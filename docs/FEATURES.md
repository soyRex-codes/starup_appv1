# Features Documentation

This document consolidates the technical implementation details for the core features of FounderVers Mobile.

## Table of Contents
1. [Feed System](#feed-system)
2. [Content Moderation](#content-moderation)
3. [Real-time Messaging](#real-time-messaging)
4. [Unified Profile](#unified-profile)
5. [Bookmark System](#bookmark-system)
6. [Stripe Payments](#stripe-payments)

---

## Feed System

The feed is the central hub for discovering posts.

### UI Enhancements
- **Timestamps**: Uses `TimeFormatter` to show relative time (e.g., "2h ago").
- **Card Design**: 
  - Dual shadow layers for depth
  - 12px border radius
  - Optimized spacing (12px bottom margin)
- **Onboarding**: 5-step overlay for first-time users (`FeedOnboardingOverlay`).

### Caching Strategy
- **Hit Rate**: ~70%
- **Architecture**: In-memory LRU cache + Supabase disk persistence
- **TTL**: Adaptive based on content type (1 min for search, 10 mins for categories)

---

## Content Moderation

A 3-layer hybrid moderation system ensures content safety while minimizing costs.

### Layer 1: Local Word Filter (Device-side)
- **Cost**: $0
- **Speed**: ~2ms
- **Effectiveness**: Blocks ~70% of violations immediately.
- **Mechanism**: Checks against local list of 200+ banned words/patterns.

### Layer 2: GPT-4o-mini (Server-side)
- **Cost**: Low (~$0.0009/check)
- **Speed**: ~200ms
- **Trigger**: Only if Layer 1 passes.
- **Function**: Context-aware text analysis (e.g., detects nuances like sarcasm or hate speech).

### Layer 3: Hive AI (Images)
- **Cost**: higher ($0.003/image)
- **Speed**: ~400ms
- **Trigger**: Only for images.
- **Capabilities**: NSFW detection, violence, gore.

---

## Real-time Messaging

Built on Supabase Realtime with PostgreSQL.

### Architecture
- **Protocol**: WebSockets via `supabase_flutter` channel
- **Tables**: `conversations`, `conversation_participants`, `messages`
- **Delivery**: Instant (<500ms) with Flutter `StreamBuilder`

### Key Features
- **Direct & Group Chats**: Unified schema supports both.
- **Optimistic Updates**: UI updates immediately before server confirmation.
- **Read Receipts**: Tracks `last_read_at` timestamp per participant.
- **Typing Indicators**: Ephemeral events (currently disabled for performance).

---

## Unified Profile

A single, smart `UnifiedProfilePage` handles both "My Profile" and "Public Profile" views.

### Logic
- **Own Profile**: 
  - Shows "Edit Profile" button
  - Displays private info (Email)
  - Tabs: "My Posts" + "Saved"
- **Other's Profile**:
  - Shows "Message" button
  - Hides private info
  - Tabs: "Posts" only

### Benefits
- Single source of truth (DRY)
- Consistent UI/UX
- Easy permissions management

---

## Bookmark System

Simple save/unsave functionality for posts.

### Implementation
- **Table**: `bookmarks` (user_id, post_id)
- **UI**: 
  - Feed: Green bookmark icon (outlined/filled)
  - Profile: Dedicated "Saved" tab
- **Performance**: 
  - Real-time sync via db triggers
  - Optimistic UI updates

---

## Stripe Payments

Integrated payment processing for the Ecosystem business portal.

### Flow
1. **Frontend**: User initiates payment for service ($20.00)
2. **Edge Function**: `create-payment-intent` generates Client Secret
3. **App**: Displays Native Payment Sheet (Apple Pay/Google Pay/Card)
4. **Stripe**: Processes transaction
5. **Webhook**: `stripe-webhook` updates `application_payments` table
6. **Trigger**: Database updates application status to 'paid'

### Configuration
- **Publishable Key**: In `.env.mobile` (safe for client)
- **Secret Key**: In Supabase Vault (never exposed)
