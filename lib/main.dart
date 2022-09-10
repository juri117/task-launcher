import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:rich_text_view/rich_text_view.dart';
import 'package:task_launcher/models/task.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Launcher',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: const MyHomePage(title: 'Task Launcher'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final ScrollController _scrollController = ScrollController();
  final MultiSplitViewController _splitViewController =
      MultiSplitViewController(areas: Area.weights([0.3, 0.7]));

  Tasks tasks = Tasks([], {});
  Task selectedTask = Task(0, "loading...", ".", [], "");

  @override
  void initState() {
    super.initState();
    _loadFile();
  }

  Future<void> _loadFile() async {
    final file = File('setup.json');
    final content = await file.readAsString();
    final instance = jsonDecode(content);
    setState(() {
      tasks = Tasks.fromJson(instance);
      if (tasks.tasks.isNotEmpty) {
        selectedTask = tasks.tasks[0];
      }
    });
  }

  Future<void> _scrollDown() async {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent + 2000,
      duration: const Duration(milliseconds: 500),
      curve: Curves.ease,
    );
  }

  Future<void> _runTask(Task task) async {
    _selectTask(task);
    _taskChangeState(task, TaskState.running);
    _appendOutputToTask(task,
        "\n*${'=' * 40}*\n*running command: ${task.cmd} ${task.params.join(" ")}*\n*${'-' * 40}*\n");
    try {
      if (task.profile.isNotEmpty) {
        if (!tasks.profiles.containsKey(task.profile)) {
          _appendOutputToTask(
              task, "*ERROR: profile ${task.profile} is not defined*\n");
          return;
        }
        var terminal = tasks.profiles[task.profile];
        task.process = await Process.start("\"$terminal\"", []);
        task.process?.stdin
            .writeln("${task.cmd} ${task.params.join(" ")} && exit");
      } else {
        task.process = await Process.start(task.cmd, task.params);
      }
      var lines = task.process?.stdout.transform(utf8.decoder);
      if (lines == null) {
        _taskChangeState(task, TaskState.aborted);
      } else {
        await lines.forEach((element) {
          _appendOutputToTask(task, element);
          if (task.process == null) {
            return;
          }
        });
        if (task.process != null) {
          _taskChangeState(task, TaskState.finished);
        }
      }
    } catch (e) {
      _taskChangeState(task, TaskState.aborted);
      _appendOutputToTask(task, "$e\n");
    }
    task.process = null;
  }

  void _taskChangeState(Task task, TaskState newState) {
    setState(() {
      task.state = newState;
    });
  }

  void _appendOutputToTask(Task task, String out) {
    if (task.id == selectedTask.id) {
      setState(() {
        task.stout += out;
      });
      _scrollDown();
    } else {
      task.stout += out;
    }
  }

  Future<void> _killTask(Task task) async {
    var pid = task.process?.pid;
    if (pid != null) {
      Process.killPid(pid);
      _taskChangeState(task, TaskState.aborted);
      _appendOutputToTask(
          task, "\n*${'-' * 40}*\n*task was aborted by user*\n");
    }
    task.process = null;
  }

  Future<void> _clearOutput(Task task) async {
    setState(() {
      task.stout = "";
    });
  }

  Future<void> _selectTask(Task task) async {
    selectedTask.scrollOffset = _scrollController.offset;
    setState(() {
      selectedTask = task;
    });
    if (task.scrollOffset < 0.0) {
      _scrollController.jumpTo(0.0);
    } else {
      _scrollController.jumpTo(task.scrollOffset);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget left = ListView.builder(
      shrinkWrap: true,
      //physics: const NeverScrollableScrollPhysics(),
      itemCount: tasks.tasks.length,
      itemBuilder: (context, index) {
        return _buildList(tasks.tasks[index]);
      },
    );
    Widget right = Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            controller: _scrollController,
            child: RichTextView(
              style: const TextStyle(fontFamily: "myMono", color: Colors.black),
              selectable: true,
              text: selectedTask.stout,
              linkStyle: const TextStyle(color: Colors.blue),
              truncate: false,
              supportedTypes: const [ParsedType.URL, ParsedType.BOLD],
              boldStyle:
                  const TextStyle(fontFamily: "myMono", color: Colors.purple),
            )));

    MultiSplitView multiSplitView = MultiSplitView(
        controller: _splitViewController,
        children: [left, right],
        dividerBuilder:
            (axis, index, resizable, dragging, highlighted, themeData) {
          return Container(
            color: dragging ? Colors.grey[300] : Colors.grey[100],
            child: Icon(
              Icons.drag_indicator,
              color: highlighted ? Colors.grey[600] : Colors.grey[400],
            ),
          );
        });

    MultiSplitViewTheme theme = MultiSplitViewTheme(
        data: MultiSplitViewThemeData(dividerThickness: 24),
        child: multiSplitView);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: theme,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _clearOutput(selectedTask);
        },
        backgroundColor: Colors.grey,
        child: const Icon(Icons.delete_outline_outlined),
      ),
    );
  }

  Widget _buildList(Task task) {
    return ListTile(
      leading: const Icon(Icons.terminal),
      title: Text(
        task.name,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      trailing: SizedBox(
          width: 120,
          child: Row(children: [
            SizedBox(
                width: 60,
                height: 60,
                child: (task.state == TaskState.running)
                    ? IconButton(
                        icon: const Icon(Icons.stop_circle),
                        onPressed: () => _killTask(task))
                    : IconButton(
                        icon: const Icon(Icons.play_circle),
                        onPressed: () => _runTask(task))),
            (task.state == TaskState.running)
                ? const SizedBox(
                    height: 30, width: 30, child: CircularProgressIndicator())
                : (task.state == TaskState.finished)
                    ? const Icon(Icons.done)
                    : (task.state == TaskState.aborted)
                        ? const Icon(Icons.dangerous)
                        : const Icon(Icons.device_unknown)
          ])),
      subtitle: Text(task.cmd),
      onTap: () => _selectTask(task),
      tileColor: task.id == selectedTask.id
          ? Theme.of(context).backgroundColor
          : Theme.of(context).canvasColor,
      //children: [Text("params here...")]
    );
  }
}
