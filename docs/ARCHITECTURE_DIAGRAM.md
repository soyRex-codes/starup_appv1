# Structured Comments - System Architecture Diagram

## User Flow

```
┌─────────────────────────────────────────────────────────────┐
│                         FEED PAGE                            │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              Enhanced Post Card                       │  │
│  │  ┌────────────────────────────────────────────────┐  │  │
│  │  │ [Post Title]                                    │  │  │
│  │  │ Post Description...                             │  │  │
│  │  │                                                  │  │  │
│  │  │ [Invest] [Collab] [Suggest]                     │  │  │
│  │  │ [Comment (5)] ← Purple button with badge        │  │  │
│  │  └────────────────────────────────────────────────┘  │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              ↓
                       [User taps Comment]
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                    COMMENT SHEET (85%)                       │
│ ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓ │
│ ┃  ═══ (Handle Bar)                                      ┃ │
│ ┃                                                         ┃ │
│ ┃  Comments (5)                                      [X]  ┃ │
│ ┃  ─────────────────────────────────────────────────────  ┃ │
│ ┃                                                         ┃ │
│ ┃  ┌─────────────────────────────────────────────────┐  ┃ │
│ ┃  │ User John Doe          2m ago                    │  ┃ │
│ ┃  │ [Idea/Suggestion]                               │  ┃ │
│ ┃  │ This is a great concept! Have you considered... │  ┃ │
│ ┃  │ [Reply]                                          │  ┃ │
│ ┃  │                                                   │  ┃ │
│ ┃  │   ⎿ User Jane Smith     1m ago                   │  ┃ │
│ ┃  │     Thanks for the feedback!                     │  ┃ │
│ ┃  │     [Reply]                                      │  ┃ │
│ ┃  └─────────────────────────────────────────────────┘  ┃ │
│ ┃                                                         ┃ │
│ ┃  ┌─────────────────────────────────────────────────┐  ┃ │
│ ┃  │ User Alice Johnson     5m ago                    │  ┃ │
│ ┃  │ [Question]                                       │  ┃ │
│ ┃  │ What's your go-to-market strategy?              │  ┃ │
│ ┃  │ [Reply]                                          │  ┃ │
│ ┃  └─────────────────────────────────────────────────┘  ┃ │
│ ┃                                                         ┃ │
│ ┃  ─────────────────────────────────────────────────────  ┃ │
│ ┃  [?][I][C][L][C] <- Category Selector                ┃ │
│ ┃  ┌─────────────────────────────────────────────────┐  ┃ │
│ ┃  │ Write a comment...                          [->]│  ┃ │
│ ┃  └─────────────────────────────────────────────────┘  ┃ │
│ ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛ │
└─────────────────────────────────────────────────────────────┘
```

---

## Component Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     FLUTTER APP LAYER                        │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                     UI COMPONENTS                            │
│                                                               │
│  CommentSheet (Modal)                                        │
│  ├── Header (Title + Count + Close)                         │
│  ├── CommentsList (Scrollable)                              │
│  │   └── CommentThread (foreach comment)                    │
│  │       ├── CommentCard (Parent)                           │
│  │       │   ├── Avatar                                     │
│  │       │   ├── Author Name + Time                         │
│  │       │   ├── Category Badge                             │
│  │       │   ├── Content                                    │
│  │       │   └── Actions (Reply, Delete)                    │
│  │       └── CommentCard (Replies, indented)               │
│  └── CommentInput (Fixed Bottom)                            │
│      ├── CategorySelector (Chips)                           │
│      ├── TextField (Multi-line)                             │
│      └── Submit Button                                      │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                     SERVICE LAYER                            │
│                                                               │
│  CommentService                                              │
│  ├── fetchComments(postId)                                  │
│  ├── addComment(postId, content, category)                  │
│  ├── addReply(parentId, content, postId)                    │
│  ├── deleteComment(commentId)                               │
│  ├── getCommentCount(postId)                                │
│  └── subscribeToComments(postId) → Stream                   │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                     SUPABASE CLIENT                          │
│                                                               │
│  ├── REST API (CRUD operations)                             │
│  ├── Realtime (WebSocket subscriptions)                     │
│  └── Auth (JWT validation)                                  │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                     POSTGRESQL DATABASE                      │
│                                                               │
│  comments TABLE                                              │
│  ├── id (UUID)                                              │
│  ├── post_id (FK → posts)                                   │
│  ├── author_id (FK → users)                                 │
│  ├── content (TEXT)                                         │
│  ├── category (ENUM)                                        │
│  ├── parent_comment_id (FK → comments)                      │
│  └── timestamps + metadata                                  │
│                                                               │
│  RLS POLICIES                                                │
│  ├── SELECT: Public (non-deleted)                           │
│  ├── INSERT: Authenticated                                  │
│  └── UPDATE/DELETE: Owner only                              │
│                                                               │
│  INDEXES                                                     │
│  ├── post_id + created_at                                   │
│  ├── author_id                                              │
│  └── parent_comment_id                                      │
└─────────────────────────────────────────────────────────────┘
```

---

## Data Flow

### Creating a Comment
```
User Input
    ↓
CommentInput validates (category + content)
    ↓
CommentService.addComment()
    ↓
Supabase Client POST /rest/v1/comments
    ↓
PostgreSQL INSERT with RLS check
    ↓
Realtime broadcasts to subscribers
    ↓
CommentSheet receives update via Stream
    ↓
