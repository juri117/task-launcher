import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class LogView extends StatefulWidget {
  final List<LogMessage> logMessages;
  final VoidCallback? onClear;
  final double fontSize;
  final bool canSendInput;
  final Function(String)? onSendInput;
  const LogView(this.logMessages,
      {super.key,
      this.fontSize = 14,
      this.onClear,
      this.canSendInput = false,
      this.onSendInput});

  @override
  LogViewStat createState() => LogViewStat();
}

class LogViewStat extends State<LogView> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _inputController = TextEditingController();

  bool _needsScroll = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _scrollToEnd({bool force = false}) async {
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

  void _sendInput() {
    if (_inputController.text.isNotEmpty && widget.onSendInput != null) {
      widget.onSendInput!(_inputController.text);
      _inputController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> logLines = [];
    for (var element in widget.logMessages) {
      logLines.add(SelectableText(element.toString(),
          style: TextStyle(
              fontSize: widget.fontSize, color: element.getColor(context))));
    }
    _scrollToEnd();

    return Column(
      children: [
        Expanded(
          child: Stack(children: [
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
                      FloatingActionButton(
                        mini: true,
                        child: const Icon(Icons.copy),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(
                              text: widget.logMessages.join("\n")));
                        },
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      FloatingActionButton(
                        mini: true,
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
                      FloatingActionButton(
                        mini: true,
                        backgroundColor: _needsScroll
                            ? Theme.of(context).colorScheme.secondary
                            : Colors.grey,
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
          ]),
        ),
        if (widget.canSendInput)
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1.0,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    decoration: const InputDecoration(
                      hintText: 'Type input for the running task...',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                    ),
                    onSubmitted: (_) => _sendInput(),
                    autofocus: true,
                  ),
                ),
                const SizedBox(width: 8.0),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendInput,
                  tooltip: 'Send input to task',
                ),
              ],
            ),
          ),
      ],
    );
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

  Color getColor(BuildContext context) {
    switch (level) {
      case "I":
        return Theme.of(context).colorScheme.primary;
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
