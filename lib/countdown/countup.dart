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
  final bool isPause;
  final Duration initialDuration;
  final Duration? maxDuration;
  final VoidCallback? onFinish;
  final TextStyle? timeStyle;
  final CountupWidgetBuilder? timerWidgetBuilder;

  const Countup({
    required super.key,
    this.isPause = false,
    this.initialDuration = Duration.zero,
    this.maxDuration,
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
  late bool _isPause;
  late Key _key;
  late ValueNotifier<Duration> _notifier;

  @override
  void initState() {
    _isPause = widget.isPause;
    _key = widget.key!;
    _startTimer();
    super.initState();
  }

  @override
  void didUpdateWidget(covariant Countup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.effectiveInitialDuration != oldWidget.effectiveInitialDuration ||
        widget.effectiveMaxDuration != oldWidget.effectiveMaxDuration ||
        widget.isPause != oldWidget.isPause ||
        widget.key != oldWidget.key) {
      if (!_isPause) {
        CountdownManager.instance.stopCountupTimer(_key);
      }
      _isPause = widget.isPause;
      _key = widget.key!;
      _startTimer();
    }
  }

  @override
  void dispose() {
    if (!_isPause) {
      CountdownManager.instance.stopCountupTimer(_key);
    }
    super.dispose();
  }

  void _startTimer() {
    if (!_isPause) {
      CountdownManager.instance.startCountupTimer(
        _key,
        widget.effectiveInitialDuration,
        maxDuration: widget.effectiveMaxDuration,
        onFinish: () {
          if (!widget.isFinished) {
            widget.onFinish?.call();
          }
        },
      );
      _notifier = CountdownManager.instance.currentCountup(_key)!;
    }
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
    if (_isPause) {
      final duration = widget.effectiveInitialDuration;
      final dateText = _formatDuration(duration);
      return widget.timerWidgetBuilder?.call(context, duration, dateText) ??
          Text(
            dateText,
            style: const TextStyle(
              height: 1.1,
              fontFeatures: [FontFeature.tabularFigures()],
            ).merge(widget.timeStyle),
          );
    }
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
