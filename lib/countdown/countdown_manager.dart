import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:system_clock/system_clock.dart';

enum TimerRunState { running, paused, finished, stopped }

enum _TimerDirection { countdown, countup }

class TimerController extends ChangeNotifier {
  _TimerEntry? _entry;
  bool _isDisposed = false;

  TimerRunState get state => _entry?.state ?? TimerRunState.stopped;

  bool get isRunning => state == TimerRunState.running;

  bool get isPaused => state == TimerRunState.paused;

  Duration get value => _entry?.notifier.value ?? Duration.zero;

  void pause() {
    _entry?.pause();
  }

  void resume() {
    _entry?.resume();
  }

  void stop() {
    _entry?.stop(notifyController: true);
  }

  void reset() {
    _entry?.reset();
  }

  void _attach(_TimerEntry entry) {
    if (_entry == entry) return;
    _entry?._controller = null;
    _entry = entry;
    entry._controller = this;
    _safeNotifyListeners();
  }

  void _detach(_TimerEntry entry) {
    if (_entry != entry) return;
    _entry = null;
    _safeNotifyListeners();
  }

  void _notifyStateChanged() {
    _safeNotifyListeners();
  }

  void _safeNotifyListeners() {
    if (_isDisposed) return;

    final schedulerPhase = WidgetsBinding.instance.schedulerPhase;
    if (schedulerPhase == SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_isDisposed) return;
        notifyListeners();
      });
      return;
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _entry?._controller = null;
    _entry = null;
    super.dispose();
  }
}

/// 高级 ValueNotifier 保持不变
class AdvancedValueNotifier<T> extends ValueNotifier<T> {
  int _listenerCount = 0;

  AdvancedValueNotifier(super.value);

  @override
  void addListener(VoidCallback listener) {
    super.addListener(listener);
    _listenerCount++;
  }

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
    _listenerCount--;
  }

  bool get hasAnyListeners => _listenerCount > 0;
}

class _TimerEntry {
  final Key key;
  final _TimerDirection direction;
  final AdvancedValueNotifier<Duration> notifier;
  final Duration duration;
  final Duration initialDuration;
  final Duration? maxDuration;
  final VoidCallback? onFinish;
  final VoidCallback onChanged;

  TimerController? _controller;
  TimerRunState state;
  int _startedRealtimeMs;
  Duration _pausedElapsed = Duration.zero;
  int? _pausedRealtimeMs;
  bool _finishNotified = false;

  _TimerEntry.countdown({
    required this.key,
    required this.duration,
    required this.notifier,
    required this.onChanged,
    required VoidCallback this.onFinish,
    required bool isPaused,
  }) : direction = _TimerDirection.countdown,
       initialDuration = Duration.zero,
       maxDuration = null,
       state = duration == Duration.zero
           ? TimerRunState.finished
           : isPaused
           ? TimerRunState.paused
           : TimerRunState.running,
       _startedRealtimeMs = _nowMs() {
    notifier.value = displayDuration;
    if (isPaused && state == TimerRunState.paused) {
      _pausedRealtimeMs = _startedRealtimeMs;
    }
  }

  _TimerEntry.countup({
    required this.key,
    required this.initialDuration,
    required this.maxDuration,
    required this.notifier,
    required this.onChanged,
    this.onFinish,
    required bool isPaused,
  }) : direction = _TimerDirection.countup,
       duration = Duration.zero,
       state = maxDuration != null && initialDuration >= maxDuration
           ? TimerRunState.finished
           : isPaused
           ? TimerRunState.paused
           : TimerRunState.running,
       _startedRealtimeMs = _nowMs() {
    notifier.value = displayDuration;
    if (isPaused && state == TimerRunState.paused) {
      _pausedRealtimeMs = _startedRealtimeMs;
    }
  }

  Duration get displayDuration {
    switch (direction) {
      case _TimerDirection.countdown:
        final remaining = duration - _elapsed;
        if (remaining <= Duration.zero) return Duration.zero;
        return Duration(seconds: (remaining.inMilliseconds + 999) ~/ 1000);
      case _TimerDirection.countup:
        final elapsed = initialDuration + _elapsed;
        final rounded = Duration(seconds: elapsed.inSeconds);
        if (maxDuration != null && rounded >= maxDuration!) {
          return maxDuration!;
        }
        return rounded;
    }
  }

