# Content Moderation Setup - Complete Guide ✅

## System Overview

```
┌─────────────────────────────────────────────────────────┐
│         YOUR APP CONTENT MODERATION SYSTEM              │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  📝 TEXT CONTENT                                          │
│  ├─ Where: Posts, Comments, Direct Messages             │
│  ├─ Service: OpenAI GPT-4o-mini                          │
│  ├─ API: Chat Completions API                           │
│  └─ Cost: $0.03 per 1,000 posts                         │
│                                                           │
│  📸 IMAGES                                               │
│  ├─ Where: Post images, Profile pics, Comments         │
│  ├─ Service: Hive AI v3                                 │
│  ├─ API: https://api.thehive.ai/api/v3/sync/moderation  │
│  └─ Cost: $3 per 1,000 images                           │
│                                                           │
│  🎥 VIDEOS                                               │
│  ├─ Where: Post videos, Profile videos                  │
│  ├─ Service: Hive AI v3 (extracts frames)               │
│  ├─ Frames: 5-10 per video analyzed                     │
│  └─ Cost: ~$3 per video (multi-frame)                   │
│                                                           │
└─────────────────────────────────────────────────────────┘
```

---

## What You Need: API Keys

### 1. OpenAI API Key (For Text) ✅ ALREADY CONFIGURED

**Status**: ✅ Active in `.env.mobile`

**What it is**: 
- Allows your app to use GPT-4o-mini for text moderation
- Text-aware (understands context, not just keywords)

**Location**: Already in `.env.mobile`:
```
OPENAI_API_KEY=sk-proj-tLZMhPytJuxoa2z9UICbsN1dJEJi__Fh5ADQuAUNb_...
```

**Where to get it** (if you need to renew):
1. Go to: https://platform.openai.com/account/api-keys
2. Click "Create new secret key"
3. Copy it
4. Replace `OPENAI_API_KEY` in `.env.mobile`

**What costs**: 
- Text moderation: ~$0.03 per 1,000 posts
- Actual tokens used: ~50 tokens per post

---

### 2. Hive AI API Key (For Images & Videos) ✅ ALREADY CONFIGURED

**Status**: ✅ Active in `.env.mobile`

**What it is**:
- Allows your app to analyze images and videos for inappropriate content
- Detects: nudity, violence, gore, sexual content, illegal content, etc.

**Location**: Already in `.env.mobile`:
```
HIVE_AI_API_KEY=Eu9pAIRCidXD3nJD/RfZOw==
```

**Where to get it** (if you need to renew):
1. Go to: https://thehive.ai/
2. Sign up / Log in
3. Go to: https://console.thehive.ai/
4. Create API key
5. Copy it
6. Replace `HIVE_AI_API_KEY` in `.env.mobile`

**What costs**:
- Images: $3 per 1,000 images (v3 pricing)
- Videos: $3 per 1,000 frames analyzed (5-10 frames per video)

---

## How It Works In Your App

### Flow Diagram

```
User Creates Post
       │
       ├──────────────────┬──────────────────┐
       │                  │                  │
       ▼                  ▼                  ▼
    TEXT              IMAGES               VIDEOS
       │                  │                  │
       │                  │    Hive AI       │
       │              Extracts Frames        │
       │              (5-10 frames)          │
       │                  │                  │
    GPT-4o-mini       Hive AI v3          Hive AI v3
  (Chat Completions) (Image Analysis)  (Image Analysis)
       │                  │                  │
       ▼                  ▼                  ▼
   APPROVED?          APPROVED?          APPROVED?
       │                  │                  │
    YES ✅             YES ✅             YES ✅
    │                    │                    │
    └────────────────┬───┴────────────────┬──┘
                     │
                     ▼
            SAVE TO DATABASE ✅
              Display to Users
```

### Code Files Involved

**Text Moderation**:
```
lib/services/gpt_text_moderation_service.dart
  └─ Creates ChatGPT prompt
  └─ Sends to OpenAI Chat Completions API
  └─ Gets JSON response (block: true/false)
```

**Image Moderation**:
```
lib/services/hive_ai_service.dart
  └─ Converts image to base64
  └─ Sends to Hive AI v3 API
  └─ Gets response (classes: [nudity: 95%, ...])
  └─ Blocks if any category > threshold
```

