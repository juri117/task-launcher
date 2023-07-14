import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const int maxLogMsgLength = 256;

class LogMessage {
  final DateTime ts = DateTime.now();
  final String level;
  final String tag;
  final String msg;
  LogMessage(this.level, this.tag, this.msg) {
    // level = this.msg[0];
  }

  @override
  String toString() {
    if (tag == "") return "${DateFormat('kk:mm:ss').format(ts)}: $msg";
    return "${DateFormat('kk:mm:ss').format(ts)}: $tag - $msg";
  }

  String getDateTimeStr() {
    return DateFormat('dd.MM.yyyy – kk:mm:ss').format(ts);
  }

  Color getColor() {
    switch (level) {
      case "I":
        return Colors.black;
      case "W":
        return Colors.orange;
      case "E":
        return Colors.red;
      case "X":
        return Colors.red;
      case "D":
        return Colors.yellow;
    }
    return Colors.black;
  }
}
