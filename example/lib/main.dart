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
      home: Scaffold(
        appBar: AppBar(title: const Text('Countdown Manager Example')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Countdown(
                key: const ValueKey('example-countdown'),
                duration: const Duration(minutes: 1),
                zeroText: 'Done',
                onFinish: () {
                  debugPrint('Countdown finished');
                },
              ),
              const SizedBox(height: 16),
              Countup(
                key: const ValueKey('example-countup'),
                maxDuration: const Duration(minutes: 1),
                onFinish: () {
                  debugPrint('Countup finished');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