  Duration get _elapsed {
    if (state == TimerRunState.stopped) return Duration.zero;
    final nowMs = _pausedRealtimeMs ?? _nowMs();
    final elapsedMs = nowMs - _startedRealtimeMs;
    if (elapsedMs <= 0) return Duration.zero;
    return _pausedElapsed + Duration(milliseconds: elapsedMs);
  }

  bool get _isFinishedByTime {
    switch (direction) {
      case _TimerDirection.countdown:
        return displayDuration == Duration.zero;
      case _TimerDirection.countup:
        return maxDuration != null && displayDuration >= maxDuration!;
    }
  }

  bool refresh() {
    if (state == TimerRunState.stopped) return false;

    final previousValue = notifier.value;
    final currentValue = displayDuration;
    if (previousValue != currentValue) {
      notifier.value = currentValue;
    }

    if (state == TimerRunState.running && _isFinishedByTime) {
      state = TimerRunState.finished;
      _controller?._notifyStateChanged();
      if (!_finishNotified) {
        _finishNotified = true;
        onFinish?.call();
      }
    }

    return previousValue != currentValue;
  }

  void pause() {
    if (state != TimerRunState.running) return;
    _pausedRealtimeMs = _nowMs();
    refresh();
    state = TimerRunState.paused;
    _controller?._notifyStateChanged();
    onChanged();
  }

  void resume() {
    if (state != TimerRunState.paused) return;
    final pausedRealtimeMs = _pausedRealtimeMs;
    if (pausedRealtimeMs != null) {
      _pausedElapsed += Duration(
        milliseconds: pausedRealtimeMs - _startedRealtimeMs,
      );
    }
    _startedRealtimeMs = _nowMs();
    _pausedRealtimeMs = null;
    state = TimerRunState.running;
    refresh();
    _controller?._notifyStateChanged();
    onChanged();
  }

  void stop({bool notifyController = false}) {
    if (state == TimerRunState.stopped) return;
    state = TimerRunState.stopped;
    _pausedRealtimeMs = null;
    if (notifyController) {
      _controller?._notifyStateChanged();
    }
    onChanged();
  }

  void reset() {
    _startedRealtimeMs = _nowMs();
    _pausedElapsed = Duration.zero;
    _pausedRealtimeMs = null;
    _finishNotified = false;
    state = direction == _TimerDirection.countdown && duration == Duration.zero
        ? TimerRunState.finished
        : direction == _TimerDirection.countup &&
              maxDuration != null &&
              initialDuration >= maxDuration!
        ? TimerRunState.finished
        : TimerRunState.running;
    notifier.value = displayDuration;
    _controller?._notifyStateChanged();
    onChanged();
  }

  Duration nextDelay() {
    if (state != TimerRunState.running) return Duration.zero;

    switch (direction) {
      case _TimerDirection.countdown:
        final remainingMs = duration.inMilliseconds - _elapsed.inMilliseconds;
        if (remainingMs <= 0) return Duration.zero;
        final remainder = remainingMs % 1000;
        return Duration(milliseconds: remainder == 0 ? 1000 : remainder);
      case _TimerDirection.countup:
        final elapsedMs = (initialDuration + _elapsed).inMilliseconds;
        final max = maxDuration;
        if (max != null) {
          final remainingToMax = max.inMilliseconds - elapsedMs;
          if (remainingToMax <= 0) return Duration.zero;
          final toNextSecond = 1000 - (elapsedMs % 1000);
          return Duration(
            milliseconds: remainingToMax < toNextSecond
                ? remainingToMax
                : toNextSecond,
          );
        }
        final remainder = elapsedMs % 1000;
        return Duration(milliseconds: remainder == 0 ? 1000 : 1000 - remainder);
    }
  }

  static int _nowMs() => SystemClock.elapsedRealtime().inMilliseconds;
}

class CountdownManager with WidgetsBindingObserver {
  static final CountdownManager instance = CountdownManager._();

  CountdownManager._();

  Timer? _timer;
  bool _isObservingLifecycle = false;

  final Map<Key, _TimerEntry> _entries = {};
  final Map<Key, AdvancedValueNotifier<Duration>> _notifiers = {};

  AdvancedValueNotifier<Duration>? current(Key key) => _notifiers[key];

  AdvancedValueNotifier<Duration>? currentCountup(Key key) => _notifiers[key];

