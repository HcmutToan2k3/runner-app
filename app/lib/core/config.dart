/// Values are passed at build time so keys never live in git:
///   flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
class AppConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// GPS points worse than this are ignored.
  static const maxAccuracyM = 25.0;

  /// ~7 m/s is a 2:23 /km pace: faster than any school runner, slower than a bike.
  static const maxSpeedMps = 7.0;
}
