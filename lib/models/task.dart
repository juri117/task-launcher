import 'dart:io';

import 'package:task_launcher/log_view.dart';

class Tasks {
  final List<Task> tasks;
  final Map<String, Profile> profiles;
  Tasks(this.tasks, this.profiles);

  factory Tasks.fromJson(Map<String, dynamic> data) {
    if (!data.containsKey("tasks")) return Tasks([], {});
    List<dynamic> taskList = data["tasks"];
    List<Task> out = [];
    int id = 0;
    for (var task in taskList) {
      List<String> params = [];
      Map<String, String> env = {};
      if (task.containsKey("params")) {
        params = List<String>.from(task['params']);
      }
      if (task.containsKey("env")) {
        env = Map<String, String>.from(task['env']);
      }
      String profile = "";
      if (task.containsKey("profile")) {
        profile = task['profile'];
      }
      String? workingDir;
      if (task.containsKey("workingDirectory")) {
        workingDir = task['workingDirectory'];
      }
      bool logToFile = false;
      if (task.containsKey("logToFile")) {
        logToFile = task['logToFile'];
      }
      out.add(Task(id, task['name'], task['cmd'], params, env, profile,
          workingDir, logToFile));
      id++;
    }
    Map<String, Profile> profiles = {};
    if (data.containsKey("profiles")) {
      for (var prof in data["profiles"]) {
        if (prof.containsKey("name") && prof.containsKey("executable")) {
          List<String> params = [];
          if (prof.containsKey("params")) {
            params = List<String>.from(prof['params']);
          }
          List<String> setup = [];
          if (prof.containsKey("setup")) {
            setup = List<String>.from(prof['setup']);
          }
          profiles[prof["name"]] =
              Profile(prof["name"], prof["executable"], params, setup);
        }
      }
    }
    return Tasks(out, profiles);
  }
}

class Task {
  final int id;
  final String name;
  final String cmd;
  final List<String> params;
  final Map<String, String> env;
  final String profile;
  final String? workingDir;
  final bool logToFile;

  TaskState state = TaskState.idle;
  // String stout = "";
  List<LogMessage> output = [];
  Process? process;
  //double scrollOffset = -1.0;
  //bool autoScroll = true;
  DateTime? startTime;
  DateTime? stopTime;
  String runtimeStr = "";

  Task(this.id, this.name, this.cmd, this.params, this.env, this.profile,
      this.workingDir, this.logToFile);

  void start() {
    startTime = DateTime.now();
    stopTime = null;
  }

  void addOutput(String txt, {String level = "I"}) {
    output.add(LogMessage(level, "", txt));
  }

  void trimStdout(int maxTerminalChars, int maxTerminalCharsTrimThreshold) {
    if (output.length > maxTerminalChars + maxTerminalCharsTrimThreshold) {
      output.removeRange(0, output.length - maxTerminalChars);
    }
  }

  void finished() {
    process = null;
    stopTime = DateTime.now();
  }

  String getStartTime() {
    if (startTime != null) {
      return formatTime(
          startTime?.hour ?? 0, startTime?.minute ?? 0, startTime?.second ?? 0);
    }
    return "-";
  }

  String getRuntime() {
    if (startTime != null) {
      var diff =
          (stopTime ?? DateTime.now()).difference(startTime ?? DateTime.now());
      //if (diff != null) {
      return diff.toString().split('.').first;
      //}
    }
    return "-";
  }

  String formatTime(int hours, int min, int sec) {
    return "$hours:${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}";
  }
}

enum TaskState { idle, running, finished, aborted, failed }

class Profile {
  final String name;
  final String executable;
  final List<String> params;
  final List<String> setup;
  Profile(this.name, this.executable, this.params, this.setup);
}
