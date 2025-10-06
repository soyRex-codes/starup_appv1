import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  await Supabase.initialize(
    url: 'https://oeuhiakmrdpwhnqgsqwd.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9ldWhpYWttcmRwd2hucWdzcXdkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzQzNDk0NzgsImV4cCI6MjA0OTkyNTQ3OH0.j_4NCmTGgXBQmVJF4m7pn4YXC4fHKs_Mm0kxJYX6mq4',
  );

  final supabase = Supabase.instance.client;

  print('🔍 Checking users table...');

  try {
    // Get all users to see the data structure
    final response = await supabase
        .from('users')
        .select('id, username, full_name, email')
        .limit(5);

    print('📊 Users data:');
    for (var user in response) {
      print('  ID: ${user['id']}');
      print('  Username: ${user['username']}');
      print('  Full Name: ${user['full_name']}');
      print('  Email: ${user['email']}');
      print('  ---');
    }

    // Check conversations and participants
    print('🔍 Checking conversations...');
    final convResponse = await supabase.from('conversations').select('''
          id,
          participants:conversation_participants(
            user_id,
            user_profile:users(id, username, full_name, avatar_url)
          )
        ''').limit(3);

    print('📊 Conversations data:');
    for (var conv in convResponse) {
      print('  Conversation ID: ${conv['id']}');
      print('  Participants:');
      for (var participant in (conv['participants'] as List)) {
        final profile = participant['user_profile'];
        print('    User ID: ${participant['user_id']}');
        print('    Username: ${profile?['username']}');
        print('    Full Name: ${profile?['full_name']}');
        print('    Profile: $profile');
        print('    ----');
      }
      print('  ---');
    }
  } catch (e) {
    print('❌ Error: $e');
  }
}
