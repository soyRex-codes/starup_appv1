import 'package:flutter_dotenv/flutter_dotenv.dart' as dotenv;

class AppEnv {
  static String get supabaseUrl =>
      dotenv.dotenv.maybeGet('SUPABASE_URL') ??
      const String.fromEnvironment('SUPABASE_URL');
  static String get supabaseAnonKey =>
      dotenv.dotenv.maybeGet('SUPABASE_ANON_KEY') ??
      const String.fromEnvironment('SUPABASE_ANON_KEY');
  static String get startupbuilderBucket =>
      dotenv.dotenv.maybeGet('STARTUPBUILDER_BUCKET') ?? 'startupbuilder';
  static String get applicationsBucket =>
      dotenv.dotenv.maybeGet('APPLICATIONS_BUCKET') ?? 'applications';

  static List<String> get adminEmails {
    final raw = dotenv.dotenv.maybeGet('ADMIN_EMAILS') ?? '';
    return raw
        .split(',')
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  static String get openAIAPIKey =>
      dotenv.dotenv.maybeGet('OPENAI_API_KEY') ??
      const String.fromEnvironment('OPENAI_API_KEY');
}
