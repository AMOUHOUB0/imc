import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _locale = Locale('en');  // Langue par défaut

  LanguageProvider() {
    loadSavedLanguage();
  }

  Locale get locale => _locale;

  Future<void> loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String languageCode = prefs.getString('language_code') ?? 'en';
      _locale = Locale(languageCode);
      notifyListeners();
    } catch (e) {
      print("Error loading saved language: $e");
    }
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language_code', locale.languageCode);
    } catch (e) {
      print("Error saving language preference: $e");
    }
    notifyListeners();
  }

  // Liste des langues disponibles
  List<Map<String, dynamic>> get languages => [
    {'name': 'English', 'locale': Locale('en')},
    {'name': 'Français', 'locale': Locale('fr')},
    {'name': 'العربية', 'locale': Locale('ar')},
    {'name': 'Español', 'locale': Locale('es')},
  ];
}