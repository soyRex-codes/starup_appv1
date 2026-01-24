import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:foundervers/services/supa.dart';
import 'package:foundervers/models/notification.dart';

/// Service for managing in-app notifications
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final SupabaseClient _s = Supa.client;

  // Real-time subscription
  RealtimeChannel? _notificationChannel;
  final _unreadCountController = StreamController<int>.broadcast();

  /// Stream of unread notification count
  Stream<int> get unreadCountStream => _unreadCountController.stream;

  /// Current unread count (cached)
  int _cachedUnreadCount = 0;
  int get unreadCount => _cachedUnreadCount;

  // Smart polling: adjust interval based on app lifecycle
  Timer? _pollingTimer;
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;
  static const _pollingIntervalFocused = Duration(seconds: 5);
  static const _pollingIntervalBackgrounded = Duration(seconds: 30);
  static const _pollingIntervalIdle = Duration(seconds: 60);

  // =============================================
  // NOTIFICATION CRUD
  // =============================================

  /// Create a new notification
  static Future<NotificationModel?> create({
    required String userId,
    required NotificationType type,
    required String title,
    required String message,
    int? relatedPostId,
    String? relatedCommentId,
    String? relatedUserId,
    String? relatedConversationId,
    String? actionUrl,
  }) async {
    try {
      final result = await Supa.client.rpc('create_notification', params: {
        'p_user_id': userId,
        'p_type': type.value,
        'p_title': title,
        'p_message': message,
        'p_related_post_id': relatedPostId,
        'p_related_comment_id': relatedCommentId,
        'p_related_user_id': relatedUserId,
        'p_related_conversation_id': relatedConversationId,
        'p_action_url': actionUrl,
      });

      if (result == null) return null;

      Map<String, dynamic>? json;

      if (result is List && result.isNotEmpty) {
        final first = result.first;
        if (first is Map<String, dynamic>) {
          json = first;
        } else if (first is Map) {
          json = Map<String, dynamic>.from(first);
        }
      } else if (result is Map<String, dynamic>) {
        json = result;
      } else if (result is Map) {
        json = Map<String, dynamic>.from(result);
      }

      if (json == null) return null;

      return NotificationModel.fromJson(json);
    } catch (e) {
      debugPrint('Error creating notification: $e');
      return null;
    }
  }

  /// Get all notifications for current user
  Future<List<NotificationModel>> getNotifications({
    int limit = 50,
    bool unreadOnly = false,
  }) async {
    try {
      final userId = _s.auth.currentUser?.id;
      if (userId == null) return [];

      var query = _s.from('notifications').select('''
            *,
            author:related_user_id(id, name, full_name, username, avatar_url)
          ''').eq('user_id', userId);

      if (unreadOnly) {
        query = query.eq('read', false);
      }

      final data =
          await query.order('created_at', ascending: false).limit(limit);

      return (data as List)
          .map((json) => NotificationModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      return [];
    }
  }

  /// Get unread notification count
  Future<int> getUnreadCount() async {
    try {
      final userId = _s.auth.currentUser?.id;
      if (userId == null) return 0;

      final count = await _s.rpc('get_unread_notification_count',
          params: {'target_user_id': userId});

      _cachedUnreadCount = count as int;
      _unreadCountController.add(_cachedUnreadCount);
      return _cachedUnreadCount;
    } catch (e) {
      debugPrint('Error getting unread count: $e');
      return 0;
    }
  }

  /// Mark a single notification as read
  Future<bool> markAsRead(String notificationId) async {
    try {
      await _s
          .from('notifications')
          .update({'read': true}).eq('id', notificationId);

      // Update cached count
      if (_cachedUnreadCount > 0) {
        _cachedUnreadCount--;
        _unreadCountController.add(_cachedUnreadCount);
      }

      return true;
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      return false;
    }
  }

  /// Mark all notifications as read
  Future<bool> markAllAsRead() async {
    try {
      final userId = _s.auth.currentUser?.id;
      if (userId == null) return false;

      await _s.rpc('mark_all_notifications_read',
          params: {'target_user_id': userId});

      _cachedUnreadCount = 0;
      _unreadCountController.add(0);

      return true;
    } catch (e) {
      debugPrint('Error marking all as read: $e');
      return false;
    }
  }

  /// Delete a notification
  Future<bool> deleteNotification(String notificationId) async {
    try {
      await _s.from('notifications').delete().eq('id', notificationId);
      return true;
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      return false;
    }
  }

  /// Clear all read notifications
  Future<bool> clearAllRead() async {
    try {
      final userId = _s.auth.currentUser?.id;
      if (userId == null) return false;

      await _s
          .from('notifications')
          .delete()
          .eq('user_id', userId)
          .eq('read', true);

      return true;
    } catch (e) {
      debugPrint('Error clearing read notifications: $e');
      return false;
    }
  }

  // =============================================
  // REAL-TIME SUBSCRIPTIONS (OPTIONAL ENHANCEMENT)
  // =============================================

  /// Start listening for new notifications [DEPRECATED: Use polling instead]
  ///
  /// REAL-TIME STATUS: INACTIVE (Table not in publications) + SCALABILITY DECISION
  /// The 'notifications' table is NOT enabled in Supabase real-time publications.
  /// Only these 3 tables are enabled: chat_messages, messages, oauth_authorizations
  ///
  /// **INTENTIONAL DESIGN DECISION**: We use POLLING instead of real-time subscriptions
  ///
  /// Why polling is better:
  /// 1. Doesn't use real-time connection slots (limited to 100 per plan)
  /// 2. Simple, reliable, works on spotty networks
  /// 3. Scales to 10,000+ MAU without subscription overhead
  /// 4. Notifications can wait 10-15 seconds (not critical path)
  ///
  /// Implementation:
  /// - UI calls getUnreadCount() periodically (10-15 second intervals)
  /// - UI calls getNotifications() when user opens notification panel
  /// - No connection slots used
  /// - Much better for scaling!
  ///
  /// This subscription will fail silently (table not published) but that's OK.
  /// App works great with polling approach.
  ///
  /// To restore real-time in future (if needed):
  /// 1. Ensure 'notifications' table is in real-time publications
  /// 2. Uncomment the .onPostgresChanges listeners below
  /// 3. But this is NOT recommended for scaling
  Future<void> startListening() async {
    final userId = _s.auth.currentUser?.id;
    if (userId == null) {
      debugPrint('No user logged in, cannot start notification listener');
      return;
    }

    // Unsubscribe if already subscribed
    await stopListening();

    // Initial unread count via polling
    await getUnreadCount();

    // OPTIONAL: Real-time subscription (disabled for scalability)
    // Uncomment if you want to restore real-time notifications:
    //
    // _notificationChannel = _s
    //     .channel('notifications_$userId')
    //     .onPostgresChanges(
    //       event: PostgresChangeEvent.insert,
    //       schema: 'public',
    //       table: 'notifications',
    //       filter: PostgresChangeFilter(
    //         type: PostgresChangeFilterType.eq,
    //         column: 'user_id',
    //         value: userId,
    //       ),
    //       callback: (payload) {
    //         debugPrint('New notification received');
    //         _handleNewNotification(payload.newRecord);
    //       },
    //     )
    //     .onPostgresChanges(
    //       event: PostgresChangeEvent.update,
    //       schema: 'public',
    //       table: 'notifications',
    //       filter: PostgresChangeFilter(
    //         type: PostgresChangeFilterType.eq,
    //         column: 'user_id',
    //         value: userId,
    //       ),
    //       callback: (payload) {
    //         debugPrint('Notification updated');
    //         _handleNotificationUpdate(payload.newRecord);
    //       },
    //     )
    //     .subscribe();

    debugPrint('Notification polling started for user: $userId');
  }

  /// Stop listening for notifications
  Future<void> stopListening() async {
    if (_notificationChannel != null) {
      await _notificationChannel!.unsubscribe();
      _notificationChannel = null;
      debugPrint('Notification listener stopped');
    }
  }

  /// Handle new notification from real-time subscription [DISABLED]
  // void _handleNewNotification(Map<String, dynamic> data) {
  //   try {
  //     final notification = NotificationModel.fromJson(data);
  //     if (!notification.read) {
  //       _cachedUnreadCount++;
  //       _unreadCountController.add(_cachedUnreadCount);
  //     }
  //   } catch (e) {
  //     debugPrint('Error handling new notification: $e');
  //   }
  // }

  /// Handle notification update from real-time subscription [DISABLED]
  // void _handleNotificationUpdate(Map<String, dynamic> data) {
  //   try {
  //     final notification = NotificationModel.fromJson(data);
  //     if (notification.read && _cachedUnreadCount > 0) {
  //       _cachedUnreadCount--;
  //       _unreadCountController.add(_cachedUnreadCount);
  //     }
  //   } catch (e) {
  //     debugPrint('Error handling notification update: $e');
  //   }
  // }

  /// Start smart polling with adaptive intervals
  void startSmartPolling() {
    _stopPolling();

    // Listen to app lifecycle changes
    WidgetsBinding.instance.addObserver(_AppLifecycleObserver(
      onStateChanged: (state) {
        _appLifecycleState = state;
        _adjustPollingInterval();
      },
    ));

    _startPolling();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(_getPollingInterval(), (_) {
      getUnreadCount();
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  void _adjustPollingInterval() {
    _stopPolling();
    _startPolling();
  }

  Duration _getPollingInterval() {
    switch (_appLifecycleState) {
      case AppLifecycleState.resumed:
        return _pollingIntervalFocused; // 5s when app is focused
      case AppLifecycleState.paused:
        return _pollingIntervalBackgrounded; // 30s when app backgrounded
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        return _pollingIntervalIdle; // 60s when app is hidden
      case AppLifecycleState.inactive:
        return _pollingIntervalBackgrounded;
    }
  }

  /// Dispose resources
  void dispose() {
    stopListening();
    _stopPolling();
    _unreadCountController.close();
  }

  // =============================================
  // HELPER METHODS FOR CREATING NOTIFICATIONS
  // =============================================

  /// Create a comment notification
  static Future<void> notifyComment({
    required String postOwnerId,
    required String commenterName,
    required int postId,
    required String postTitle,
    required String commenterId,
  }) async {
    // Don't notify yourself
    if (postOwnerId == commenterId) return;

    await create(
      userId: postOwnerId,
      type: NotificationType.comment,
      title: 'New comment on your post',
      message: '$commenterName commented on "$postTitle"',
      relatedPostId: postId,
      relatedUserId: commenterId,
      actionUrl: '/post/$postId',
    );
  }

  /// Create a reply notification
  static Future<void> notifyReply({
    required String originalCommenterId,
    required String replierName,
    required String commentId,
    required int postId,
    required String replierId,
  }) async {
    // Don't notify yourself
    if (originalCommenterId == replierId) return;

    await create(
      userId: originalCommenterId,
      type: NotificationType.reply,
      title: 'Someone replied to your comment',
      message: '$replierName replied to your comment',
      relatedCommentId: commentId,
      relatedPostId: postId,
      relatedUserId: replierId,
      actionUrl: '/post/$postId?comment=$commentId',
    );
  }

  /// Create a DM notification
  static Future<void> notifyDM({
    required String recipientId,
    required String senderName,
    required String conversationId,
    required String messagePreview,
    required String senderId,
  }) async {
    // Don't notify yourself
    if (recipientId == senderId) return;

    await create(
      userId: recipientId,
      type: NotificationType.dm,
      title: 'New message from $senderName',
      message: messagePreview.length > 100
          ? '${messagePreview.substring(0, 100)}...'
          : messagePreview,
      relatedConversationId: conversationId,
      relatedUserId: senderId,
      actionUrl: '/dm/$conversationId',
    );
  }

  /// Create a bookmark notification
  static Future<void> notifyBookmark({
    required String postOwnerId,
    required String bookmarkerName,
    required int postId,
    required String postTitle,
    required String bookmarkerId,
  }) async {
    // Don't notify yourself
    if (postOwnerId == bookmarkerId) return;

    await create(
      userId: postOwnerId,
      type: NotificationType.bookmark,
      title: 'Your post was bookmarked',
      message: '$bookmarkerName saved "$postTitle"',
      relatedPostId: postId,
      relatedUserId: bookmarkerId,
      actionUrl: '/post/$postId',
    );
  }

  /// Create a collaboration request notification
  static Future<void> notifyCollabRequest({
    required String recipientId,
    required String requesterName,
    required int postId,
    required String postTitle,
    required String requesterId,
  }) async {
    // Don't notify yourself
    if (recipientId == requesterId) return;

    await create(
      userId: recipientId,
      type: NotificationType.collabRequest,
      title: 'New collaboration request',
      message: '$requesterName wants to collaborate on "$postTitle"',
      relatedPostId: postId,
      relatedUserId: requesterId,
      actionUrl: '/post/$postId',
    );
  }
}

/// Observer for app lifecycle changes
class _AppLifecycleObserver extends WidgetsBindingObserver {
  final Function(AppLifecycleState) onStateChanged;

  _AppLifecycleObserver({required this.onStateChanged});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    onStateChanged(state);
  }
}
