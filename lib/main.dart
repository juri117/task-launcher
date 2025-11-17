// ignore_for_file: argument_type_not_assignable_to_error_handler

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:task_launcher/log_view.dart';
import 'package:task_launcher/models/task.dart';
import 'package:task_launcher/logging/my_logger.dart';
import 'package:task_launcher/theme.dart';
import 'package:task_launcher/widgets/runtime_display.dart';
import 'package:window_manager/window_manager.dart';

String versionName = "?.?.?"; // is read from pubspec.yaml

const String myTag = "main";

int maxTerminalChars = 500;
int maxTerminalCharsTrimThreshold = 20;
bool useDarkTheme = false;
String themeName = "blue";

void main(List<String> arguments) async {
  WidgetsFlutterBinding.ensureInitialized();
  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  versionName = packageInfo.version;

  Directory directory = await getApplicationDocumentsDirectory();
  if (Platform.isWindows || Platform.isLinux) {
    directory = Directory.current;
  }
  String appsPath = "${directory.path}/";
  //Directory(join(directory.path, "logs")).create();

  await MyLog().setup(appsPath);

  // Parse command line arguments
  String configFile = 'config.json'; // default config file
  for (String arg in arguments) {
    if (arg.startsWith('-config=')) {
      configFile = arg.substring(8); // Remove '-config=' prefix
    }
  }

  runApp(MyApp(
      configFile: configFile, useDarkTheme: useDarkTheme, appsPath: appsPath));
}

class MyApp extends StatefulWidget {
  final String configFile;
  final bool useDarkTheme;
  final String appsPath;
  const MyApp(
      {super.key,
      required this.configFile,
      this.useDarkTheme = false,
      required this.appsPath});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkTheme = false;
  String _themeName = "blue";

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

  void changeTheme(String themeName) {
    setState(() {
      _themeName = themeName;
    });
  }

  @override
  Widget build(BuildContext context) {
    print("build MyApp");
    ThemeData theme = FlexColorScheme.light(scheme: FlexScheme.blue).toTheme;
    ThemeData themeDark =
        FlexColorScheme.light(scheme: FlexScheme.blue).toTheme;

    // Get FlexScheme from string name

    // Handle custom themes
    switch (_themeName) {
      case "my":
        theme = AppTheme.lightTheme;
        themeDark = AppTheme.darkTheme;
        break;

      default:
        FlexScheme scheme = getFlexSchemeFromString(_themeName);
        theme = FlexColorScheme.light(scheme: scheme).toTheme;
        themeDark = FlexColorScheme.dark(scheme: scheme).toTheme;
        break;
    }

    return MaterialApp(
      title: 'Task Launcher',
      theme: theme,
      //theme: AppTheme.lightTheme,
      darkTheme: themeDark,
      themeMode: _isDarkTheme ? ThemeMode.dark : ThemeMode.light,
      home: MyHomePage(
        title: 'Task Launcher',
        configFile: widget.configFile,
        onToggleTheme: toggleTheme,
        isDarkTheme: _isDarkTheme,
        onThemeChange: changeTheme,
        appsPath: widget.appsPath,
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
    required this.onThemeChange,
    required this.appsPath,
  });
  final String title;
  final String configFile;
  final VoidCallback onToggleTheme;
  final bool isDarkTheme;
  final Function(String) onThemeChange;
  final String appsPath;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WindowListener {
  //Timer? _timer;
  //final MultiSplitViewController _splitViewController =
  //   MultiSplitViewController(); //areas: Area.weights([0.4, 0.6]));

  String _title = "";
  Tasks tasks = Tasks([], {});
  Task selectedTask = Task(0, "loading...", ".", [], {}, "", null, false);

  List<LogMessage> logMessages = [];

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _loadJsonFile(widget.configFile);
    //startTimer();
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
    //if (_timer != null) {
    //  _timer?.cancel();
    //  _timer = null;
    //}
    for (var task in tasks.tasks) {
      try {
        _killTask(task);
      } catch (ex, s) {
        MyLog().exception(myTag, "${task.name} failed to kill", ex, s);
      }
    }
  }
/*
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
  */

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
      if (jsonData.containsKey("theme")) {
        themeName = jsonData["theme"];
        widget.onThemeChange(themeName);
      }
      if (jsonData.containsKey("title")) {
        _title = jsonData["title"];
      }
      setState(() {
        tasks = Tasks.fromJson(jsonData, widget.appsPath);
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
        "\n*${'=' * 40}*\n*running command: ${task.cmd} ${task.params.join(" ")}*\n*${'-' * 40}*",
        level: "D");
    //print("${task.name} start...");
    try {
      if (task.profile.isNotEmpty) {
        if (!tasks.profiles.containsKey(task.profile)) {
          _appendOutputToTask(
              task, "*ERROR: profile ${task.profile} is not defined*",
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
        // On Linux, wrap bash/sh scripts with 'script' command to create a PTY
        // This allows interactive commands like 'sudo' to prompt for passwords
        String actualCmd = task.cmd;
        List<String> actualParams = List<String>.from(task.params);

        if (Platform.isLinux &&
            (task.cmd == 'bash' ||
                task.cmd == 'sh' ||
                task.cmd.endsWith('/bash') ||
                task.cmd.endsWith('/sh'))) {
          // Build the command string to execute within script
          // Properly quote arguments that contain spaces
          String scriptCommand = task.cmd;
          if (actualParams.isNotEmpty) {
            List<String> quotedParams = actualParams.map((param) {
              // Quote if contains spaces (most common case needing quotes)
              if (param.contains(' ')) {
                return "'${param.replaceAll("'", "'\\''")}'";
              }
              return param;
            }).toList();
            scriptCommand = "$scriptCommand ${quotedParams.join(' ')}";
          }

          // Use script command to create a PTY
          // -q: quiet mode (suppress script start/stop messages)
          // -e: return exit code of child process
          // -f: flush output after each write
          // -c: execute command
          // /dev/null: log file (we don't need it, we capture stdout/stderr)
          actualCmd = 'script';
          actualParams = ['-qefc', scriptCommand, '/dev/null'];
        }

        task.process = await Process.start(actualCmd, actualParams,
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
      _appendOutputToTask(task, "*exit code: $exitCode*", level: "D");
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
      _appendOutputToTask(task, "*failed to launch the task, reason:*",
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
    // Keep ANSI codes for styled display
    // Split by newlines and add each line as a separate log message
    String trimmed = out.trim();
    if (trimmed.isEmpty) return;
    task.addOutput(trimmed, level: level);
/*
    List<String> lines = trimmed.split('\n');
    for (int i = 0; i < lines.length; i++) {
      String line = lines[i];
      if (line.isNotEmpty || i == lines.length - 1) {
        // Add newline to all lines except the last one (if it's empty)
        if (i < lines.length - 1 || line.isNotEmpty) {
          task.addOutput("$line\n", level: level);
        }
      }
    }
    */

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
      _appendOutputToTask(task, "\n*${'-' * 40}*\n*task was aborted by user*",
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
        _appendOutputToTask(task, "*Failed to send input: $ex*", level: "E");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print("build MyHomePage");
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
            ),
            SizedBox(width: 30),
            Text(_title,
                style:
                    TextStyle(color: Theme.of(context).colorScheme.secondary)),
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
            RuntimeDisplay(task: task),
          ],
        ),
        onTap: () => _selectTask(task),
      ),
    );
  }
}
