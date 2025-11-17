import 'package:flutter/material.dart';

/// Utility class to parse ANSI escape codes and convert them to Flutter TextSpan styling
class AnsiParser {
  static List<TextSpan> parseAnsi(String text,
      {double fontSize = 14, Color? defaultColor, String? fontFamily}) {
    List<TextSpan> spans = [];
    String currentText = '';
    TextStyle currentStyle = TextStyle(
      fontSize: fontSize,
      color: defaultColor ?? Colors.black,
      fontFamily: fontFamily,
    );

    // Split by ANSI escape sequences
    RegExp ansiRegex = RegExp(r'\x1B\[[0-9;]*[a-zA-Z]');
    List<String> parts = text.split(ansiRegex);
    List<Match> matches = ansiRegex.allMatches(text).toList();

    int partIndex = 0;
    for (int i = 0; i < parts.length; i++) {
      // Add the text part
      if (parts[i].isNotEmpty) {
        spans.add(TextSpan(text: parts[i], style: currentStyle));
      }

      // Apply the ANSI code if there's a corresponding match
      if (i < matches.length) {
        String ansiCode = matches[i].group(0)!;
        currentStyle = _applyAnsiCode(currentStyle, ansiCode);
      }
    }

    return spans;
  }

  static TextStyle _applyAnsiCode(TextStyle currentStyle, String ansiCode) {
    // Extract the code numbers
    RegExp codeRegex = RegExp(r'\[([0-9;]*)m');
    Match? match = codeRegex.firstMatch(ansiCode);
    if (match == null) return currentStyle;

    String codes = match.group(1) ?? '';
    List<String> codeList =
        codes.split(';').where((c) => c.isNotEmpty).toList();

    TextStyle newStyle = currentStyle;
    bool bold = false;
    bool italic = false;
    bool underline = false;
    Color? color;
    Color? backgroundColor;

    for (String code in codeList) {
      int? numCode = int.tryParse(code);
      if (numCode == null) continue;

      switch (numCode) {
        case 0: // Reset
          bold = false;
          italic = false;
          underline = false;
          color = null;
          backgroundColor = null;
          break;
        case 1: // Bold
          bold = true;
          break;
        case 3: // Italic
          italic = true;
          break;
        case 4: // Underline
          underline = true;
          break;
        case 30: // Black
          color = Colors.black;
          break;
        case 31: // Red
          color = Colors.red;
          break;
        case 32: // Green
          color = Colors.green;
          break;
        case 33: // Yellow
          color = Colors.yellow;
          break;
        case 34: // Blue
          color = Colors.blue;
          break;
        case 35: // Magenta
          color = Colors.purple;
          break;
        case 36: // Cyan
          color = Colors.cyan;
          break;
        case 37: // White
          color = Colors.white;
          break;
        case 90: // Bright Black (Gray)
          color = Colors.grey[600];
          break;
        case 91: // Bright Red
          color = Colors.red[300];
          break;
        case 92: // Bright Green
          color = Colors.green[300];
          break;
        case 93: // Bright Yellow
          color = Colors.yellow[300];
          break;
        case 94: // Bright Blue
          color = Colors.blue[300];
          break;
        case 95: // Bright Magenta
          color = Colors.purple[300];
          break;
        case 96: // Bright Cyan
          color = Colors.cyan[300];
          break;
        case 97: // Bright White
          color = Colors.grey[100];
          break;
        // Background colors
        case 40: // Black background
          backgroundColor = Colors.black;
          break;
        case 41: // Red background
          backgroundColor = Colors.red;
          break;
        case 42: // Green background
          backgroundColor = Colors.green;
          break;
        case 43: // Yellow background
          backgroundColor = Colors.yellow;
          break;
        case 44: // Blue background
          backgroundColor = Colors.blue;
          break;
        case 45: // Magenta background
          backgroundColor = Colors.purple;
          break;
        case 46: // Cyan background
          backgroundColor = Colors.cyan;
          break;
        case 47: // White background
          backgroundColor = Colors.white;
          break;
      }
    }

    return newStyle.copyWith(
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      fontStyle: italic ? FontStyle.italic : FontStyle.normal,
      decoration: underline ? TextDecoration.underline : TextDecoration.none,
      color: color,
      backgroundColor: backgroundColor,
    );
  }
}
