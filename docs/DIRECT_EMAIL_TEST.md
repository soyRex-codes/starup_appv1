# Direct Email Test (Bypass Edge Functions)

Since the Edge Function approach hasn't worked after 100+ tests, let's try the simplest possible approach:

## Option 1: Use Supabase's Built-in Email (For Testing Only)

Instead of Resend, use Supabase's auth email system temporarily:

```sql
-- Replace the send_applicant_confirmation_email function with this simpler version
CREATE OR REPLACE FUNCTION send_applicant_confirmation_email()
RETURNS TRIGGER
LANGUAGE plpgsql 
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  -- Just log that we received the application
  RAISE NOTICE '=== APPLICATION RECEIVED ===';
  RAISE NOTICE 'ID: %', NEW.id;
  RAISE NOTICE 'Name: %', NEW.applicant_name;
  RAISE NOTICE 'Email: %', NEW.applicant_email;
  RAISE NOTICE 'Service: %', NEW.service_type;
  RAISE NOTICE '============================';
  
  -- For now, just return - no email sending
  RETURN NEW;
END;
$$;
```

## Option 2: Call Resend API Directly from Flutter

Skip the database trigger entirely. Send email directly from your Flutter app after the application is submitted:

### 1. Create a new Edge Function (simpler version):

**supabase/functions/send-email-simple/index.ts**
```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

serve(async (req) => {
  try {
    const { to, subject, html } = await req.json()
    
    const resendApiKey = Deno.env.get('RESEND_API_KEY')
    
    const res = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${resendApiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        from: 'FounderVers <foundervers@gmail.com>',
        to: [to],
        subject: subject,
        html: html,
      }),
    })
    
    const data = await res.json()
    
    return new Response(JSON.stringify(data), {
      headers: { 'Content-Type': 'application/json' },
      status: res.status,
    })
    
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    })
  }
})
```

### 2. Call it from Flutter after submitting the application:

```dart
// In your application submission code, after the application is created:
Future<void> sendConfirmationEmail(String applicantEmail, String applicantName) async {
  final supabase = Supabase.instance.client;
  
  try {
    final response = await supabase.functions.invoke(
      'send-email-simple',
      body: {
        'to': applicantEmail,
        'subject': 'Application Received - FounderVers',
        'html': '''
          <h1>Hi $applicantName!</h1>
          <p>We received your application and will get back to you soon.</p>
        ''',
      },
    );
    
    print('Email sent: ${response.data}');
  } catch (e) {
    print('Email error: $e');
  }
}
```

## Option 3: Manual Test via cURL

Test if Resend is working at all:

```bash
curl -X POST 'https://api.resend.com/emails' \
  -H 'Authorization: Bearer YOUR_RESEND_API_KEY' \
  -H 'Content-Type: application/json' \
  -d '{
    "from": "FounderVers <foundervers@gmail.com>",
    "to": ["rajkushwaha0213@gmail.com"],
    "subject": "Test Email",
    "html": "<p>This is a test</p>"
  }'
```

## Which approach should we try?

1. **Simplest**: Option 1 - Just log the application and verify the trigger fires
2. **Most reliable**: Option 2 - Call from Flutter app directly 
3. **Diagnostic**: Option 3 - Test Resend API manually first

Let me know which you want to try, or we can do all three in sequence.
