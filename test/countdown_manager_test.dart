import 'package:countdown_manager/countdown_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders a duration countdown', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Countdown(
          key: ValueKey('countdown'),
          duration: Duration(seconds: 3),
        ),
      ),
    );

    expect(find.text('00:00:03'), findsOneWidget);
  });

  testWidgets('supports paused countdowns without starting a timer', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Countdown(
          key: ValueKey('paused-countdown'),
          paused: true,
          duration: Duration(minutes: 1, seconds: 5),
        ),
      ),
    );

    expect(find.text('00:01:05'), findsOneWidget);
  });

  testWidgets('uses zeroText when duration is zero', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Countdown(
          key: ValueKey('zero-countdown'),
          duration: Duration.zero,
          zeroText: 'Done',
        ),
      ),
    );

    expect(find.text('Done'), findsOneWidget);
  });

  testWidgets('treats negative durations as zero', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Countdown(
          key: ValueKey('negative-countdown'),
          duration: Duration(seconds: -3),
          zeroText: 'Done',
        ),
      ),
    );

    expect(find.text('Done'), findsOneWidget);
  });

  testWidgets('countdown controller supports pause and resume', (tester) async {
    final controller = TimerController();

    await tester.pumpWidget(
      MaterialApp(
        home: Countdown(
          key: const ValueKey('controlled-countdown'),
          duration: const Duration(seconds: 3),
          controller: controller,
        ),
      ),
    );

    expect(controller.isRunning, isTrue);
    expect(find.text('00:00:03'), findsOneWidget);

    controller.pause();
    await tester.pump();

    expect(controller.isPaused, isTrue);
    expect(find.text('00:00:03'), findsOneWidget);

    controller.resume();
    await tester.pump();

    expect(controller.isRunning, isTrue);
  });

  testWidgets('countdown paused updates pause and resume existing timer', (
    tester,
  ) async {
    final controller = TimerController();

    await tester.pumpWidget(
      MaterialApp(
        home: Countdown(
          key: const ValueKey('declarative-countdown'),
          duration: const Duration(seconds: 3),
          controller: controller,
          paused: true,
        ),
      ),
    );

    expect(controller.isPaused, isTrue);

    await tester.pumpWidget(
      MaterialApp(
        home: Countdown(
          key: const ValueKey('declarative-countdown'),
          duration: const Duration(seconds: 3),
          controller: controller,
        ),
      ),
    );

    expect(controller.isRunning, isTrue);
  });

  testWidgets('renders a countup from zero', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Countup(key: ValueKey('countup'))),
    );

    expect(find.text('00:00:00'), findsOneWidget);
  });

  testWidgets('supports countup initial durations', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Countup(
          key: ValueKey('initial-countup'),
          initialDuration: Duration(minutes: 1, seconds: 5),
        ),
      ),
    );

    expect(find.text('00:01:05'), findsOneWidget);
  });

  testWidgets('supports paused countups without starting a timer', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Countup(
          key: ValueKey('paused-countup'),
          paused: true,
          initialDuration: Duration(seconds: 3),
        ),
      ),
    );

    expect(find.text('00:00:03'), findsOneWidget);
  });

  testWidgets('treats negative countup initial durations as zero', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Countup(
          key: ValueKey('negative-countup'),
          initialDuration: Duration(seconds: -3),
        ),
      ),
    );

    expect(find.text('00:00:00'), findsOneWidget);
  });

  testWidgets('countup controller supports pause and resume', (tester) async {
    final controller = TimerController();

    await tester.pumpWidget(
      MaterialApp(
        home: Countup(
          key: const ValueKey('controlled-countup'),
          controller: controller,
        ),
      ),
    );

    expect(controller.isRunning, isTrue);
    expect(find.text('00:00:00'), findsOneWidget);

    controller.pause();
    await tester.pump();

    expect(controller.isPaused, isTrue);
    expect(find.text('00:00:00'), findsOneWidget);

    controller.resume();
    await tester.pump();

    expect(controller.isRunning, isTrue);
  });

  testWidgets('countup paused updates pause and resume existing timer', (
    tester,
  ) async {
    final controller = TimerController();

    await tester.pumpWidget(
      MaterialApp(
        home: Countup(
          key: const ValueKey('declarative-countup'),
          controller: controller,
          paused: true,
        ),
      ),
    );

    expect(controller.isPaused, isTrue);

    await tester.pumpWidget(
      MaterialApp(
        home: Countup(
          key: const ValueKey('declarative-countup'),
          controller: controller,
        ),
      ),
    );

    expect(controller.isRunning, isTrue);
  });

  testWidgets('countup calls onFinish at maxDuration', (tester) async {
    var finished = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Countup(
          key: const ValueKey('max-countup'),
          maxDuration: Duration.zero,
          onFinish: () {
            finished = true;
          },
        ),
      ),
    );

    await tester.pump();

    expect(finished, isFalse);
    expect(find.text('00:00:00'), findsOneWidget);
  });
}
