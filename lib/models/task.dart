import 'dart:io';

class Tasks {
  final List<Task> tasks;
  final Map<String, String> profiles;
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
      out.add(Task(id, task['name'], task['cmd'], params, profile));
      id++;
    }
    Map<String, String> profiles = {};
    if (data.containsKey("profiles")) {
      for (var prof in data["profiles"]) {
        if (prof.containsKey("name") && prof.containsKey("executable")) {
          profiles[prof["name"]] = prof["executable"];
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
  TaskState state = TaskState.idle;
  String stout = "";
  Process? process;
  double scrollOffset = -1.0;
  Task(this.id, this.name, this.cmd, this.params, this.profile);
}

enum TaskState { idle, running, finished, aborted }
