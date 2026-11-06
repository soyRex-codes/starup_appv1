import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import * as admin from "npm:firebase-admin@11.11.1";

const webhookSecret = Deno.env.get("PUSH_WEBHOOK_SECRET");
const textEncoder = new TextEncoder();

async function hasValidWebhookSecret(request: Request): Promise<boolean> {
  const suppliedSecret = request.headers.get("x-terai-webhook-secret");
  if (!webhookSecret || !suppliedSecret) return false;

  const [expectedHash, suppliedHash] = await Promise.all([
    crypto.subtle.digest("SHA-256", textEncoder.encode(webhookSecret)),
    crypto.subtle.digest("SHA-256", textEncoder.encode(suppliedSecret)),
  ]);
  const expected = new Uint8Array(expectedHash);
  const supplied = new Uint8Array(suppliedHash);
  let difference = 0;
  for (let index = 0; index < expected.length; index++) {
    difference |= expected[index] ^ supplied[index];
  }
  return difference === 0;
}

function json(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

// Initialize Firebase Admin
// The Firebase Admin credential remains in an Edge Function secret.
const serviceAccount = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");
if (serviceAccount) {
  try {
    const serviceAccountObj = JSON.parse(serviceAccount);
    if (admin.apps.length === 0) {
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccountObj),
      });
    }
  } catch (e) {
    console.error("Error parsing FIREBASE_SERVICE_ACCOUNT:", e);
  }
} else {
  console.error("Missing FIREBASE_SERVICE_ACCOUNT environment variable");
}

serve(async (req) => {
  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }
  if (!(await hasValidWebhookSecret(req))) {
    return json({ error: "Unauthorized" }, 401);
  }

  let payload: Record<string, any>;
  try {
    payload = await req.json();
  } catch (_) {
    return json({ error: "Invalid JSON" }, 400);
  }

  // Only handle INSERT events on 'notifications' table
  if (payload.type !== "INSERT" || payload.table !== "notifications") {
    return json({ ignored: true }, 200);
  }

  const notification = payload.record;
  if (!notification || typeof notification !== "object") {
    return json({ error: "Invalid notification payload" }, 400);
  }
  const userId = notification.user_id;

  // Ignore 'broadcast' type notifications as they are handled via FCM Topic
  if (notification.type === 'broadcast') {
    return json({ skipped: "broadcast" }, 200);
  }

  if (!userId) {
    return json({ error: "Missing user ID" }, 400);
  }

  // 2. Initialize Supabase Client
  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const supabase = createClient(supabaseUrl, supabaseKey);

  // 3. Fetch user's FCM tokens
  const { data: devices, error } = await supabase
    .from("user_devices")
    .select("fcm_token")
    .eq("user_id", userId);

  if (error) {
    console.error("Error fetching notification devices", error);
    return json({ error: "Database error" }, 500);
  }

  if (!devices || devices.length === 0) {
    return json({ sent: 0, reason: "No registered devices" }, 200);
  }

  const tokens = devices.map((d) => d.fcm_token);

  // 4. Send Notification via Firebase
  if (admin.apps.length === 0) {
    return json({ error: "Firebase not initialized" }, 500);
  }

  const message = {
    notification: {
      title: notification.title,
      body: notification.message,
    },
    data: {
      notification_id: notification.id,
      type: notification.type,
      related_post_id: notification.related_post_id?.toString() ?? "",
      related_user_id: notification.related_user_id ?? "",
      click_action: "FLUTTER_NOTIFICATION_CLICK",
    },
    tokens: tokens,
  };

  try {
    const response = await admin.messaging().sendMulticast(message);

    // Optional: Remove invalid tokens
    if (response.failureCount > 0) {
      const failedTokens: string[] = [];
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          failedTokens.push(tokens[idx]);
        }
      });
      if (failedTokens.length > 0) {
        await supabase
          .from("user_devices")
          .delete()
          .in("fcm_token", failedTokens);
      }
    }

    return json(
      { sent: response.successCount, failed: response.failureCount },
      200,
    );
  } catch (error) {
    console.error("Error sending push notification", error);
    return json({ error: "Notification delivery failed" }, 500);
  }
});
