import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'countdown_manager.dart';

typedef CountupWidgetBuilder =
    Widget Function(
      BuildContext context,
      Duration elapsedTime,
      String dateText,
    );

class Countup extends StatefulWidget {
  final bool paused;
  final Duration initialDuration;
  final Duration? maxDuration;
  final TimerController? controller;
  final VoidCallback? onFinish;
  final TextStyle? timeStyle;
  final CountupWidgetBuilder? timerWidgetBuilder;

  const Countup({
    required super.key,
    this.paused = false,
    this.initialDuration = Duration.zero,
    this.maxDuration,
    this.controller,
    this.onFinish,
    this.timeStyle,
    this.timerWidgetBuilder,
  });

  Duration get effectiveInitialDuration =>
      initialDuration.isNegative ? Duration.zero : initialDuration;

  Duration? get effectiveMaxDuration =>
      maxDuration == null || maxDuration!.isNegative ? null : maxDuration;

  bool get isFinished {
    final max = effectiveMaxDuration;
    return max != null && effectiveInitialDuration >= max;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<Duration>(
        'initialDuration',
        effectiveInitialDuration,
      ),
    );
    properties.add(
      DiagnosticsProperty<Duration?>('maxDuration', effectiveMaxDuration),
    );
  }

  @override
  CountupState createState() => CountupState();
}

class CountupState extends State<Countup> {
  late Key _key;
  late ValueNotifier<Duration> _notifier;

  @override
  void initState() {
    _key = widget.key!;
    _startTimer();
    super.initState();
  }

  @override
  void didUpdateWidget(covariant Countup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.effectiveInitialDuration != oldWidget.effectiveInitialDuration ||
        widget.effectiveMaxDuration != oldWidget.effectiveMaxDuration ||
        widget.controller != oldWidget.controller ||
        widget.key != oldWidget.key) {
      CountdownManager.instance.stopCountupTimer(_key);
      _key = widget.key!;
      _startTimer();
      return;
    }

    if (widget.paused != oldWidget.paused) {
      if (widget.paused) {
        CountdownManager.instance.pauseTimer(_key);
      } else {
        CountdownManager.instance.resumeTimer(_key);
      }
    }
  }

  @override
  void dispose() {
    CountdownManager.instance.stopCountupTimer(_key);
    super.dispose();
  }

  void _startTimer() {
    CountdownManager.instance.startCountupTimer(
      _key,
      widget.effectiveInitialDuration,
      maxDuration: widget.effectiveMaxDuration,
      onFinish: () {
        if (!widget.isFinished) {
          widget.onFinish?.call();
        }
      },
      controller: widget.controller,
      isPaused: widget.paused,
    );
    _notifier = CountdownManager.instance.currentCountup(_key)!;
  }

  String _formatDuration(Duration duration) {
    int days = duration.inDays;
    int hours = duration.inHours % 24;
    int minutes = duration.inMinutes % 60;
    int seconds = duration.inSeconds % 60;
    if (duration.inDays > 0) {
      return '$days天${_zeroToTwoString(hours)}:${_zeroToTwoString(minutes)}:${_zeroToTwoString(seconds)}';
    }
    return '${_zeroToTwoString(hours)}:${_zeroToTwoString(minutes)}:${_zeroToTwoString(seconds)}';
  }

  String _zeroToTwoString(int value) {
    return '${value < 10 ? '0' : ''}$value';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Duration>(
      valueListenable: _notifier,
      builder: (context, elapsedTime, child) {
        final dateText = _formatDuration(elapsedTime);
        return widget.timerWidgetBuilder?.call(
              context,
              elapsedTime,
              dateText,
            ) ??
            Text(
              dateText,
              style: const TextStyle(
                height: 1.1,
                fontFeatures: [FontFeature.tabularFigures()],
              ).merge(widget.timeStyle),
            );
      },
    );
  }
}
