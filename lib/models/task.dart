import 'dart:io';

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
      if (task.containsKey("params")) {
        params = List<String>.from(task['params']);
      }
      String profile = "";
      if (task.containsKey("profile")) {
        profile = task['profile'];
      }
      String? workingDir;
      if (task.containsKey("workingDirectory")) {
        workingDir = task['workingDirectory'];
      }
      out.add(Task(id, task['name'], task['cmd'], params, profile, workingDir));
      id++;
    }
    Map<String, Profile> profiles = {};
    if (data.containsKey("profiles")) {
      for (var prof in data["profiles"]) {
        if (prof.containsKey("name") && prof.containsKey("executable")) {
          List<String> setup = [];
          if (prof.containsKey("setup")) {
            setup = List<String>.from(prof['setup']);
          }
          profiles[prof["name"]] =
              Profile(prof["name"], prof["executable"], setup);
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
  final String profile;
  final String? workingDir;
  TaskState state = TaskState.idle;
  String stout = "";
  Process? process;
  double scrollOffset = -1.0;
  DateTime? startTime;
  DateTime? stopTime;
  Task(
      this.id, this.name, this.cmd, this.params, this.profile, this.workingDir);
  void start() {
    startTime = DateTime.now();
    stopTime = null;
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

  String getRunntime() {
    if (startTime != null && stopTime != null) {
      var diff = stopTime?.difference(startTime ?? DateTime.now());
      if (diff != null) {
        return diff.toString().split('.').first;
      }
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
  final List<String> setup;
  Profile(this.name, this.executable, this.setup);
}
