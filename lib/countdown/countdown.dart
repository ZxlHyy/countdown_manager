import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'countdown_manager.dart';

typedef CountdownWidgetBuilder =
    Widget Function(
      BuildContext context,
      Duration remainingTime,
      String dateText,
    );

class Countdown extends StatefulWidget {
  final bool paused;
  final Duration duration;
  final TimerController? controller;
  final VoidCallback? onFinish;
  final String? zeroText;
  final TextStyle? timeStyle;
  final CountdownWidgetBuilder? timerWidgetBuilder;

  const Countdown({
    required super.key,
    this.paused = false,
    required this.duration,
    this.controller,
    this.onFinish,
    this.zeroText,
    this.timeStyle,
    this.timerWidgetBuilder,
  });

  Duration get effectiveDuration =>
      duration.isNegative ? Duration.zero : duration;

  bool get isFinished => effectiveDuration == Duration.zero;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<Duration>('duration', effectiveDuration),
    );
  }

  @override
  CountdownState createState() => CountdownState();
}

class CountdownState extends State<Countdown> {
  late Key _key;
  late ValueNotifier<Duration> _notifier;

  @override
  void initState() {
    _key = widget.key!;
    _startTimer();
    super.initState();
  }

  @override
  void didUpdateWidget(covariant Countdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.effectiveDuration != oldWidget.effectiveDuration ||
        widget.controller != oldWidget.controller ||
        widget.key != oldWidget.key) {
      CountdownManager.instance.stopTimer(_key);
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
    CountdownManager.instance.stopTimer(_key);
    super.dispose();
  }

  void _startTimer() {
    CountdownManager.instance.startTimer(
      _key,
      widget.effectiveDuration,
      () {
        if (!widget.isFinished) {
          widget.onFinish?.call();
        }
      },
      controller: widget.controller,
      isPaused: widget.paused,
    );
    _notifier = CountdownManager.instance.current(_key)!;
  }

  String _formatDuration(Duration duration) {
    if (widget.zeroText != null && duration == Duration.zero) {
      return widget.zeroText!;
    }
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
      builder: (context, remainingTime, child) {
        final dateText = _formatDuration(remainingTime);
        return widget.timerWidgetBuilder?.call(
              context,
              remainingTime,
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
