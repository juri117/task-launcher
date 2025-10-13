// ignore_for_file: argument_type_not_assignable_to_error_handler

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:flutter/material.dart';
import 'package:task_launcher/log_view.dart';
import 'package:task_launcher/models/task.dart';
import 'package:task_launcher/logging/my_logger.dart';
import 'package:task_launcher/theme.dart';
import 'package:window_manager/window_manager.dart';

String versionName = "?.?.?"; // is read from pubspec.yaml

const String myTag = "main";

int maxTerminalChars = 500;
int maxTerminalCharsTrimThreshold = 20;
bool useDarkTheme = false;

void main(List<String> arguments) async {
  WidgetsFlutterBinding.ensureInitialized();
  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  versionName = packageInfo.version;

  await MyLog().setup();

  // Parse command line arguments
  String configFile = 'setup.json'; // default config file
  for (String arg in arguments) {
    if (arg.startsWith('-config=')) {
      configFile = arg.substring(8); // Remove '-config=' prefix
    }
  }

  runApp(MyApp(configFile: configFile, useDarkTheme: useDarkTheme));
}

class MyApp extends StatefulWidget {
  final String configFile;
  final bool useDarkTheme;

  const MyApp({super.key, required this.configFile, this.useDarkTheme = false});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkTheme = false;

  @override
  void initState() {
    super.initState();
    _isDarkTheme = widget.useDarkTheme;
  }

