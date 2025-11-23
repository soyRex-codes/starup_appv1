import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:foundervers/features/feed/feed_service.dart';

class UserBlockingService {
  // Singleton instance
  static final UserBlockingService _instance = UserBlockingService._internal();
  factory UserBlockingService() => _instance;
  UserBlockingService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  
  // In-memory cache of blocked user IDs
  List<String>? _blockedUserIdsCache;
  DateTime? _lastFetchTime;
  static const Duration _cacheValidity = Duration(minutes: 5);

  // Stream controller for block/unblock events
  final _blockEventsController = StreamController<void>.broadcast();
  Stream<void> get onBlockStateChanged => _blockEventsController.stream;

  /// Block a user
  Future<void> blockUser(String userId) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    // Optimistic update
    if (_blockedUserIdsCache != null && !_blockedUserIdsCache!.contains(userId)) {
      _blockedUserIdsCache!.add(userId);
    }

    await _supabase.from('user_blocks').insert({
      'blocker_id': currentUser.id,
      'blocked_id': userId,
    });

    // Invalidate feed cache so posts from this user disappear
    FeedService().invalidateCache();
    
    // Notify listeners
    _blockEventsController.add(null);
  }

  /// Unblock a user
  Future<void> unblockUser(String userId) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    // Optimistic update
    if (_blockedUserIdsCache != null) {
      _blockedUserIdsCache!.remove(userId);
    }

    await _supabase
        .from('user_blocks')
        .delete()
        .match({'blocker_id': currentUser.id, 'blocked_id': userId});

    // Invalidate feed cache to potentially show posts again
    FeedService().invalidateCache();
    
    // Notify listeners
    _blockEventsController.add(null);
  }

  /// Get list of blocked user IDs (Cached)
  Future<List<String>> getBlockedUserIds({bool forceRefresh = false}) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return [];

    // Return cached if valid
    if (!forceRefresh && 
        _blockedUserIdsCache != null && 
        _lastFetchTime != null && 
        DateTime.now().difference(_lastFetchTime!) < _cacheValidity) {
       return _blockedUserIdsCache!;
    }
    
    // Re-implementing correct cache logic below in the full replacement
    return _fetchBlockedUserIds();
  }

  Future<List<String>> _fetchBlockedUserIds() async {
     final currentUser = _supabase.auth.currentUser;
     if (currentUser == null) return [];

    try {
      final response = await _supabase
          .from('user_blocks')
          .select('blocked_id')
          .eq('blocker_id', currentUser.id);

      _blockedUserIdsCache = (response as List)
          .map((e) => e['blocked_id'] as String)
          .toList();
      _lastFetchTime = DateTime.now();
      
      return _blockedUserIdsCache!;
    } catch (e) {
      return _blockedUserIdsCache ?? [];
    }
  }

  /// Check if a user is blocked
  Future<bool> isUserBlocked(String userId) async {
    final blockedIds = await getBlockedUserIds();
    return blockedIds.contains(userId);
  }

  /// Get detailed profiles of blocked users
  Future<List<Map<String, dynamic>>> getBlockedProfiles() async {
    final blockedIds = await getBlockedUserIds(forceRefresh: true);
    if (blockedIds.isEmpty) return [];

    try {
      // Format for PostgREST: (id1,id2,id3)
      final filterString = '(${blockedIds.map((id) => '"$id"').join(',')})';
      
      final response = await _supabase
          .from('users') 
          .select('id, name, username, avatar_url')
          .filter('id', 'in', filterString);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching blocked profiles: $e');
      return [];
    }
  }
}
