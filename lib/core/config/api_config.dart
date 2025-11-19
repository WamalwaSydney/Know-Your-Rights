// lib/core/config/api_config.dart
class ApiConfig {
  // Groq API Configuration (Hardcoded)
  static const String groqApiKey =
      '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';

  static const String groqBaseUrl = 'https://api.groq.com/openai/v1';
  static const String groqModel = 'llama-3.1-8b-instant';

  // Alternative models:
  // 'llama-3.1-8b-instant'
  // 'mixtral-8x7b-32768'
  // 'gemma2-9b-it'

  // API Settings
  static const int requestTimeout = 60; // seconds
  static const int maxRetries = 3;
  static const double temperature = 0.7;
  static const int maxTokens = 2048;

  // Rate limits (Groq free tier)
  static const int requestsPerMinute = 30;
  static const int requestsPerDay = 14400;

  // Validate configuration
  static bool isConfigured() {
    return groqApiKey.isNotEmpty && groqApiKey.startsWith('gsk_');
  }

  static String getConfigurationError() {
    if (groqApiKey.isEmpty) {
      return 'Groq API key missing.';
    }
    if (!groqApiKey.startsWith('gsk_')) {
      return 'Invalid Groq API key format. Must start with "gsk_".';
    }
    return 'Unknown configuration error';
  }
}
