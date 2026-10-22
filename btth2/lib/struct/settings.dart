import 'package:flutter/material.dart';

class SettingsGlobal extends ChangeNotifier {
  bool isDarkMode = false;
  String currentLanguage = 'vi';

  void toggleTheme() {
    isDarkMode = !isDarkMode;
    notifyListeners();
  }
}

final SettingsGlobal appSettings = SettingsGlobal();
