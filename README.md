# countdown_manager

High precision countdown and countup widgets for Flutter.

`countdown_manager` provides second-level timer widgets that calculate time from
a monotonic clock instead of accumulating periodic ticks. This keeps displayed
time correct after delayed ticks, pause/resume cycles, and app background
resumes.

## Features

- `Countdown` and `Countup` widgets.
- `TimerController` with `pause`, `resume`, `stop`, and `reset`.
- Declarative pause control with `paused`.
- Monotonic clock based timing to avoid tick drift.
- App lifecycle resume refresh for background correction.
- Single low-power scheduler aligned to the next second-level UI change.
- Stable second-level display with tabular figures.
- Custom rendering through `timerWidgetBuilder`.

## Getting started

Add the package to your app:

```yaml
dependencies:
  countdown_manager: ^0.1.0
```

Then import it:

```dart
import 'package:countdown_manager/countdown_manager.dart';
```

## Countdown

```dart
final controller = TimerController();

Countdown(
  key: const ValueKey('checkout-countdown'),
  duration: const Duration(minutes: 5),
  controller: controller,
  zeroText: 'Done',
  onFinish: () {
    debugPrint('Countdown finished');
  },
)
```

## Countup

```dart
final controller = TimerController();

Countup(
  key: const ValueKey('session-countup'),
  initialDuration: Duration.zero,
  maxDuration: const Duration(hours: 1),
  controller: controller,
  onFinish: () {
    debugPrint('Countup finished');
  },
)
```

## Controller

```dart
controller.pause();
controller.resume();
controller.reset();
controller.stop();
```

You can observe controller state:

```dart
AnimatedBuilder(
  animation: controller,
  builder: (context, child) {
    return Text(controller.state.name);
  },
)
```

## Declarative pause

Use `paused` when the timer state is driven by parent widget state:

```dart
Countdown(
  key: const ValueKey('task-countdown'),
  duration: const Duration(minutes: 10),
  paused: taskPaused,
)
```

For imperative controls such as `reset` and `stop`, prefer `TimerController`.

## Custom rendering

```dart
Countdown(
  key: const ValueKey('custom-countdown'),
  duration: const Duration(days: 1, hours: 2, minutes: 3),
  timerWidgetBuilder: (context, remainingTime, formattedText) {
    return Text('$formattedText (${remainingTime.inSeconds}s)');
  },
)
```

## Notes

- Timers are corrected with `SystemClock.elapsedRealtime()`, so delayed Dart
  timers do not create time drift.
- The scheduler updates at the next second-level display change. It is designed
  for stable second-level UI, not sub-second stopwatch rendering.
- If the app process is killed, persist your own start timestamp and recreate
  the widget with an adjusted `duration` or `initialDuration`.
