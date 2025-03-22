import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();

    // Сохраняем тему в SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', mode.toString());
  }

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString('theme') ?? 'system';

    switch (themeString) {
      case 'ThemeMode.dark':
        _themeMode = ThemeMode.dark;
        break;
      case 'ThemeMode.light':
        _themeMode = ThemeMode.light;
        break;
      default:
        _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }
}