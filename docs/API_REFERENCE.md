# API Reference

**Backend:** Supabase (PostgreSQL + Edge Functions)
**Auth:** Supabase Auth

## Authentication

| Method | Description |
|--------|-------------|
| `AuthService.signInWithEmailPassword` | Sign in with email/pass. Handles suspension checks. |
| `AuthService.signUp` | Register new user. Sends confirmation email. |
| `AuthService.signOut` | Clears local session and storage. |

## User Data (`users` table)

- **GET** `UserService.getById(id)`: Full profile (requires RLS for own data).
- **GET** `UserService.getPublicProfile(id)`: Limited public data (name, avatar, bio).
- **PUT** `UserService.upsertUser`: Update profile fields. **Note:** Only updates non-null fields (Patch semantics).

## Posts (`posts` table)

- **GET** `PostService.getPosts`: Paginated feed.
- **POST** `PostService.createPost`: content + optional media.
- **RLS**: Public read, Owner write.

## Messaging (`messages` table)

- **Realtime**: Subscribed via `channel('messages_convId')`.
- **Send**: `DMService.sendMessage`. Uses optimistic UI updates.

## Deep Links

- **Scheme**: `https://foundervers.com`
- **Routes**:
  - `/posts/:id` -> `SinglePostFeedPage`
  - `/profile/:id` -> `UnifiedProfilePage`
