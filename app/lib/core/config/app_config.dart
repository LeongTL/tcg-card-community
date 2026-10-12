class AppConfig {
  const AppConfig({
    required this.flavor,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
  });

  final String flavor;
  final String supabaseUrl;
  final String supabaseAnonKey;

  /// Reads the values passed with `--dart-define-from-file`.
  factory AppConfig.fromEnvironment() => AppConfig.fromMap(const {
        'FLAVOR': String.fromEnvironment('FLAVOR'),
        'SUPABASE_URL': String.fromEnvironment('SUPABASE_URL'),
        'SUPABASE_ANON_KEY': String.fromEnvironment('SUPABASE_ANON_KEY'),
      });

  /// Fails fast on a missing or empty key.
  factory AppConfig.fromMap(Map<String, String> env) {
    String need(String key) {
      final value = env[key];
      if (value == null || value.isEmpty) {
        throw StateError('Missing config value: $key');
      }
      return value;
    }

    return AppConfig(
      flavor: need('FLAVOR'),
      supabaseUrl: need('SUPABASE_URL'),
      supabaseAnonKey: need('SUPABASE_ANON_KEY'),
    );
  }
}
