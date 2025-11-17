import 'dart:async';
import 'package:flutter/material.dart';
import '../models/task.dart';

class RuntimeDisplay extends StatefulWidget {
  final Task task;

  const RuntimeDisplay({
    Key? key,
    required this.task,
  }) : super(key: key);

  @override
  State<RuntimeDisplay> createState() => _RuntimeDisplayState();
}

class _RuntimeDisplayState extends State<RuntimeDisplay> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        if (widget.task.state == TaskState.running) {
          setState(() {
            // Force rebuild to update the runtime display
          });
        }
      }
    });
  }

  String _getRuntimeStr() {
    if (widget.task.startTime != null) {
      var diff = (widget.task.stopTime ?? DateTime.now())
          .difference(widget.task.startTime ?? DateTime.now());
      return diff.toString().split('.').first;
    }
    return "-";
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      "it took: ${_getRuntimeStr()}",
      style: const TextStyle(fontSize: 11),
    );
  }
}


