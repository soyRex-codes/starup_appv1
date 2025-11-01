//Debug script to check conversation participants in the database
//Run with: dart test/debug_dm_participants.dart
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  await Supabase.initialize(
    url: 'https://oeuhiakmrdpwhnqgsqwd.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9ldWhpYWttcmRwd2hucWdzcXdkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzQzNDk0NzgsImV4cCI6MjA0OTkyNTQ3OH0.j_4NCmTGgXBQmVJF4m7pn4YXC4fHKs_Mm0kxJYX6mq4',
  );
  
  final client = Supabase.instance.client;
  final currentUser = client.auth.currentUser;
  
  if (currentUser == null) {
    print('❌ No user logged in');
    return;
  }
  
  print('✅ Current user: ${currentUser.id}');
  print('\n🔍 Checking conversations...\n');
  
  // Get conversations where user is a participant
  final participants = await client
      .from('conversation_participants')
      .select('conversation_id')
      .eq('user_id', currentUser.id)
      .isFilter('left_at', null);
  
  print('Found ${participants.length} conversations');
  
  for (final p in participants) {
    final convId = p['conversation_id'] as String;
    print('\n📧 Conversation: $convId');
    
    // Get all participants for this conversation
    final allParticipants = await client
        .from('conversation_participants')
        .select('user_id')
        .eq('conversation_id', convId)
        .isFilter('left_at', null);
    
    print('   Participants:');
    for (final participant in allParticipants) {
      final uid = participant['user_id'] as String;
      final isSelf = uid == currentUser.id;
      print('   - $uid ${isSelf ? "(YOU)" : ""}');
    }
    
    // Get participant count
    print('   Total: ${allParticipants.length} participants');
    
    if (allParticipants.length != 2) {
      print('   ⚠️  WARNING: Expected 2 participants for direct conversation!');
    }
  }
}
