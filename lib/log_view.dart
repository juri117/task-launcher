import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class LogView extends StatefulWidget {
  final List<LogMessage> logMessages;
  final VoidCallback? onClear;
  final double fontSize;
  const LogView(this.logMessages,
      {super.key, this.fontSize = 14, this.onClear});

  @override
  LogViewStat createState() => LogViewStat();
}

class LogViewStat extends State<LogView> {
  final ScrollController _scrollController = ScrollController();

  bool _needsScroll = true;

  @override
  void initState() {
    super.initState();
  }

  _scrollToEnd({bool force = false}) async {
    if (_needsScroll || force) {
      try {
        if (_scrollController.hasClients) {
          Future.delayed(const Duration(milliseconds: 100), () {
            _scrollController
                .jumpTo(_scrollController.position.maxScrollExtent);
          });
        }
      } catch (e) {
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> logLines = [];
    for (var element in widget.logMessages) {
      logLines.add(Text(element.toString(),
          style:
              TextStyle(fontSize: widget.fontSize, color: element.getColor())));
    }
    _scrollToEnd();

    return Stack(children: [
      Container(
          alignment: Alignment.topLeft,
          child: LayoutBuilder(builder: (context, constraint) {
            return Scrollbar(
                controller: _scrollController,
                child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    controller: _scrollController,
                    child: ConstrainedBox(
                        constraints:
                            BoxConstraints(minWidth: constraint.maxWidth),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: logLines,
                        ))));
          })),
      Container(
          alignment: Alignment.bottomRight,
          child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Column(children: [
                ElevatedButton(
                  child: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(
                        ClipboardData(text: widget.logMessages.join("\n")));
                  },
                ),
                const SizedBox(
                  height: 5,
                ),
                ElevatedButton(
                  child: const Icon(Icons.delete_outline_outlined),
                  onPressed: () {
                    if (widget.onClear != null) {
                      widget.onClear!();
                    }
                  },
                ),
                const SizedBox(
                  height: 5,
                ),
                ElevatedButton(
                  style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(
                          _needsScroll
                              ? Theme.of(context).colorScheme.secondary
                              : Colors.grey)),
                  child: const Icon(Icons.arrow_downward),
                  onPressed: () {
                    if (!mounted) return;
                    setState(() {
                      _needsScroll = !_needsScroll;
                    });
                    _scrollToEnd();
                  },
                ),
              ])))
    ]);
  }
}

class LogMessage {
  final DateTime ts = DateTime.now();
  final String level;
  final String tag;
  final String msg;
  LogMessage(this.level, this.tag, this.msg);

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
        return Colors.deepPurple;
      case "W":
        return Colors.orange;
      case "E":
        return Colors.red;
      case "X":
        return Colors.red;
      case "D":
        return Colors.grey;
    }
    return Colors.black;
  }
}