UI auto-updates with new comment
```

### Real-Time Updates
```
User A adds comment
    ↓
Database INSERT triggers Realtime event
    ↓
Supabase broadcasts to WebSocket subscribers
    ↓
User B's CommentSheet Stream receives event
    ↓
_organizeThreads() rebuilds hierarchy
    ↓
UI rebuilds with new comment visible
    ↓
[All in <200ms]
```

---

## State Management

```
┌─────────────────────────────────────────────────────────────┐
│                   CommentSheet State                         │
│                                                               │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  _comments: List<CommentModel>                       │   │
│  │  _isLoading: bool                                    │   │
│  │  _error: String?                                     │   │
│  │  _replyingTo: CommentModel?                         │   │
│  └─────────────────────────────────────────────────────┘   │
│                          ↕                                   │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  State Updates:                                      │   │
│  │  • setState() on load                                │   │
│  │  • Stream.listen() for real-time                     │   │
│  │  • Dispose on sheet close                            │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

---

## Security Flow

```
┌─────────────────────────────────────────────────────────────┐
│                     CLIENT REQUEST                           │
│  POST /rest/v1/comments                                      │
│  Headers: Authorization: Bearer <JWT>                        │
│  Body: { content, category, post_id, author_id }            │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                     SUPABASE AUTH                            │
│  ✓ Validate JWT                                              │
│  ✓ Extract user_id                                           │
│  ✓ Set auth.uid()                                            │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                     RLS POLICY CHECK                         │
│  ✓ Check comments_insert policy                              │
│  ✓ Verify: auth.uid() = author_id                           │
│  ✓ Validate category enum                                    │
│  ✓ Check content length (1-2000)                             │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                     DATABASE INSERT                          │
│  ✓ Insert row                                                │
│  ✓ Trigger update_comment_timestamp()                       │
│  ✓ Return created comment                                    │
└─────────────────────────────────────────────────────────────┘
```

---

## Thread Organization Algorithm

```
Input: Flat list of comments
[
  {id: 1, parent: null},
  {id: 2, parent: 1},
  {id: 3, parent: null},
  {id: 4, parent: 2},
  {id: 5, parent: 1}
]
                ↓
        _organizeThreads()
                ↓
Output: Nested tree structure
[
  {
    id: 1,
    parent: null,
    replies: [
      {
        id: 2,
        parent: 1,
        replies: [
          {id: 4, parent: 2, replies: []}
        ]
      },
      {id: 5, parent: 1, replies: []}
    ]
  },
  {
    id: 3,
    parent: null,
    replies: []
  }
]
                ↓
        Rendered UI
Comment 1
  ⎿ Reply 2
    ⎿ Reply 4
  ⎿ Reply 5
Comment 3
```

---

## Visual Hierarchy

```
Post Card (Full Width)
├─ [Media Carousel]
├─ [Author Header]
├─ [Title]
├─ [Description]
├─ [Category + Goal Chips]
├─ Action Buttons
│  ├─ [Invest]
│  ├─ [Collab]
│  └─ [Suggest]
└─ Comment Button
   └─ [Comment (5)] ← Added by integration
                  ↓ Opens
            Comment Sheet
            ├─ Comments List
            │  └─ Threads
            │     ├─ Parent
            │     └─ Replies (indented)
            └─ Input Bar
               ├─ Categories
               └─ Text Field
```

---

## Performance Optimizations

```
┌─────────────────────────────────────────────────────────────┐
│                   OPTIMIZATION LAYER                         │
│                                                               │
│  1. Database Level                                           │
│     ├─ Indexed queries (post_id, author_id)                 │
│     ├─ RPC function for count (no SELECT COUNT)             │
│     └─ Filtered indexes (WHERE deleted_at IS NULL)          │
│                                                               │
│  2. Network Level                                            │
│     ├─ Single query with JOINs (no N+1)                     │
│     ├─ WebSocket for real-time (not polling)                │
│     └─ Efficient JSON serialization                         │
│                                                               │
│  3. App Level                                                │
│     ├─ Cached avatars (CachedNetworkImage)                  │
│     ├─ Lazy loading (only visible comments)                 │
│     ├─ Thread organization once per fetch                   │
│     └─ Dispose streams on close                             │
│                                                               │
│  4. UI Level                                                 │
│     ├─ ListView.builder (efficient scrolling)               │
│     ├─ const constructors where possible                    │
│     └─ Minimal rebuilds (targeted setState)                 │
└─────────────────────────────────────────────────────────────┘
```

---

## Responsive Design

```
Mobile (Default)
┌──────────────────┐
│  Comment Sheet   │
│  ═══ (handle)    │
│  Comments (5) [X]│
│  ────────────────│
│  [Comment 1]     │
│    ⎿ Reply 1A    │
│  [Comment 2]     │
│  ────────────────│
│  [? I C L C]     │
│  [Input...   ->] │
└──────────────────┘

Tablet/Desktop
┌───────────────────────────────┐
│      Comment Sheet            │
│      ═══ (handle)             │
│      Comments (5)        [X]  │
│      ───────────────────────  │
│  [Comment 1]                  │
│    ⎿ Reply 1A                 │
│  [Comment 2]                  │
│      ───────────────────────  │
│  [?][I][C][L][C]           │
│  [Input field...        [->]] │
└───────────────────────────────┘
```

---

This visual architecture helps understand how all components work together!
