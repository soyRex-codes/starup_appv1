import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> testDatabaseSchema() async {
  final client = Supabase.instance.client;

  if (kDebugMode) {
    print('🔍 Testing database schema...');
  }

  try {
    // Test if conversations table exists and has expected columns
    final conversations = await client
        .from('conversations')
        .select('id, type, created_at')
        .limit(1);
    if (kDebugMode) {
      print('✅ Conversations table exists and has type column');
    }
    if (kDebugMode) {
      print('   Sample data: $conversations');
    }
  } catch (e) {
    if (kDebugMode) {
      print('❌ Conversations table issue: $e');
    }
  }

  try {
    // Test insert
    await client.from('users').insert({
      'id': 'test-user-id',
      'email': 'test@example.com',
    });

    // Test select
    await client.from('users').select('id').limit(1);
    if (kDebugMode) {
      print('✅ Users table exists and allows insert/select');
    }
  } catch (e) {
    if (kDebugMode) {
      print('❌ Users table issue: $e');
    }
  }

  try {
    // Test if get_or_create_direct_conversation function exists
    // Test if get_or_create_direct_conversation function exists
    await client.rpc('get_or_create_direct_conversation', params: {
      'user1_id': '00000000-0000-0000-0000-000000000000',
      'user2_id': '00000000-0000-0000-0000-000000000001'
    });
    if (kDebugMode) {
      print('✅ get_or_create_direct_conversation function exists');
    }
  } catch (e) {
    if (kDebugMode) {
      print('❌ get_or_create_direct_conversation function issue: $e');
    }
  }
}

void main() async {
  // Initialize Supabase (you'll need to add your credentials)
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );

  await testDatabaseSchema();
}
