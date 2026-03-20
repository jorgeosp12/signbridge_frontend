class RuntimeConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'SIGNBRIDGE_API_URL',
    defaultValue: 'http://localhost:8000',
  );

  static const apiKey = String.fromEnvironment(
    'SIGNBRIDGE_API_KEY',
    defaultValue: 'ptxisT_TVpNF3Ico2IjZlO5UoCA1bNIoHV2BvNB7G7I',
  );

  static const enableBrowserTts = bool.fromEnvironment(
    'SIGNBRIDGE_ENABLE_TTS',
    defaultValue: true,
  );

  static const ttsLanguage = String.fromEnvironment(
    'SIGNBRIDGE_TTS_LANG',
    defaultValue: 'auto',
  );
}
