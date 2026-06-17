import 'dart:async';

import 'package:flutter/material.dart';
import 'package:system_clock/system_clock.dart';

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

/// 倒计时信息（基于 system clock）
class CountdownInfo {
  final Duration duration;
  final int startRealtimeMs;

  CountdownInfo({required this.duration, required this.startRealtimeMs});

  Duration get remainingDuration {
    final nowMs = SystemClock.elapsedRealtime();
    final elapsed = nowMs.inMilliseconds - startRealtimeMs;
    final remaining = duration - Duration(milliseconds: elapsed);
    if (remaining <= Duration.zero) return Duration.zero;
    return Duration(seconds: (remaining.inMilliseconds + 999) ~/ 1000);
  }
}

/// 正向计时信息（基于 system clock）
class CountupInfo {
  final Duration initialDuration;
  final Duration? maxDuration;
  final int startRealtimeMs;

  CountupInfo({
    required this.initialDuration,
    required this.startRealtimeMs,
    this.maxDuration,
  });

  Duration get elapsedDuration {
    final nowMs = SystemClock.elapsedRealtime();
    final elapsed = Duration(
      milliseconds: nowMs.inMilliseconds - startRealtimeMs,
    );
    final current = initialDuration + elapsed;
    final rounded = Duration(seconds: current.inSeconds);
    if (maxDuration != null && rounded >= maxDuration!) return maxDuration!;
    return rounded;
  }
}

class CountdownManager {
  static final CountdownManager instance = CountdownManager._();

  CountdownManager._();

  Timer? _timer;
  final Duration _refreshInterval = const Duration(milliseconds: 100);

  final Map<Key, CountdownInfo> _timers = {};
  final Map<Key, AdvancedValueNotifier<Duration>> _notifiers = {};
  final Map<Key, VoidCallback> _onFinishCallbacks = {};
  final Map<Key, CountupInfo> _countupTimers = {};
  final Map<Key, AdvancedValueNotifier<Duration>> _countupNotifiers = {};
  final Map<Key, VoidCallback> _countupOnFinishCallbacks = {};

  AdvancedValueNotifier<Duration>? current(Key key) => _notifiers[key];

  AdvancedValueNotifier<Duration>? currentCountup(Key key) =>
      _countupNotifiers[key];

  /// 启动倒计时
  void startTimer(Key key, Duration duration, VoidCallback onFinish) {
    final effectiveDuration = duration.isNegative ? Duration.zero : duration;
    final startMs = SystemClock.elapsedRealtime();

    _timers[key] = CountdownInfo(
      duration: effectiveDuration,
      startRealtimeMs: startMs.inMilliseconds,
    );

    if (_notifiers[key] == null) {
      _notifiers[key] = AdvancedValueNotifier(effectiveDuration);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _notifiers[key]?.value = effectiveDuration;
      });
    }

    _onFinishCallbacks[key] = onFinish;

    _startGlobalTimerIfNecessary();
  }

  /// 启动正向计时
  void startCountupTimer(
    Key key,
    Duration initialDuration, {
    Duration? maxDuration,
    VoidCallback? onFinish,
  }) {
    final effectiveInitialDuration = initialDuration.isNegative
        ? Duration.zero
        : initialDuration;
    final effectiveMaxDuration = maxDuration == null || maxDuration.isNegative
        ? null
        : maxDuration;
    final startMs = SystemClock.elapsedRealtime();

    _countupTimers[key] = CountupInfo(
      initialDuration: effectiveInitialDuration,
      maxDuration: effectiveMaxDuration,
      startRealtimeMs: startMs.inMilliseconds,
    );

    if (_countupNotifiers[key] == null) {
      _countupNotifiers[key] = AdvancedValueNotifier(effectiveInitialDuration);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _countupNotifiers[key]?.value = effectiveInitialDuration;
      });
    }

    if (onFinish != null) {
      _countupOnFinishCallbacks[key] = onFinish;
    } else {
      _countupOnFinishCallbacks.remove(key);
    }

    _startGlobalTimerIfNecessary();
  }

  /// 停止倒计时
  void stopTimer(Key key) {
    _timers.remove(key);
    _onFinishCallbacks.remove(key);
    _disposeNotifierWhenUnused(key, _timers, _notifiers);

    _stopGlobalTimerIfNecessary();
  }

  /// 停止正向计时
  void stopCountupTimer(Key key) {
    _countupTimers.remove(key);
    _countupOnFinishCallbacks.remove(key);
    _disposeNotifierWhenUnused(key, _countupTimers, _countupNotifiers);

    _stopGlobalTimerIfNecessary();
  }

  void _stopGlobalTimerIfNecessary() {
    if (_timers.isEmpty && _countupTimers.isEmpty) {
      _timer?.cancel();
      _timer = null;
    }
  }

  void _disposeNotifierWhenUnused(
    Key key,
    Map<Key, Object> timers,
    Map<Key, AdvancedValueNotifier<Duration>> notifiers,
  ) {
    final notifier = notifiers[key];
    if (notifier == null) return;

    if (notifier.hasAnyListeners) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (timers.containsKey(key)) return;
        final currentNotifier = notifiers[key];
        if (currentNotifier == null || currentNotifier.hasAnyListeners) return;
        notifiers.remove(key)?.dispose();
      });
      return;
    }

    notifiers.remove(key)?.dispose();
  }

  /// 全局 Timer 刷新 UI
  void _startGlobalTimerIfNecessary() {
    if (_timer != null) return;
    if (_timers.isEmpty && _countupTimers.isEmpty) return;

    _timer = Timer.periodic(_refreshInterval, (_) {
      final List<Key> finishedKeys = [];
      final List<Key> finishedCountupKeys = [];

      _timers.forEach((key, info) {
        final remaining = info.remainingDuration;

        if (remaining == Duration.zero) {
          // 倒计时结束，直接置 0 并回调
          _notifiers[key]?.value = Duration.zero;
          finishedKeys.add(key);
        } else {
          // 更新剩余时间
          _notifiers[key]?.value = remaining;
        }
      });

      for (var key in finishedKeys) {
        _onFinishCallbacks[key]?.call();
        _timers.remove(key);
        _onFinishCallbacks.remove(key);
      }

      _countupTimers.forEach((key, info) {
        final elapsed = info.elapsedDuration;
        _countupNotifiers[key]?.value = elapsed;

        if (info.maxDuration != null && elapsed >= info.maxDuration!) {
          finishedCountupKeys.add(key);
        }
      });

      for (var key in finishedCountupKeys) {
        _countupOnFinishCallbacks[key]?.call();
        _countupTimers.remove(key);
        _countupOnFinishCallbacks.remove(key);
      }

      _stopGlobalTimerIfNecessary();
    });
  }
}