  /// 启动倒计时
  void startTimer(
    Key key,
    Duration duration,
    VoidCallback onFinish, {
    TimerController? controller,
    bool isPaused = false,
  }) {
    final effectiveDuration = duration.isNegative ? Duration.zero : duration;
    final notifier = _notifiers.putIfAbsent(
      key,
      () => AdvancedValueNotifier(effectiveDuration),
    );

    _entries[key]?._controller?._detach(_entries[key]!);
    final entry = _TimerEntry.countdown(
      key: key,
      duration: effectiveDuration,
      notifier: notifier,
      onFinish: onFinish,
      isPaused: isPaused,
      onChanged: _scheduleNextTick,
    );
    _entries[key] = entry;
    controller?._attach(entry);

    _ensureLifecycleObserver();
    entry.refresh();
    _scheduleNextTick();
  }

  /// 启动正向计时
  void startCountupTimer(
    Key key,
    Duration initialDuration, {
    Duration? maxDuration,
    VoidCallback? onFinish,
    TimerController? controller,
    bool isPaused = false,
  }) {
    final effectiveInitialDuration = initialDuration.isNegative
        ? Duration.zero
        : initialDuration;
    final effectiveMaxDuration = maxDuration == null || maxDuration.isNegative
        ? null
        : maxDuration;
    final notifier = _notifiers.putIfAbsent(
      key,
      () => AdvancedValueNotifier(effectiveInitialDuration),
    );

    _entries[key]?._controller?._detach(_entries[key]!);
    final entry = _TimerEntry.countup(
      key: key,
      initialDuration: effectiveInitialDuration,
      maxDuration: effectiveMaxDuration,
      notifier: notifier,
      onFinish: onFinish,
      isPaused: isPaused,
      onChanged: _scheduleNextTick,
    );
    _entries[key] = entry;
    controller?._attach(entry);

    _ensureLifecycleObserver();
    entry.refresh();
    _scheduleNextTick();
  }

  /// 停止倒计时
  void stopTimer(Key key) {
    _stopEntry(key);
  }

  /// 停止正向计时
  void stopCountupTimer(Key key) {
    _stopEntry(key);
  }

  void pauseTimer(Key key) {
    _entries[key]?.pause();
  }

  void resumeTimer(Key key) {
    _entries[key]?.resume();
  }

  void _stopEntry(Key key) {
    final entry = _entries.remove(key);
    if (entry == null) return;

    entry.stop();
    entry._controller?._detach(entry);
    _disposeNotifierWhenUnused(key);
    _scheduleNextTick();
  }

  void _disposeNotifierWhenUnused(Key key) {
    final notifier = _notifiers[key];
    if (notifier == null) return;

    if (notifier.hasAnyListeners) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_entries.containsKey(key)) return;
        final currentNotifier = _notifiers[key];
        if (currentNotifier == null || currentNotifier.hasAnyListeners) return;
        _notifiers.remove(key)?.dispose();
      });
      return;
    }

    _notifiers.remove(key)?.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshAll();
      _scheduleNextTick();
    }
  }

  void _ensureLifecycleObserver() {
    if (_isObservingLifecycle) return;
    WidgetsBinding.instance.addObserver(this);
    _isObservingLifecycle = true;
  }

  void _removeLifecycleObserverIfUnused() {
    if (!_isObservingLifecycle || _entries.isNotEmpty) return;
    WidgetsBinding.instance.removeObserver(this);
    _isObservingLifecycle = false;
  }

  void _refreshAll() {
    for (final entry in List<_TimerEntry>.of(_entries.values)) {
      entry.refresh();
    }
  }

  void _removeStoppedEntries() {
    final stoppedKeys = <Key>[];
    for (final entry in _entries.values) {
      if (entry.state == TimerRunState.stopped) {
        stoppedKeys.add(entry.key);
      }
    }

    for (final key in stoppedKeys) {
      final entry = _entries.remove(key);
      if (entry == null) continue;
      entry._controller?._detach(entry);
      _disposeNotifierWhenUnused(key);
    }
  }

  void _scheduleNextTick() {
    _timer?.cancel();
    _timer = null;

    _refreshAll();
    _removeStoppedEntries();

    Duration? nextDelay;
    for (final entry in _entries.values) {
      final delay = entry.nextDelay();
      if (delay == Duration.zero) continue;
      if (nextDelay == null || delay < nextDelay) {
        nextDelay = delay;
      }
    }

    if (nextDelay == null) {
      _removeLifecycleObserverIfUnused();
      return;
    }

    _timer = Timer(nextDelay, () {
      _timer = null;
      _scheduleNextTick();
    });
  }
}