  void toggleTheme() {
    setState(() {
      _isDarkTheme = !_isDarkTheme;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Launcher',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _isDarkTheme ? ThemeMode.dark : ThemeMode.light,
      home: MyHomePage(
        title: 'Task Launcher',
        configFile: widget.configFile,
        onToggleTheme: toggleTheme,
        isDarkTheme: _isDarkTheme,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
    required this.title,
    required this.configFile,
    required this.onToggleTheme,
    required this.isDarkTheme,
  });
  final String title;
  final String configFile;
  final VoidCallback onToggleTheme;
  final bool isDarkTheme;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WindowListener {
  Timer? _timer;
  //final MultiSplitViewController _splitViewController =
  //   MultiSplitViewController(); //areas: Area.weights([0.4, 0.6]));

  Tasks tasks = Tasks([], {});
  Task selectedTask = Task(0, "loading...", ".", [], {}, "", null, false);

  List<LogMessage> logMessages = [];

  @override
  void initState() {
    super.initState();
/*
    Widget left = ListView.builder(
      shrinkWrap: true,
      itemCount: tasks.tasks.length,
      itemBuilder: (context, index) {
        return _buildList(tasks.tasks[index]);
      },
    );
    Widget right = LogView(
      logMessages,
      onClear: () {
        _clearOutput(selectedTask);
      },
    );
    _splitViewController.addArea(Area(min: 300, size: 350, data: left));
    _splitViewController.addArea(Area(min: 300, size: 500, data: right));
*/
    windowManager.addListener(this);
    _loadJsonFile(widget.configFile);
    startTimer();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  //@override
  //void onWindowEvent(String eventName) {
  //  print('[WindowManager] onWindowEvent: $eventName');
  //}

  @override
  void onWindowClose() {
    //print("win close");
    cleanupOnCLose();
  }

  void cleanupOnCLose() {
    if (_timer != null) {
      _timer?.cancel();
      _timer = null;
    }
    for (var task in tasks.tasks) {
      try {
        _killTask(task);
      } catch (ex, s) {
        MyLog().exception(myTag, "${task.name} failed to kill", ex, s);
      }
    }
  }

  void startTimer() {
    if (_timer != null) {
      _timer?.cancel();
      _timer = null;
    }
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (Timer timer) {
        updateTaskTimes();
      },
    );
  }

  Future<void> updateTaskTimes() async {
    setState(() {
      for (var task in tasks.tasks) {
        if (task.state == TaskState.running) {
          task.runtimeStr = task.getRuntime();
        }
      }
    });
  }

  Future<void> _loadJsonFile(String configFile) async {
    try {
      final file = File(configFile);
      if (!await file.exists()) {
        MyLog().error(myTag, "Config file '$configFile' does not exist");
        return;
      }
      final content = await file.readAsString();
      final jsonData = jsonDecode(content);
      if (jsonData.containsKey("maxLogLines")) {
        maxTerminalChars = jsonData["maxLogLines"];
        maxTerminalCharsTrimThreshold = (maxTerminalChars * 0.05).round();
      }
      if (jsonData.containsKey("useDarkTheme")) {
        useDarkTheme = jsonData["useDarkTheme"];
      }
      setState(() {
        tasks = Tasks.fromJson(jsonData);
        if (tasks.tasks.isNotEmpty) {
          selectedTask = tasks.tasks[0];
        }
      });
      MyLog().info(myTag, "Loaded config from '$configFile'");
    } catch (ex, s) {
      MyLog()
          .exception(myTag, "Failed to load config file '$configFile'", ex, s);
    }
  }

  Future<void> _runTask(Task task) async {
    _selectTask(task);
    task.start();
    _taskChangeState(task, TaskState.running);
    _appendOutputToTask(task,
        "\n*${'=' * 40}*\n*running command: ${task.cmd} ${task.params.join(" ")}*\n*${'-' * 40}*\n",
        level: "D");
    //print("${task.name} start...");
    try {
      if (task.profile.isNotEmpty) {
        if (!tasks.profiles.containsKey(task.profile)) {
          _appendOutputToTask(
              task, "*ERROR: profile ${task.profile} is not defined*\n",
              level: "E");
          return;
        }
        var profile = tasks.profiles[task.profile];
        task.process = await Process.start(
            "\"${profile?.executable}\"", profile?.params ?? [],
            workingDirectory: task.workingDir,
            environment: task.env,
            mode: ProcessStartMode.normal);
        for (var setupRow in profile?.setup ?? []) {
          task.process?.stdin.writeln(setupRow);
        }
        task.process?.stdin
            .writeln("${task.cmd} ${task.params.join(" ")} && exit");
      } else {
        task.process = await Process.start(task.cmd, task.params,
            workingDirectory: task.workingDir,
            environment: task.env,
            mode: ProcessStartMode.normal);
      }
      MyLog().info(myTag, "${task.name} started");
      final Completer<int?> completer = Completer<int?>();

      task.process?.stdout.listen((event) {
        try {
          var test = const Utf8Decoder().convert(event);
          _appendOutputToTask(task, test, level: "I");
        } catch (ex, s) {
          MyLog().exception(
              myTag, "${task.name} exception in process listen stdout", ex, s);
        }
      }, onDone: () async {
        completer.complete(await task.process?.exitCode);
      }, onError: (ex, s) {
        //print("error: $error, $stack");
        // _appendOutputToTask(task, "error: $error", level: "E");
        MyLog().exception(
            myTag, "${task.name} exception in process listen stdout", ex, s);
      }, cancelOnError: false);

      task.process?.stderr.listen((event) {
        //print("${task.name} event -> $event");
        try {
          var test = const Utf8Decoder().convert(event);
          _appendOutputToTask(task, test, level: "I");
        } catch (ex, s) {
          // print("${task.name} exception in process listen stderr: $e");
          MyLog().exception(
              myTag, "${task.name} exception in process listen stderr", ex, s);
        }
      }, onDone: () async {
        //print("${task.name} onDone");
      }, onError: (error, stack) {
        //print("${task.name} onError stderr error: $error, $stack");
        _appendOutputToTask(task, "error: $error", level: "E");
      }, cancelOnError: false);
      // print("${task.name} listener added");
      final int? exitCode = await completer.future;
      //print("${task.name} completed $exitCode");
      _appendOutputToTask(task, "*exit code: $exitCode*\n", level: "D");
      if (task.state != TaskState.aborted) {
        if (exitCode == null) {
          //print('${task.name} failed null');
          _taskChangeState(task, TaskState.failed);
        } else if (exitCode != 0) {
          //print('${task.name} failed $exitCode');
          _taskChangeState(task, TaskState.failed);
        } else {
          //print('${task.name} finished $exitCode');
          _taskChangeState(task, TaskState.finished);
        }
      }
    } catch (ex, s) {
      // print('${task.name} exception $e');
      MyLog().exception(
          myTag, "${task.name} exception in process listen stderr", ex, s);
      _taskChangeState(task, TaskState.failed);
      _appendOutputToTask(task, "*failed to launch the task, reason:*\n",
          level: "E");
      _appendOutputToTask(task, "$ex\n", level: "E");
    }
    task.finished();
    // print('${task.name} finished');
  }

  void _taskChangeState(Task task, TaskState newState) {
    setState(() {
      task.state = newState;
    });
  }

  void _appendOutputToTask(Task task, String out, {String level = "I"}) {
    if (task.logToFile) {
      MyLog().generic("task-${task.name}", out, level);
    }
    task.addOutput(out.trim(), level: level);
    task.trimStdout(maxTerminalChars, maxTerminalCharsTrimThreshold);
    if (task.id == selectedTask.id) {
      setState(() {
        logMessages = task.output;
      });
    }
  }

  void _killTask(Task task) {
    var pid = task.process?.pid;
    if (pid != null) {
      task.process?.kill(ProcessSignal.sigint);
      //Process.killPid(pid);
      _taskChangeState(task, TaskState.aborted);
      _appendOutputToTask(task, "\n*${'-' * 40}*\n*task was aborted by user*\n",
          level: "W");
    }
    task.finished();
  }

  Future<void> _clearOutput(Task task) async {
    task.output = [];
    setState(() {
      logMessages = task.output;
    });
  }

  Future<void> _selectTask(Task task) async {
    // selectedTask.scrollOffset = 0;
    setState(() {
      selectedTask = task;
      logMessages = task.output;
    });
  }

  void _sendInputToTask(Task task, String input) {
    if (task.state == TaskState.running && task.process != null) {
      try {
        task.process!.stdin.writeln(input);
        _appendOutputToTask(task, "> $input\n", level: "D");
      } catch (ex, s) {
        MyLog().exception(myTag, "${task.name} failed to send input", ex, s);
        _appendOutputToTask(task, "*Failed to send input: $ex*\n", level: "E");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget left = ListView.builder(
      shrinkWrap: true,
      itemCount: tasks.tasks.length,
      itemBuilder: (context, index) {
        return _buildList(tasks.tasks[index], context);
      },
    );
    Widget right = LogView(
      logMessages,
      onClear: () {
        _clearOutput(selectedTask);
      },
      canSendInput: selectedTask.state == TaskState.running,
      onSendInput: (String input) {
        _sendInputToTask(selectedTask, input);
      },
    );

    /*
    MultiSplitView multiSplitView = MultiSplitView(
        //controller: _splitViewController,
        initialAreas: [
          Area(builder: (context, area) => left),
          Area(builder: (context, area) => right)
        ],
        //builder: (BuildContext context, Area area) {
        //  return area.data;
        //},
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
    */

    return Scaffold(
        appBar: AppBar(
          title: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.title),
            const SizedBox(
              width: 10,
            ),
            Text(
              "v: $versionName",
              style: TextStyle(
                fontSize: 10,
              ),
            )
          ]),
          actions: [
            IconButton(
              icon:
                  Icon(widget.isDarkTheme ? Icons.light_mode : Icons.dark_mode),
              onPressed: widget.onToggleTheme,
              tooltip: widget.isDarkTheme
                  ? 'Switch to light theme'
                  : 'Switch to dark theme',
            ),
          ],
        ),
        drawer: Drawer(
            child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
                //decoration: BoxDecoration(
                //  color: Theme.of(context).primaryColorDark,
                //),
                child: const Text("menu")),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: Text('reload ${widget.configFile}'),
              onTap: () {
                Navigator.pop(context);
                _loadJsonFile(widget.configFile);
              },
            ),
          ],
        )),
        body: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 350, child: left),
            VerticalDivider(
              width: 1,
              thickness: 1,
            ),
            Expanded(child: right)
          ],
        )
        //theme,
        );
  }

  Widget _buildList(Task task, BuildContext context) {
    final bool isSelected = task.id == selectedTask.id;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: AppTheme.getElevatedTileDecoration(context, isSelected),
      child: ListTile(
        dense: true,
        leading: const Icon(Icons.terminal, size: 20),
        title: Text(
          task.name,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        trailing: SizedBox(
            width: 80,
            child: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
              SizedBox(
                  width: 50,
                  height: 50,
                  child: (task.state == TaskState.running)
                      ? IconButton(
                          icon: const Icon(Icons.stop_circle, size: 20),
                          onPressed: () => _killTask(task))
                      : IconButton(
                          icon: const Icon(Icons.play_circle, size: 20),
                          onPressed: () => _runTask(task))),
              (task.state == TaskState.running)
                  ? Icon(Icons.running_with_errors,
                      color: AppTheme.getRunningColor(context), size: 16)
                  : (task.state == TaskState.finished)
                      ? Icon(Icons.done,
                          color: AppTheme.getFinishedColor(context), size: 16)
                      : (task.state == TaskState.aborted)
                          ? Icon(Icons.cancel_outlined,
                              color: AppTheme.getAbortedColor(context),
                              size: 16)
                          : (task.state == TaskState.failed)
                              ? Icon(Icons.error_outline,
                                  color: AppTheme.getFailedColor(context),
                                  size: 16)
                              : const SizedBox(width: 16, height: 16)
            ])),
        subtitle: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("started at: ${task.getStartTime()}",
                style: const TextStyle(fontSize: 11)),
            Text("it took: ${task.runtimeStr}",
                style: const TextStyle(fontSize: 11)),
          ],
        ),
        onTap: () => _selectTask(task),
      ),
    );
  }
}
