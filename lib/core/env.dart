class AppEnv {
  // Browser builds may expose every value below. Only public client
  // configuration belongs here; private provider keys live in Edge Functions.
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');
  static String get startupbuilderBucket => const String.fromEnvironment(
        'STARTUPBUILDER_BUCKET',
        defaultValue: 'startupbuilder',
      );
  static String get applicationsBucket => const String.fromEnvironment(
        'APPLICATIONS_BUCKET',
        defaultValue: 'applications',
      );
  // VAPID keys are public browser identifiers. A deploy environment may
  // override this value with FIREBASE_VAPID_KEY if the key is rotated.
  static const String firebaseVapidKey = String.fromEnvironment(
    'FIREBASE_VAPID_KEY',
    defaultValue:
        'BKoKaybx0WrhrP8vdPckZABV5qiAKNC8o3fsTSB3BTfb7dSa7jq_TAknKf-tDOiJAyLhU5Q5PQkxK7Ve8LBXQ2I',
  );
  static List<String> get adminEmails {
    const raw = String.fromEnvironment('ADMIN_EMAILS');
    return raw
        .split(',')
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toList();
  }
}
