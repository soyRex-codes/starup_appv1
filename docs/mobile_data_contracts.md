# Mobile Data Contracts (FounderVers Mobile)

Purpose
- Define the exact queries, payload shapes, pagination, and error modes for the mobile client using Supabase.
- Assume Supabase Auth for mobile; IDs in tables are stored as TEXT user_id matching auth.uid()::text (hybrid with existing Firebase UIDs for web).

Conventions
- All queries scoped with select(...).limit(n).order(...).range(...) to avoid heavy scans.
- All timestamps are ISO8601 strings in UTC from Supabase.
- Errors: surface message + code; BLoC converts to domain-friendly enums.

Fixed categories
- Allowed values (fixed set): ['funding','team','skills','hiring','partnership','mentorship','feedback','other']
- DB enforces with a CHECK constraint (see migrations/fixed_categories.sql; initially NOT VALID to allow cleanup).

Storage
- Bucket for post media: startupbuilder
- Upload flow: client uploads to this bucket, then inserts media rows referencing file_path.

Auth & User Profile
- On login success: get or upsert user profile.
  - Table: users
  - Key columns: firebase_uid (TEXT), name, email, avatar_url, created_at
  - Contract:
    - GET my profile
      - Query: supabase.from('users').select('firebase_uid,name,email,avatar_url,created_at').eq('firebase_uid', auth.uid()::text).single()
      - Response: { firebase_uid: string, name: string|null, email: string, avatar_url: string|null, created_at: string }
    - UPSERT on first login (if not found): set firebase_uid=auth.uid()::text, email, name if available

Feed (Posts)
- Table: posts; join media; join author (users)
- Default page: 20 items, newest first
- Filters: category (one of fixed categories)
- Contract:
  - GET page
    - Query (no filter):
      supabase
        .from('posts')
        .select('id,user_id,name,category,title,description,funding_goal,post_goal,post_goal_description,email,created_at,media:media(*),author:users!inner(firebase_uid,name,avatar_url)')
        .order('created_at', { ascending: false })
        .range(offset, offset+limit-1)
    - With category: add .eq('category', category)
    - Response item:
      {
        id: number,
        user_id: string,
        title: string,
        description: string|null,
        category: string|null,
        funding_goal: number|null,
        post_goal: string|null,
        post_goal_description: string|null,
        email: string|null,
        created_at: string,
        media: Array<{ id:number, post_id:number, type:string|null, filename:string|null, original_name:string|null, file_path:string|null, file_size:number|null, uploaded_at:string }>,
        author: { firebase_uid: string, name: string|null, avatar_url: string|null }
      }

Create Post
- Storage: upload files to bucket startupbuilder
- Insert post, then media rows.
- Contract:
  1) Upload each file -> get storage path/url (e.g., startupbuilder/{uid}/{uuid}.{ext})
  2) Insert post
     supabase.from('posts').insert({
       user_id: auth.uid()::text,
       name, category, title, description, funding_goal, post_goal, post_goal_description, email
     }).select('id').single()
  3) Insert media rows
     supabase.from('media').insert(mediaList.map(m => ({ post_id: postId, type: m.type, filename: m.filename, original_name: m.originalName, file_path: m.path, file_size: m.size })))

Global Chat
- Table: chat_messages; realtime stream
- Contract:
  - Subscribe:
    supabase.from('chat_messages').stream(primaryKey: ['id']).order('created_at', { ascending: false }).limit(50)
  - Send message:
    supabase.from('chat_messages').insert({ user_id: auth.uid()::text, user_name, content })
  - Message item: { id:number, user_id:string, user_name:string, content:string|null, file_url:string|null, file_name:string|null, file_type:string|null, created_at:string, edited:boolean, moderation_status:string }

Personal Messaging
- Table: personal_messages
- Inbox: group by other participant (client-side grouping)
- Contract:
  - Fetch my messages (paged newest first):
    supabase
      .from('personal_messages')
      .select('id,sender_id,recipient_id,sender_name,sender_email,recipient_email,subject,content,type,related_post_id,related_post_title,investment_amount,skills,read,created_at')
      .or(`sender_id.eq.${auth.uid()},recipient_id.eq.${auth.uid()}`)
      .order('created_at', { ascending: false })
      .range(offset, offset+limit-1)
  - Send message:
    supabase.from('personal_messages').insert({
      sender_id: auth.uid()::text,
      recipient_id,
      sender_name, sender_email,
      recipient_email,
      subject, content, type,
      related_post_id, related_post_title, investment_amount, skills
    })
  - Mark read:
    supabase.from('personal_messages').update({ read: true }).eq('id', messageId).or(`recipient_id.eq.${auth.uid()}`)

Notifications (FCM)
- Table: user_devices (id, user_id, fcm_token, platform, created_at)
- Contract:
  - Register/update token on app start and token refresh:
    - Upsert: delete existing rows with same token for safety; insert { user_id: auth.uid()::text, fcm_token, platform }
  - Edge Function send-dm-notification handles dispatch on personal_messages insert.

Moderation (server-side)
- Text: OpenAI moderation; Images: Google Cloud Vision SafeSearch.
- Client receives moderation_status only; no direct calls from client.

Moderation visibility (current phase: client-side)
- Posts/media: Client filters to show only approved + published; also show if owner (my Firebase UID) or admin email.
- Chat: Client filters to show only approved and non-deleted; also show if sender (my Firebase UID) or admin email.
- Future: RLS will enforce the same rules server-side.

Profile
- My posts:
  supabase.from('posts').select('id,title,category,created_at').eq('user_id', auth.uid()::text).order('created_at', { descending: true })

Pagination & limits
- Feed: limit 20; Chat stream: limit 50; Inbox: limit 50 per page; My posts: limit 20.

Error modes
- 401/permission_denied (RLS): show login or insufficient permission
- 413/too_large (media): advise compressing uploads
- 429/rate limited (edge): exponential backoff and user hint