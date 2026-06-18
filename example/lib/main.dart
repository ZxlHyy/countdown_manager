import 'package:countdown_manager/countdown_manager.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const TimerExamplePage(),
    );
  }
}

class TimerExamplePage extends StatefulWidget {
  const TimerExamplePage({super.key});

  @override
  State<TimerExamplePage> createState() => _TimerExamplePageState();
}

class _TimerExamplePageState extends State<TimerExamplePage> {
  final TimerController _countdownController = TimerController();
  final TimerController _countupController = TimerController();

  int _countdownSeed = 0;
  int _countupSeed = 0;
  bool _declarativePaused = true;
  String _lastEvent = 'No timer has finished yet.';

  @override
  void dispose() {
    _countdownController.dispose();
    _countupController.dispose();
    super.dispose();
  }

  void _setLastEvent(String value) {
    setState(() {
      _lastEvent = value;
    });
  }

  void _restartCountdown() {
    setState(() {
      _countdownSeed++;
    });
  }

  void _restartCountup() {
    setState(() {
      _countupSeed++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Countdown Manager Example')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _InfoPanel(lastEvent: _lastEvent),
          const SizedBox(height: 12),
          _TimerSection(
            title: 'Countdown with TimerController',
            subtitle:
                'duration, zeroText, onFinish, pause, resume, reset, stop',
            timer: Countdown(
              key: ValueKey('controlled-countdown-$_countdownSeed'),
              duration: const Duration(seconds: 20),
              controller: _countdownController,
              zeroText: 'Done',
              timeStyle: Theme.of(context).textTheme.displaySmall,
              onFinish: () {
                _setLastEvent('Controlled countdown finished.');
              },
            ),
            controller: _countdownController,
            onRestart: _restartCountdown,
          ),
          const SizedBox(height: 12),
          _TimerSection(
            title: 'Countup with TimerController',
            subtitle:
                'initialDuration, maxDuration, onFinish, pause, resume, reset, stop',
            timer: Countup(
              key: ValueKey('controlled-countup-$_countupSeed'),
              initialDuration: const Duration(seconds: 5),
              maxDuration: const Duration(seconds: 20),
              controller: _countupController,
              timeStyle: Theme.of(context).textTheme.displaySmall,
              onFinish: () {
                _setLastEvent('Controlled countup reached maxDuration.');
              },
            ),
            controller: _countupController,
            onRestart: _restartCountup,
          ),
          const SizedBox(height: 12),
          _ExampleCard(
            title: 'Declarative Pause',
            subtitle: 'paused can keep a timer mounted in a paused state.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Countup(
                  key: ValueKey('declarative-countup-$_declarativePaused'),
                  paused: _declarativePaused,
                  initialDuration: const Duration(minutes: 1, seconds: 5),
                  maxDuration: const Duration(minutes: 2),
                  timeStyle: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Paused'),
                  value: _declarativePaused,
                  onChanged: (value) {
                    setState(() {
                      _declarativePaused = value;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _ExampleCard(
            title: 'Custom Builder',
            subtitle:
                'timerWidgetBuilder receives Duration and formatted text.',
            child: Countdown(
              key: const ValueKey('custom-builder-countdown'),
              duration: const Duration(
                days: 1,
                hours: 2,
                minutes: 3,
                seconds: 4,
              ),
              timerWidgetBuilder: (context, remainingTime, dateText) {
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _DurationChip(label: 'Formatted', value: dateText),
                    _DurationChip(
                      label: 'Raw seconds',
                      value: remainingTime.inSeconds.toString(),
                    ),
                    _DurationChip(
                      label: 'Days',
                      value: remainingTime.inDays.toString(),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          _ExampleCard(
            title: 'Zero and Negative Durations',
            subtitle: 'Negative countdown durations are clamped to zero.',
            child: Countdown(
              key: const ValueKey('zero-countdown'),
              duration: const Duration(seconds: -3),
              zeroText: 'Finished immediately',
              timeStyle: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimerSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget timer;
  final TimerController controller;
  final VoidCallback onRestart;

  const _TimerSection({
    required this.title,
    required this.subtitle,
    required this.timer,
    required this.controller,
    required this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    return _ExampleCard(
      title: title,
      subtitle: subtitle,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              timer,
              const SizedBox(height: 12),
              Text('State: ${controller.state.name}'),
              Text('Controller value: ${controller.value}'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: controller.pause,
                    icon: const Icon(Icons.pause),
                    label: const Text('Pause'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: controller.resume,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Resume'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: controller.reset,
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('Reset'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: controller.stop,
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop'),
                  ),
                  FilledButton.icon(
                    onPressed: onRestart,
                    icon: const Icon(Icons.refresh),
                    label: const Text('New Widget'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  final String lastEvent;

  const _InfoPanel({required this.lastEvent});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'High precision timer demo',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(lastEvent),
          ],
        ),
      ),
    );
  }
}

class _ExampleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _ExampleCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _DurationChip extends StatelessWidget {
  final String label;
  final String value;

  const _DurationChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label: $value'),
      visualDensity: VisualDensity.compact,
    );
  }
}
