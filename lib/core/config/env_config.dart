import 'package:flutter/foundation.dart';
import '../constants.dart';
import '../../api_keys.dart';

/// Environment configuration for Legal AI app.
class EnvConfig {
  /// The name of the app.
  static const String appName = 'Legal AI';

  /// Whether the app is running in production mode.
  static bool get isProduction => const bool.fromEnvironment('dart.vm.product');

  /// Whether the app is running in development mode.
  static bool get isDevelopment => !isProduction;

  /// The Gemini API key (from ApiKeys class).
  static String get geminiApiKey => ApiKeys.geminiApiKey;

  /// Validate essential environment variables.
  static void validate() {
    if (geminiApiKey.isEmpty) {
      throw Exception('Missing Gemini API key. Please set it in ApiKeys.');
    }
  }
}
