# Content Moderation System

## Overview
Simple content moderation system using OpenAI's free Moderation API to check text and images across the app.

## Features
- **Text Moderation**: Blocks harmful text content in posts, messages, and chat
- **Image Moderation**: Checks uploaded images for inappropriate content
- **Real-time Checking**: Content is checked before being saved/sent
- **User-friendly Errors**: Clear feedback when content is blocked

## Integration Points

### 1. Post Creation (`post_creation_page.dart`)
- Checks title + description before creating post
- Checks uploaded images before saving to database
- Cleans up uploaded files if flagged

### 2. Direct Messages (`dm_service.dart`)  
- Checks message content before sending
- Throws exception if content violates guidelines

### 3. Global Chat (`global_chat_page.dart`)
- Checks message content before saving to database
- Shows user-friendly error message if blocked

## Configuration

### Environment Variable
Add to your `.env` file or environment:
```
OPENAI_API_KEY=your_openai_api_key_here
```

### Content Categories Blocked
- harassment, harassment/threatening
- hate, hate/threatening  
- violence, violence/graphic
- sexual, sexual/minors
- self-harm, self-harm/intent, self-harm/instructions
- illicit, illicit/violent (omni model only)

## Error Handling
- **API Failures**: Falls back to allowing content (no blocking)
- **Network Issues**: 10 second timeout, allows content on failure
- **No API Key**: Logs warning, allows all content

## Usage
The moderation is automatic - no additional code needed. Users will see error messages if their content is flagged:

- Posts: "Content violates community guidelines. Please revise and try again."
- Images: "Images violate community guidelines. Please choose different images."  
- Messages: "Message violates community guidelines"

## Performance
- Text-only: ~1-2 seconds
- Text + Images: ~2-3 seconds
- Free API with no usage limits