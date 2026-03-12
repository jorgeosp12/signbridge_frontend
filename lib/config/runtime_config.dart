class RuntimeConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'SIGNBRIDGE_API_URL',
    defaultValue: 'http://localhost:8000',
  );

  static const apiKey = String.fromEnvironment(
    'SIGNBRIDGE_API_KEY',
    defaultValue: '',
  );

  static const enableBrowserTts = bool.fromEnvironment(
    'SIGNBRIDGE_ENABLE_TTS',
    defaultValue: true,
  );
}
