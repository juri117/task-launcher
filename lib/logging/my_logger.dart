import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';

import 'package:task_launcher/logging/log_message.dart';

const int maxTerminalChars = 50000;
const int maxTerminalCharsTrimThreshold = 5000;

class MyLog extends ChangeNotifier {
  static final MyLog _singleton = MyLog._internal();

  List<LogMessage> history = [];

  // Map<String, Logger> _loggers = {};
  //bool _isSetup = false;

  final _workerQue = StreamController<Future>();

  IOSink? _out;

  factory MyLog() {
    return _singleton;
  }

  MyLog._internal();

  Future<void> setup() async {
    //print("setup LOG...");

    _workerQue.stream
        .asyncMap((future) async => await future)
        .listen((_) {}, cancelOnError: false);

    Directory directory = await getApplicationDocumentsDirectory();
    if (Platform.isWindows || Platform.isLinux) {
      directory = Directory.current;
    }
    Directory(join(directory.path, "logs")).create();

    final DateFormat format = DateFormat('yyyy-MM-dd_HH-mm-ss');
    final String formatted = format.format(DateTime.now().toUtc());
    String fullPath = join(directory.path, "logs/${formatted}_rp_log.txt");
    File logFile = File(fullPath);
    _out = logFile.openWrite();
  }

  void addToHistory(LogMessage msg) {
    history.add(msg);
    while (history.length > maxLogMsgLength) {
      history.removeRange(maxLogMsgLength, history.length);
    }
  }

  Future<void> _log(LogMessage log) async {
    String logStr =
        "${log.level}: ${log.getDateTimeStr()}: ${log.tag}: ${log.msg}";
    if (_out != null) {
      _out?.write("$logStr\n");
    }
    // ignore: avoid_print
    print(logStr);
    addToHistory(log);
    notifyListeners();
  }

  void info(String tag, String message) {
    _workerQue.add(_log(LogMessage("I", tag, message)));
  }

  void warning(String tag, String message) {
    _workerQue.add(_log(LogMessage("W", tag, message)));
  }

  void error(String tag, String message) {
    _workerQue.add(_log(LogMessage("E", tag, message)));
  }

  void debug(String tag, String message) {
    _workerQue.add(_log(LogMessage("D", tag, message)));
  }

  void exception(String tag, String message, Object exception, StackTrace? s) {
    _workerQue.add(_log(LogMessage("X", tag, "$message: $exception\n$s")));
  }

  void generic(String tag, String message, String level) {
    _workerQue.add(_log(LogMessage(level, tag, message)));
  }
}
