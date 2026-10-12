import 'package:flutter_test/flutter_test.dart';
import 'package:tcg_card_app/core/config/app_config.dart';

void main() {
  test('reads_flavor_and_keys_from_environment', () {
    final config = AppConfig.fromMap({
      'FLAVOR': 'staging',
      'SUPABASE_URL': 'https://example.supabase.co',
      'SUPABASE_ANON_KEY': 'anon-key',
    });

    expect(config.flavor, 'staging');
    expect(config.supabaseUrl, 'https://example.supabase.co');
    expect(config.supabaseAnonKey, 'anon-key');
  });

  test('throws_when_a_key_is_missing', () {
    expect(
      () => AppConfig.fromMap({
        'FLAVOR': 'dev',
        'SUPABASE_ANON_KEY': 'anon-key',
      }),
      throwsStateError,
    );
  });

  test('throws_when_a_key_is_empty', () {
    expect(
      () => AppConfig.fromMap({
        'FLAVOR': 'dev',
        'SUPABASE_URL': '',
        'SUPABASE_ANON_KEY': 'anon-key',
      }),
      throwsStateError,
    );
  });
}
