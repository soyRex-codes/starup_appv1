# 🔄 Profile Unification Guide

## Overview
Merged `ProfilePage` and `PublicProfilePage` into **one smart `UnifiedProfilePage`** that intelligently adapts based on viewer permissions.

## ✅ Benefits

### Before (Problems)
- ❌ Two separate files: `profile_page.dart` + `public_profile_page.dart`
- ❌ Duplicate code for UI rendering
- ❌ ProfilePage showed minimal info (just UID, post count)
- ❌ PublicProfilePage had rich UI but couldn't edit
- ❌ Confusing which page to use
- ❌ Maintenance nightmare (update both files)
- ❌ Inconsistent UX

### After (Solution)
- ✅ **One file**: `unified_profile_page.dart`
- ✅ Smart permission system
- ✅ Rich UI for everyone
- ✅ Automatic feature toggling
- ✅ Single source of truth
- ✅ Easy maintenance
- ✅ Consistent UX

---

## 🎯 Features

### Smart Profile Detection
```dart
// Pass userId = null for current user (own profile)
UnifiedProfilePage()

// Pass userId to view someone else's profile
UnifiedProfilePage(userId: 'user-123', userName: 'John Doe')
```

### Permission-Based UI

| Feature | Own Profile | Others' Profile |
|---------|-------------|-----------------|
| **Email Address** | ✅ Shown | ❌ Hidden (privacy) |
| **Edit Button** | ✅ Shown (top + bottom) | ❌ Hidden |
| **Message Button** | ❌ Hidden (can't message self) | ✅ Shown |
| **Full Profile Data** | ✅ All fields | ✅ Public fields only |
| **Posts** | ✅ All posts | ✅ Public posts |

### Key Code Logic
```dart
bool get _isOwnProfile {
  final currentUserId = _supabase.auth.currentUser?.id;
  final targetId = _targetUserId;
  return currentUserId != null && targetId != null && currentUserId == targetId;
}

// Smart data fetching
if (_isOwnProfile) {
  return await userService.getById(_targetUserId!); // Full data
} else {
  return await userService.getPublicProfile(_targetUserId!); // Public only
}

// Smart button display
_isOwnProfile
  ? ElevatedButton.icon(label: 'Edit Profile')
  : OutlinedButton.icon(label: 'Message')
```

---

## 📋 Migration Steps

### Step 1: Update Navigation Points

#### A. Post Cards (Avatar/Name Taps)
**File**: `lib/features/feed/enhanced_post_card.dart`

```dart
// BEFORE
import 'package:foundervers/features/profile/public_profile_page.dart';

Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => PublicProfilePage(
      userId: widget.post.author!.userId,
      userName: displayName,
    ),
  ),
);

// AFTER
import 'package:foundervers/features/profile/unified_profile_page.dart';

Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => UnifiedProfilePage(
      userId: widget.post.author!.userId,
      userName: displayName,
    ),
  ),
);
```

#### B. Comment Cards
**File**: `lib/widgets/comments/comment_card.dart`

```dart
// BEFORE
import 'package:foundervers/features/profile/public_profile_page.dart';

Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => PublicProfilePage(
      userId: widget.comment.authorId,
      userName: widget.comment.authorName ?? 'User',
    ),
  ),
);

// AFTER
import 'package:foundervers/features/profile/unified_profile_page.dart';

Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => UnifiedProfilePage(
      userId: widget.comment.authorId,
      userName: widget.comment.authorName ?? 'User',
    ),
  ),
);
```

#### C. Global Chat
**File**: `lib/features/Global_public_chat-for_founders/global_chat_page.dart`

```dart
// BEFORE
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => PublicProfilePage(
      userId: msg['user_id'],
      userName: msg['user_name'] ?? 'User',
    ),
  ),
);

// AFTER
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => UnifiedProfilePage(
      userId: msg['user_id'],
      userName: msg['user_name'] ?? 'User',
    ),
  ),
);
```

#### D. DM Thread View
**File**: `lib/features/dm/thread_view.dart`

```dart
// BEFORE
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => PublicProfilePage(
      userId: otherUserId,
      userName: otherUserName,
    ),
  ),
);

// AFTER
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => UnifiedProfilePage(
      userId: otherUserId,
      userName: otherUserName,
    ),
  ),
);
```

#### E. Inbox Page
**File**: `lib/features/dm/new_inbox_page.dart`

```dart
// BEFORE (2 places)
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => PublicProfilePage(
      userId: participantId,
      userName: participantName,
    ),
  ),
);

// AFTER
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => UnifiedProfilePage(
      userId: participantId,
      userName: participantName,
    ),
  ),
);
```

#### F. App Header Menu (Own Profile)
**File**: `lib/app/widgets/app_header.dart`

```dart
// BEFORE
import 'package:foundervers/features/profile/profile_page.dart';

Navigator.of(ctx).push(
  MaterialPageRoute(
    builder: (_) => const ProfilePage()
  )
);

// AFTER
import 'package:foundervers/features/profile/unified_profile_page.dart';

Navigator.of(ctx).push(
  MaterialPageRoute(
    builder: (_) => const UnifiedProfilePage() // No userId = own profile
  )
);
```

### Step 2: Optional - Delete Old Files (After Testing)

Once you've verified everything works:

```bash
# Delete old profile pages
rm lib/features/profile/profile_page.dart
rm lib/features/profile/public_profile_page.dart
```

**⚠️ IMPORTANT**: Keep `edit_profile_page.dart` - it's still used for editing!

---

## 🧪 Testing Checklist

### Test Own Profile
- [ ] Open app menu → Tap "Profile"
- [ ] Should show "My Profile" in app bar
- [ ] Email should be visible
- [ ] Edit icon should appear in top right
- [ ] "Edit Profile" button should show at bottom
- [ ] Tap Edit → Should open EditProfilePage
- [ ] Make changes → Save → Profile should refresh
- [ ] Posts section should show "My Posts"

### Test Other's Profile
- [ ] Tap any user's avatar/name in feed
- [ ] Should show their username in app bar
- [ ] Email should NOT be visible
- [ ] Edit icon should NOT appear
- [ ] "Message" button should show at bottom
- [ ] Tap Message → Should open DM thread
- [ ] Posts section should show "Posts"
- [ ] Verified badge should show if they're verified

### Test Navigation
- [ ] Feed → Avatar tap → Profile opens
- [ ] Comments → Avatar tap → Profile opens
- [ ] Global Chat → Avatar tap → Profile opens
- [ ] DM Thread → Header avatar → Profile opens
- [ ] Inbox → Thread item avatar → Profile opens
- [ ] Menu → Profile → Own profile opens

### Test Edge Cases
- [ ] View own profile → Can't send message to self
- [ ] View suspended user → Profile still loads (admin can review)
- [ ] No posts → Should show "No posts yet" message
- [ ] Loading state → Shows spinner
- [ ] Error state → Shows error message
- [ ] Profile without avatar → Shows default icon
- [ ] Long bio → Wraps correctly
- [ ] No company/location → Fields hidden

---

## 🔧 Technical Details

### Constructor Flexibility
```dart
// Own profile
const UnifiedProfilePage()

// With user ID
const UnifiedProfilePage(userId: 'user-123')

// With user ID + display name (better UX)
const UnifiedProfilePage(
  userId: 'user-123', 
  userName: 'John Doe'
)
```

### Data Privacy
```dart
// Own profile: Full access via getById()
final profile = await userService.getById(userId);
// Returns: id, email, name, username, bio, company, location, avatar_url, email_verified, created_at

// Others' profile: Limited access via getPublicProfile()
final profile = await userService.getPublicProfile(userId);
// Returns: id, name, username, bio, company, location, avatar_url, email_verified, created_at
// ❌ NO EMAIL - Privacy protected
```

### Performance
- ✅ Single profile fetch (not two separate calls)
- ✅ Efficient FutureBuilder with refresh key
- ✅ Posts loaded separately (doesn't block profile render)
- ✅ ListView.builder for large post lists
- ✅ Image lazy loading via NetworkImage

---

## 📊 Code Comparison

### Lines of Code
| File | Before | After | Reduction |
|------|--------|-------|-----------|
| profile_page.dart | 120 lines | 0 | -120 |
| public_profile_page.dart | 450 lines | 0 | -450 |
| unified_profile_page.dart | 0 | 580 lines | +580 |
| **TOTAL** | **570 lines** | **580 lines** | **+10 lines** |

**Net Result**: +10 lines but **-1 file** and **massively improved maintainability**

### Maintenance Benefits
- 1 file to update vs 2
- Consistent UI automatically
- Single source of truth for profile logic
- Easier to add new features (add once, works everywhere)

---

## 🚀 Quick Start Commands

### Apply All Changes (Automated Script)

Create this script to update all imports automatically:

```bash
#!/bin/bash
# File: scripts/migrate_to_unified_profile.sh

echo "🔄 Migrating to UnifiedProfilePage..."

# Find and replace imports
find lib -name "*.dart" -type f -exec sed -i '' \
  's|import.*profile/public_profile_page.dart.*|import '\''package:foundervers/features/profile/unified_profile_page.dart'\'';|g' {} \;

find lib -name "*.dart" -type f -exec sed -i '' \
  's|import.*profile/profile_page.dart.*|import '\''package:foundervers/features/profile/unified_profile_page.dart'\'';|g' {} \;

# Replace widget constructors
find lib -name "*.dart" -type f -exec sed -i '' \
  's|PublicProfilePage(|UnifiedProfilePage(|g' {} \;

find lib -name "*.dart" -type f -exec sed -i '' \
  's|const ProfilePage()|const UnifiedProfilePage()|g' {} \;

echo "✅ Migration complete!"
echo "⚠️  Please review changes and test thoroughly before committing."
```

Make executable and run:
```bash
chmod +x scripts/migrate_to_unified_profile.sh
./scripts/migrate_to_unified_profile.sh
```

### Manual Migration
If you prefer manual updates, follow Step 1 above for each file.

---

## 🐛 Troubleshooting

### Error: "No Material widget found"
**Cause**: NavigationBar needs MaterialApp ancestor  
**Solution**: Already handled - uses proper Navigator.push with MaterialPageRoute

### Error: "userId is null"
**Cause**: Trying to view profile without user ID  
**Solution**: Code checks for null and shows "Please log in" message

### Profile doesn't refresh after edit
**Cause**: Missing refresh key increment  
**Solution**: Already implemented - setState(() => _refreshKey++)

### Can see others' emails
**Cause**: Using getById() instead of getPublicProfile()  
**Solution**: Code checks _isOwnProfile and calls appropriate method

### "Message" button appears on own profile
**Cause**: Permission check not working  
**Solution**: Check _isOwnProfile getter - compares currentUser.id with widget.userId

---

## 📝 Next Steps

1. **Run the migration script** OR manually update all 8 navigation points
2. **Hot restart** (not hot reload) to load new UnifiedProfilePage
3. **Test thoroughly** using checklist above
4. **Delete old files** after confirming everything works
5. **Commit changes** with message: "Merge profile pages into UnifiedProfilePage"

---

## 💡 Future Enhancements

Once unified profile is stable, consider adding:

- [ ] **Follow/Unfollow button** (permission: only on others' profiles)
- [ ] **Block user button** (permission: only on others' profiles)  
- [ ] **Report user button** (permission: only on others' profiles)
- [ ] **Share profile button** (permission: all profiles)
- [ ] **Profile stats** (followers, following, total likes)
- [ ] **Activity feed** (recent comments, likes)
- [ ] **Cover photo** (similar to avatar implementation)
- [ ] **Pinned posts** (permission: only on own profile to pin)
- [ ] **Profile badges** (early adopter, verified email, etc.)
- [ ] **Social links** (Twitter, LinkedIn, GitHub)

All these features become **much easier** to implement with unified page!

---

## 🎉 Summary

**One profile page to rule them all!**

- Smart permission system
- Better UX consistency
- Easier maintenance
- Privacy-aware data fetching
- Clean, modern architecture

The UnifiedProfilePage provides the same rich experience whether viewing your own profile or someone else's, with automatic permission-based feature toggling. No more duplicate code, no more confusion about which page to use!
