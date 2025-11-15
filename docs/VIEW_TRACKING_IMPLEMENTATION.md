# View Tracking Implementation - Quick Reference

## Overview
Implemented scroll-based view tracking (Option C) for posts in the feed.

## How It Works
1. **Scroll Detection**: When user scrolls and post becomes 50%+ visible
2. **Instant UI Update**: View count increments immediately in the UI
3. **Batch Save**: Every 5 views, syncs to database (reduces DB calls)
4. **Display**: Shows "👁️ X" badge next to comment button

## Files Modified

### 1. `pubspec.yaml`
- Added `visibility_detector: ^0.4.0+2` package

### 2. `lib/models/post.dart`
- Added `views` field to PostModel
- Updated `fromJson()` to parse views from database
- Updated `copyWith()` to include views

### 3. `lib/features/feed/enhanced_post_card.dart`
- Wrapped post card with `VisibilityDetector`
- Added view tracking state: `_hasViewBeenCounted`, `_localViewCount`, `_pendingViewIncrements`
- Added methods:
  - `_handleVisibilityChanged()` - Detects when post is visible
  - `_incrementViewCount()` - Updates UI and tracks pending saves
  - `_saveViewsToDB()` - Batch saves every 5 views
- Added view counter UI badge next to comment button

### 4. `supabase/migrations/add_views_to_posts.sql`
- SQL migration to add `views INTEGER` column to posts table
- Includes index for performance

## Database Migration

Run this in Supabase SQL Editor:

\`\`\`sql
ALTER TABLE posts 
ADD COLUMN IF NOT EXISTS views INTEGER DEFAULT 0 NOT NULL;

CREATE INDEX IF NOT EXISTS idx_posts_views ON posts(views DESC);
\`\`\`

## Behavior

**When does view count?**
- Post becomes 50%+ visible in viewport (user scrolling through feed)
- Counted only once per post per app session

**When does it save to DB?**
- Every 5 views to reduce database calls
- Silent failure if DB save fails (views not critical)

**What users see:**
- View counter appears next to comment button
- Updates instantly as they scroll
- Shows 0 if no views yet (badge hidden)

## Testing

1. Open app and scroll through feed
2. Watch view counters increment as posts become visible
3. Check Supabase posts table - views column should update every 5 views

## Future Enhancements

- **Option D**: Add 2-second threshold (only count if user paused)
- **Option E**: Track unique users (prevent same user from inflating)
- **Analytics**: Track view-to-click ratio, view duration, etc.

## Performance

- **Lightweight**: Single visibility detector per post
- **Efficient**: Batches 5 views before DB call
- **Non-blocking**: UI updates instantly, DB saves async
- **Fail-safe**: Errors don't crash app, just logged
