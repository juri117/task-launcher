import 'package:flutter/material.dart';

// Theme color constants - change these to customize the appearance
const Color _primaryColor = Color.fromARGB(255, 207, 57, 187); // Forest green
const Color _primaryVariant = Color.fromARGB(255, 217, 95, 228); // Darker green
const Color _secondaryColor = Color.fromARGB(255, 101, 93, 209); // Blue
const Color _secondaryVariant =
    Color.fromARGB(255, 102, 92, 241); // Darker blue
const Color _surfaceColor = Color(0xFFF5F5F5); // Light gray
const Color _backgroundColor = Color(0xFFFFFFFF); // White
const Color _errorColor = Color(0xFFD32F2F); // Red
const Color _onPrimaryColor = Color(0xFFFFFFFF); // White
const Color _onSecondaryColor = Color(0xFFFFFFFF); // White
const Color _onSurfaceColor = Color(0xFF212121); // Dark gray
const Color _onBackgroundColor = Color(0xFF212121); // Dark gray
const Color _onErrorColor = Color(0xFFFFFFFF); // White

// Dark theme color constants
const Color _darkPrimaryColor = Color(0xFF4CAF50); // Light green
const Color _darkPrimaryVariant = Color(0xFF2E7D32); // Forest green
const Color _darkSecondaryColor = Color(0xFF2196F3); // Light blue
const Color _darkSecondaryVariant = Color(0xFF1976D2); // Blue
const Color _darkSurfaceColor = Color(0xFF303030); // Dark gray
const Color _darkBackgroundColor = Color(0xFF121212); // Very dark gray
const Color _darkErrorColor = Color(0xFFCF6679); // Light red
const Color _darkOnPrimaryColor = Color(0xFF000000); // Black
const Color _darkOnSecondaryColor = Color(0xFF000000); // Black
const Color _darkOnSurfaceColor = Color(0xFFFFFFFF); // White
const Color _darkOnBackgroundColor = Color(0xFFFFFFFF); // White
const Color _darkOnErrorColor = Color(0xFF000000); // Black

// Task state colors
const Color _runningColor = Color(0xFF2196F3); // Blue
const Color _finishedColor = Color(0xFF4CAF50); // Green
const Color _failedColor = Color(0xFFF44336); // Red
const Color _abortedColor = Color(0xFFFF9800); // Orange

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: _primaryColor,
        primaryContainer: _primaryVariant,
        secondary: _secondaryColor,
        secondaryContainer: _secondaryVariant,
        surface: _surfaceColor,
        background: _backgroundColor,
        error: _errorColor,
        onPrimary: _onPrimaryColor,
        onSecondary: _onSecondaryColor,
        onSurface: _onSurfaceColor,
        onBackground: _onBackgroundColor,
        onError: _onErrorColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: _primaryColor,
        foregroundColor: _onPrimaryColor,
        elevation: 2,
      ),
      cardTheme: const CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        dense: true,
        minVerticalPadding: 4,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        thickness: 1,
        color: Color(0xFFE0E0E0),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: _darkPrimaryColor,
        primaryContainer: _darkPrimaryVariant,
        secondary: _darkSecondaryColor,
        secondaryContainer: _darkSecondaryVariant,
        surface: _darkSurfaceColor,
        background: _darkBackgroundColor,
        error: _darkErrorColor,
        onPrimary: _darkOnPrimaryColor,
        onSecondary: _darkOnSecondaryColor,
        onSurface: _darkOnSurfaceColor,
        onBackground: _darkOnBackgroundColor,
        onError: _darkOnErrorColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: _darkPrimaryColor,
        foregroundColor: _darkOnPrimaryColor,
        elevation: 2,
      ),
      cardTheme: const CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        dense: true,
        minVerticalPadding: 4,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        thickness: 1,
        color: Color(0xFF424242),
      ),
    );
  }

  // Task state colors that work with both themes
  static Color getRunningColor(BuildContext context) {
    return _runningColor;
  }

  static Color getFinishedColor(BuildContext context) {
    return _finishedColor;
  }

  static Color getFailedColor(BuildContext context) {
    return _failedColor;
  }

  static Color getAbortedColor(BuildContext context) {
    return _abortedColor;
  }

  // Helper method to create elevated tile decoration
  static BoxDecoration getElevatedTileDecoration(
      BuildContext context, bool isSelected) {
    return BoxDecoration(
      color: isSelected
          ? Color.alphaBlend(
              Theme.of(context).colorScheme.secondary.withValues(alpha: 0.15),
              Theme.of(context)
                  .colorScheme
                  .surface) //Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1)
          : Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        width: isSelected ? 2 : 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
        if (isSelected)
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
      ],
    );
  }
}
