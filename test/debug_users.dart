import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  await Supabase.initialize(
    url: 'https://oeuhiakmrdpwhnqgsqwd.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9ldWhpYWttcmRwd2hucWdzcXdkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzQzNDk0NzgsImV4cCI6MjA0OTkyNTQ3OH0.j_4NCmTGgXBQmVJF4m7pn4YXC4fHKs_Mm0kxJYX6mq4',
  );

  final supabase = Supabase.instance.client;

  if (kDebugMode) {
    print('🔍 Checking users table...');
  }

  try {
    // Get all users to see the data structure
    final response = await supabase
        .from('users')
        .select('id, username, full_name, email')
        .limit(5);

    if (kDebugMode) {
      print('📊 Users data:');
    }
    for (var user in response) {
      if (kDebugMode) {
        print('  ID: ${user['id']}');
      }
      if (kDebugMode) {
        print('  Username: ${user['username']}');
      }
      if (kDebugMode) {
        print('  Full Name: ${user['full_name']}');
      }
      if (kDebugMode) {
        print('  Email: ${user['email']}');
      }
      if (kDebugMode) {
        print('  ---');
      }
    }

    // Check conversations and participants
    if (kDebugMode) {
      print('🔍 Checking conversations...');
    }
    final convResponse = await supabase.from('conversations').select('''
          id,
          participants:conversation_participants(
            user_id,
            user_profile:users(id, username, full_name, avatar_url)
          )
        ''').limit(3);

    if (kDebugMode) {
      print('📊 Conversations data:');
    }
    for (var conv in convResponse) {
      if (kDebugMode) {
        print('  Conversation ID: ${conv['id']}');
      }
      if (kDebugMode) {
        print('  Participants:');
      }
      for (var participant in (conv['participants'] as List)) {
        final profile = participant['user_profile'];
        if (kDebugMode) {
          print('    User ID: ${participant['user_id']}');
        }
        if (kDebugMode) {
          print('    Username: ${profile?['username']}');
        }
        if (kDebugMode) {
          print('    Full Name: ${profile?['full_name']}');
        }
        if (kDebugMode) {
          print('    Profile: $profile');
        }
        if (kDebugMode) {
          print('    ----');
        }
      }
      if (kDebugMode) {
        print('  ---');
      }
    }
  } catch (e) {
    if (kDebugMode) {
      print('❌ Error: $e');
    }
  }
}