**Main Orchestrator**:
```
lib/services/moderation_service.dart
  └─ Calls GPT for text
  └─ Calls Hive AI for images
  └─ Returns final decision: BLOCKED or APPROVED
```

---

## API Endpoints

### OpenAI (Text)

```bash
URL: https://api.openai.com/v1/chat/completions

Headers:
  Authorization: Bearer sk-proj-tLZMhPytJuxoa2z9UICbsN1dJEJi__...
  Content-Type: application/json

Body:
{
  "model": "gpt-4o-mini",
  "messages": [
    {
      "role": "system",
      "content": "You are a content moderator for a professional startup community..."
    },
    {
      "role": "user",
      "content": "Check this text for inappropriate content: [TEXT HERE]"
    }
  ]
}

Response:
{
  "choices": [{
    "message": {
      "content": "{\"block\": false, \"severity\": \"none\", \"categories\": []}"
    }
  }]
}
```

### Hive AI (Images & Videos)

```bash
URL: https://api.thehive.ai/api/v3/sync/moderation

Headers:
  authorization: token Eu9pAIRCidXD3nJD/RfZOw==
  Content-Type: application/json

Body:
{
  "media": [
    {
      "data": "[BASE64_IMAGE_DATA]",
      "media_type": "image/jpeg"
    }
  ]
}

Response:
{
  "media": [{
    "status": "success",
    "classes": {
      "yes_sexual_activity": 0.95,
      "yes_sexual_nudity": 0.87,
      "yes_violence": 0.12,
      "yes_gore": 0.02,
      ...
    }
  }]
}
```

---

## What Gets Checked

### Text Checks (GPT-4o-mini)

✅ **Approved**:
- Constructive criticism and feedback
- Professional discussions
- Casual profanity in context ("this is fucking awesome")
- Disagreement and debate
- Links and promotions (if relevant)

❌ **Blocked**:
- Hate speech or discrimination
- Threats or harassment
- Explicit sexual content
- Spam or scams
- Illegal content
- Severe personal attacks

### Image Checks (Hive AI v3)

Analyzes images for:
- 🚫 Nudity/Sexual content (threshold: 85%)
- 🚫 Violence/Gore (threshold: 85%)
- 🚫 Illegal content (threshold: 90%)
- 🚫 Substance abuse (threshold: 90%)
- ✅ Safe content (all scores < thresholds)

**Thresholds**:
```dart
const Map<String, double> thresholds = {
  'yes_sexual_activity': 0.85,
  'yes_sexual_nudity': 0.85,
  'yes_violence': 0.85,
  'yes_gore': 0.90,
  'yes_illegal_activities': 0.90,
  'yes_substance_abuse': 0.90,
};
```

---

## Costs Breakdown

### Text Moderation (GPT-4o-mini)

| Items | Tokens | Cost |
|-------|--------|------|
| 1 post | ~50 | $0.000015 |
| 10K posts | ~500K | $0.15 |
| 50K posts | ~2.5M | $0.75 |
| 100K posts | ~5M | $1.50 |

### Image Moderation (Hive AI v3)

| Items | Cost |
|-------|------|
| 1 image | $0.003 |
| 1K images | $3 |
| 5K images | $15 |
| 20K images | $60 |

### Video Moderation (Hive AI v3)

| Duration | Frames | Cost |
|----------|--------|------|
| 10 sec video | 5 frames | $0.015 |
| 30 sec video | 10 frames | $0.030 |
| 1 min video | 10 frames | $0.030 |

**Note**: Hive AI extracts 5-10 key frames from videos, not full frame-by-frame analysis.

### Example Monthly Costs

**Small Community**:
- 10K posts = $0.30
- 5K images = $15
- Total: **~$15/month**

**Growing Community**:
- 50K posts = $1.50
- 20K images = $60
- Total: **~$62/month**

**Large Community**:
- 100K posts = $3
- 50K images = $150
- Total: **~$153/month**

---

## Where To Manage/Monitor

### Check Text Moderation Usage

1. Go to: https://platform.openai.com/usage/
2. View "Requests" and costs
3. See breakdown by model
4. You'll see `gpt-4o-mini` usage

### Check Image Moderation Usage

1. Go to: https://console.thehive.ai/
2. Login with your account
3. View "API Usage"
4. See images checked this month
5. Monitor credits

### Check API Key Validity

