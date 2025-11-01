# Collapsible Search Header Implementation

## Overview
Redesigned app header with Twitter/X style collapsible search to improve mobile UX and reduce visual clutter.

## Design Pattern
**Twitter/X Collapsible Search**
- Default state: Compact with logo and icon buttons
- Search state: Full-width search input with back button
- Smooth 200ms transitions between states

## Implementation Details

### States

#### 1. Collapsed State (Default)
```
[Logo] [Search placeholder] [Filter] [Menu] [Bell]
```
- **Logo**: 40x40 FounderVers logo (left)
- **Search Placeholder**: Tappable fake search bar with hint text
- **Filter Icon**: With orange badge when filters active
- **Menu Icon**: Opens right-side drawer
- **Bell Icon**: Notification badge (red count)

#### 2. Expanded State (Search Mode)
```
[← Back] [━━━ Search Input ━━━] [✕ Clear]
```
- **Back Arrow**: Collapses search, clears text, dismisses keyboard
- **Search Input**: Full-width TextField with auto-focus
- **Clear Button**: Shows only when text entered

#### 3. Active Filters (Below Header)
```
[🔽 Filter: Tag Name ✕] [Clear All]
```
- **Filter Chips**: Horizontally scrollable
- **Close Button**: Remove individual filter
- **Clear All**: Remove all filters at once

### Key Features

✅ **Auto-Focus Keyboard**: Automatically shows keyboard when search expands
✅ **Auto-Collapse**: Collapses when focus lost and text empty
✅ **Smooth Animations**: 200ms AnimatedSwitcher for state transitions
✅ **Filter Badge**: Orange dot indicator when filters active (10x10 circle)
✅ **Active Filter Chips**: Visual feedback below header
✅ **Search Placeholder**: "Search startups, founders, ideas..."
✅ **Keyboard Dismissal**: Back button or collapse auto-dismisses keyboard

### User Flows

**Expanding Search:**
1. User taps search placeholder
2. Header animates to expanded state (200ms)
3. Keyboard auto-shows with focus
4. User types query
5. Clear button appears when text entered

**Collapsing Search:**
1. User taps back arrow
2. Text cleared if any
3. Keyboard dismissed
4. Header animates to collapsed state (200ms)
5. Logo and icons reappear

**Auto-Collapse:**
1. User taps outside search (loses focus)
2. If text is empty, header auto-collapses
3. If text exists, search stays expanded

### File Modified
`/lib/app/widgets/app_header.dart`

### Changes Made

1. **State Management**
   - Changed `_isSearchFocused` to `_isSearchExpanded`
   - Added `_expandSearch()` method
   - Added `_collapseSearch()` method
   - Auto-collapse logic on focus loss

2. **UI Structure**
   - Replaced single Row with AnimatedSwitcher
   - Created `_buildCollapsedHeader()` widget
   - Created `_buildExpandedHeader()` widget
   - Enhanced filter chips below header

3. **Collapsed Header**
   - Logo (40x40)
   - Fake search bar (tappable Container)
   - Filter icon with badge (10x10 orange dot)
   - Menu icon
   - Notification icon with red badge

4. **Expanded Header**
   - Back arrow IconButton
   - Full-width TextField (42px height)
   - Primary color border (0.3 alpha)
   - Clear button (conditional)
   - Larger touch targets

5. **Filter Chips**
   - SingleChildScrollView (horizontal)
   - Primary container background (0.7 alpha)
   - Filter icon + text + close button
   - Rounded corners (20px radius)

## Benefits

### Before (LinkedIn Style)
❌ Logo hides on small screens
❌ Search bar too small (cramped)
❌ All icons always visible (cluttered)
❌ Poor touch targets
❌ No visual hierarchy

### After (Twitter/X Style)
✅ Clean default state (logo always visible)
✅ Search gets full width when needed
✅ Larger touch targets (42px input height)
✅ Clear visual hierarchy
✅ Smooth, familiar UX pattern
✅ Better mobile experience
✅ Filter badge indicators
✅ Active filter visibility

## Technical Notes

- **AnimatedSwitcher**: Handles smooth transitions between collapsed/expanded
- **ValueKey**: Required for AnimatedSwitcher to detect widget changes
- **WidgetsBinding.addPostFrameCallback**: Ensures keyboard shows after widget build
- **FocusNode.unfocus()**: Programmatically dismisses keyboard
- **Stream**: Real-time notification badge updates

## Future Enhancements (Optional)

1. **Scope Toggle**: Add "Posts | Users | Tags" toggle in expanded search
2. **Recent Searches**: Show recent search history below input
3. **Search Suggestions**: Auto-complete dropdown
4. **Voice Search**: Microphone icon in expanded state
5. **Filter Count**: Show number of active filters (e.g., "3 filters")

## Testing Checklist

- [ ] Tap search → expands smoothly with keyboard
- [ ] Type text → clear button appears
- [ ] Tap clear → text clears
- [ ] Tap back → collapses, keyboard dismissed
- [ ] Tap outside search → auto-collapses if empty
- [ ] Filter badge shows when filters active
- [ ] Filter chips appear below header
- [ ] Notification badge updates in real-time
- [ ] Menu icon opens drawer
- [ ] All touch targets adequate size (44x44 min)

## Related Files

- `/lib/app/widgets/app_header.dart` - Header component
- `/lib/features/feed/feed_page.dart` - Uses AppHeader
- `/lib/app/widgets/app_menu_drawer.dart` - Right-side drawer
- `/lib/features/notifications/notifications.dart` - Notification page

## Design Reference

Inspired by Twitter/X mobile app header:
- Clean collapsed state with logo
- Dedicated search mode with full-width input
- Smooth expand/collapse transitions
- Back button to exit search
- Filter indicators

---

**Status**: ✅ Implemented
**Date**: January 2025
**Impact**: Significantly improved mobile UX and header usability
