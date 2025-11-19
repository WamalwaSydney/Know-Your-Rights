// lib/core/services/preferences_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _themeKey = 'theme_mode';
  static const String _notificationsKey = 'notifications_enabled';
  static const String _languageKey = 'language';
  static const String _firstLaunchKey = 'first_launch';
  static const String _autoSaveKey = 'auto_save_enabled';

  // Singleton pattern
  static final PreferencesService _instance = PreferencesService._internal();
  factory PreferencesService() => _instance;
  PreferencesService._internal();

  SharedPreferences? _prefs;

  // Initialize preferences
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Theme Mode (dark, light, system)
  Future<void> setThemeMode(String mode) async {
    await _prefs?.setString(_themeKey, mode);
  }

  String getThemeMode() {
    return _prefs?.getString(_themeKey) ?? 'dark';
  }

  // Notifications
  Future<void> setNotificationsEnabled(bool enabled) async {
    await _prefs?.setBool(_notificationsKey, enabled);
  }

  bool getNotificationsEnabled() {
    return _prefs?.getBool(_notificationsKey) ?? true;
  }

  // Language
  Future<void> setLanguage(String languageCode) async {
    await _prefs?.setString(_languageKey, languageCode);
  }

  String getLanguage() {
    return _prefs?.getString(_languageKey) ?? 'en';
  }

  // First Launch
  Future<void> setFirstLaunch(bool isFirst) async {
    await _prefs?.setBool(_firstLaunchKey, isFirst);
  }

  bool isFirstLaunch() {
    return _prefs?.getBool(_firstLaunchKey) ?? true;
  }

  // Auto Save
  Future<void> setAutoSaveEnabled(bool enabled) async {
    await _prefs?.setBool(_autoSaveKey, enabled);
  }

  bool getAutoSaveEnabled() {
    return _prefs?.getBool(_autoSaveKey) ?? true;
  }

  // Clear all preferences
  Future<void> clearAll() async {
    await _prefs?.clear();
  }

  // Export all preferences (useful for debugging)
  Map<String, dynamic> exportPreferences() {
    return {
      'theme_mode': getThemeMode(),
      'notifications_enabled': getNotificationsEnabled(),
      'language': getLanguage(),
      'first_launch': isFirstLaunch(),
      'auto_save_enabled': getAutoSaveEnabled(),
    };
  }
}