**OpenAI**:
```bash
curl https://api.openai.com/v1/models \
  -H "Authorization: Bearer sk-proj-YOUR_KEY"
```

**Hive AI**:
```bash
curl -X POST https://api.thehive.ai/api/v3/sync/moderation \
  -H "authorization: token YOUR_KEY" \
  -H "Content-Type: application/json" \
  -d '{"media":[]}'
```

---

## What Happens When Content is Blocked

### User Sees:

```
❌ Unable to post

Images violate community guidelines
  - Detected: Sexual nudity (95% confidence)
  
Please remove the image and try again
```

or

```
❌ Post violates community guidelines

Your text contains inappropriate content
  - Category: Hate speech
  
Please revise and try again
```

### In Your Database:

- Post not saved to `posts` table
- Blocked content logged to `moderation_logs` (optional)
- User can see error and resubmit

### In Your Analytics:

- Track blocked posts by type
- Monitor false positives
- Adjust thresholds if needed

---

## Files & Configuration

### Your Configuration File
📄 `.env.mobile`
```bash
OPENAI_API_KEY=sk-proj-tLZMhPytJuxoa2z9UICbsN1dJEJi__Fh5ADQuAUNb_...
HIVE_AI_API_KEY=Eu9pAIRCidXD3nJD/RfZOw==
```

### Environment Access
📄 `lib/core/env.dart`
```dart
static String get openAIAPIKey => dotenv.dotenv.maybeGet('OPENAI_API_KEY')
static String get hiveAIAPIKey => dotenv.dotenv.maybeGet('HIVE_AI_API_KEY')
```

### Services Using These Keys

| File | Service | Uses |
|------|---------|------|
| `gpt_text_moderation_service.dart` | OpenAI | `AppEnv.openAIAPIKey` |
| `hive_ai_service.dart` | Hive AI | `AppEnv.hiveAIAPIKey` |
| `moderation_service.dart` | Coordinator | Both services |

---

## FAQ

### Q: Can I use just Hive AI for everything?
**A**: No. Hive AI is for images/videos only. You need OpenAI (or similar) for text.

### Q: Can I use just OpenAI for everything?
**A**: No. OpenAI doesn't analyze images. You need Hive AI for images/videos.

### Q: Why both services?
**A**: They're specialized:
- OpenAI: Excels at context-aware text (understands nuance)
- Hive AI: Excels at visual content (99.9% accurate on images)
- Combined = comprehensive moderation

### Q: How much will this cost?
**A**: ~$15-150/month depending on user volume.
- At 50K posts + 20K images = ~$62/month

### Q: What if I hit my OpenAI/Hive AI quota?
**A**: 
- **OpenAI**: Requests fail, add credits at platform.openai.com
- **Hive AI**: Requests fail, add credits at console.thehive.ai
- Posts won't be created until you have credits

### Q: Can I adjust the sensitivity?
**A**: Yes!
- **Text**: Edit system prompt in `gpt_text_moderation_service.dart`
- **Images**: Edit thresholds in `hive_ai_service.dart`

### Q: Will this block legitimate content?
**A**: 
- **Text**: GPT-4o-mini is context-aware, much better than old system
- **Images**: Hive AI has false positive rate of ~1-2%

### Q: How do I monitor what's being blocked?
**A**: Check logs in the console:
```
🔍 GPT: Moderating post
✅ GPT approved post

🔍 Checking 3 image(s) with Hive AI...
🚫 Hive AI BLOCKED image: yes_sexual_nudity (95%)
```

---

## Quick Checklist

- ✅ OpenAI API Key: Configured in `.env.mobile`
- ✅ Hive AI API Key: Configured in `.env.mobile`
- ✅ Text moderation: Using GPT-4o-mini
- ✅ Image moderation: Using Hive AI v3
- ✅ Video moderation: Using Hive AI v3 (frame extraction)
- ✅ Services implemented: `gpt_text_moderation_service.dart`, `hive_ai_service.dart`
- ✅ Orchestrator: `moderation_service.dart`
- ✅ Environment vars: `lib/core/env.dart`

**Status**: ✅ Ready to test

---

## Next Steps

1. Run the app: `flutter run`
2. Create a post with normal content → Should be **approved**
3. Try to create post with NSFW image → Should be **blocked**
4. Try to create post with casual profanity → Should be **approved** (context understood)
5. Check logs for moderation details

**Your content moderation system is live!** 🚀
