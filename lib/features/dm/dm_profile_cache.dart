import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:foundervers/services/supa.dart';
import 'dart:collection';

/// Lightweight in-memory profile cache for DM participants.
import 'package:flutter/foundation.dart';

class ProfileModel {
  final String userId;
  final String? name;
  final String? avatarUrl;
  ProfileModel({required this.userId, this.name, this.avatarUrl});
}

/// Fetches name & avatar_url from `users` table by user ID.
class DMProfileCache {
  DMProfileCache._();
  static final DMProfileCache _i = DMProfileCache._();
  static DMProfileCache get instance => _i;

  final SupabaseClient _client = Supabase.instance.client;
  final Map<String, ProfileModel?> _cache = {};

  Future<ProfileModel?> getProfile(String userId) async {
    if (_cache.containsKey(userId)) return _cache[userId];

    try {
      final rows = await _client
          .from('users')
          .select('id,name,username,full_name,avatar_url')
          .eq('id', userId)
          .limit(1);
      final list = (rows as List).cast<Map<String, dynamic>>();

      if (list.isNotEmpty) {
        final m = list.first;
        final profile = ProfileModel(
          userId: m['id']?.toString() ?? userId,
          name: m['name']?.toString() ??
              m['username']?.toString() ??
              m['full_name']?.toString(),
          avatarUrl: m['avatar_url']?.toString(),
        );
        _cache[userId] = profile;
        return profile;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[DMProfileCache] getProfile($userId) failed: $e');
      }
    }

    _cache[userId] = null;
    return null;
  }

  Future<Map<String, ProfileModel?>> getProfiles(List<String> userIds) async {
    final Map<String, ProfileModel?> result = {};
    final List<String> toFetch = [];

    // Check cache first
    for (final userId in userIds) {
      if (_cache.containsKey(userId)) {
        result[userId] = _cache[userId];
      } else {
        toFetch.add(userId);
      }
    }

    // Fetch uncached profiles
    if (toFetch.isNotEmpty) {
      try {
        final rows = await _client
            .from('users')
            .select('id,name,username,full_name,avatar_url')
            .inFilter('id', toFetch);
        final list = (rows as List).cast<Map<String, dynamic>>();

        for (final m in list) {
          final userId = m['id']?.toString();
          if (userId != null) {
            final profile = ProfileModel(
              userId: userId,
              name: m['name']?.toString() ??
                  m['username']?.toString() ??
                  m['full_name']?.toString(),
              avatarUrl: m['avatar_url']?.toString(),
            );
            _cache[userId] = profile;
            result[userId] = profile;
          }
        }

        // Mark missing profiles as null
        for (final userId in toFetch) {
          if (!result.containsKey(userId)) {
            _cache[userId] = null;
            result[userId] = null;
          }
        }
      } catch (e) {
        if (kDebugMode) debugPrint('[DMProfileCache] getProfiles failed: $e');
        // Mark all as null on error
        for (final userId in toFetch) {
          _cache[userId] = null;
          result[userId] = null;
        }
      }
    }

    return result;
  }

  void clearCache() => _cache.clear();
}

class DmProfileCache {
  DmProfileCache._();
  static final DmProfileCache instance = DmProfileCache._();

  final SupabaseClient _s = Supa.client;
  final Map<String, DmUserProfile?> _cache = HashMap();
  final Map<String, Future<DmUserProfile?>> _inFlight = {};

  DmUserProfile? get(String uid) => _cache[uid];

  Future<DmUserProfile?> fetch(String uid) {
    if (_cache.containsKey(uid)) return Future.value(_cache[uid]);
    final inflight = _inFlight[uid];
    if (inflight != null) return inflight;
    final f = _load(uid);
    _inFlight[uid] = f;
    return f.whenComplete(() => _inFlight.remove(uid));
  }

  Future<DmUserProfile?> _load(String uid) async {
    try {
      if (kDebugMode) {
        debugPrint('[DmProfileCache] Loading profile for uid: $uid');
      }
      final rows = await _s
          .from('users')
          .select('id,name,full_name,username,avatar_url')
          .eq('id', uid)
          .limit(1);
      if (rows.isNotEmpty) {
        final m = rows.first;
        if (kDebugMode) debugPrint('[DmProfileCache] Found user data: $m');
        final p = DmUserProfile(
          firebaseUid: m['id']?.toString() ?? uid,
          name: m['full_name']?.toString() ??
              m['name']?.toString() ??
              m['username']?.toString(),
          avatarUrl: m['avatar_url']?.toString(),
        );
        if (kDebugMode) {
          debugPrint('[DmProfileCache] Created profile: ${p.name} for $uid');
        }
        _cache[uid] = p;
        return p;
      }
      if (kDebugMode) {
        debugPrint('[DmProfileCache] No user found for uid: $uid');
      }
      _cache[uid] = null; // negative cache
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[DmProfileCache] Error loading profile for $uid: $e');
      }
      return null; // silent failure
    }
  }

  /// Preload a set of user ids (batched with IN query).
  Future<void> preload(Iterable<String> uids) async {
    final missing = uids.where((u) => !_cache.containsKey(u)).toList();
    if (missing.isEmpty) return;
    try {
      if (missing.length == 1) {
        await fetch(missing.first);
        return;
      }
      final rows = await _s
          .from('users')
          .select('id,name,full_name,username,avatar_url')
          .inFilter('id', missing);
      for (final r in rows) {
        final m = r;
        final uid = m['id']?.toString();
        if (uid == null) continue;
        _cache[uid] = DmUserProfile(
          firebaseUid: uid,
          name: m['full_name']?.toString() ??
              m['name']?.toString() ??
              m['username']?.toString(),
          avatarUrl: m['avatar_url']?.toString(),
        );
      }
      for (final u in missing) {
        _cache.putIfAbsent(u, () => null);
      }
    } catch (_) {}
  }
}

class DmUserProfile {
  final String firebaseUid;
  final String? name;
  final String? avatarUrl;
  const DmUserProfile({required this.firebaseUid, this.name, this.avatarUrl});
}

/// Utility to get current user id quickly
String? currentUid() => Supabase.instance.client.auth.currentUser?.id;
