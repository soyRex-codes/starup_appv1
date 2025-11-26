import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import * as admin from "npm:firebase-admin@11.11.1";

// Initialize Firebase Admin
// The FIREBASE_SERVICE_ACCOUNT env var must be the JSON content of the service account key
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
  // 1. Parse the webhook payload
  const payload = await req.json();
  console.log("Webhook received:", JSON.stringify(payload));

  // Only handle INSERT events on 'notifications' table
  if (payload.type !== "INSERT" || payload.table !== "notifications") {
    return new Response("Ignored", { status: 200 });
  }

  const notification = payload.record;
  const userId = notification.user_id;

  // Ignore 'broadcast' type notifications as they are handled via FCM Topic
  if (notification.type === 'broadcast') {
    console.log("Skipping broadcast notification (handled via Topic)");
    return new Response("Skipped broadcast", { status: 200 });
  }

  if (!userId) {
    return new Response("No user_id", { status: 400 });
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
    console.error("Error fetching devices:", error);
    return new Response("Database error", { status: 500 });
  }

  if (!devices || devices.length === 0) {
    console.log(`No devices found for user ${userId}`);
    return new Response("No devices", { status: 200 });
  }

  const tokens = devices.map((d) => d.fcm_token);
  console.log(`Found ${tokens.length} tokens for user ${userId}`);

  // 4. Send Notification via Firebase
  if (admin.apps.length === 0) {
    return new Response("Firebase not initialized", { status: 500 });
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
    console.log("Successfully sent message:", response);

    // Optional: Remove invalid tokens
    if (response.failureCount > 0) {
      const failedTokens: string[] = [];
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          failedTokens.push(tokens[idx]);
        }
      });
      if (failedTokens.length > 0) {
        console.log("Removing invalid tokens:", failedTokens);
        await supabase
          .from("user_devices")
          .delete()
          .in("fcm_token", failedTokens);
      }
    }

    return new Response(JSON.stringify(response), {
      headers: { "Content-Type": "application/json" },
      status: 200,
    });
  } catch (error) {
    console.error("Error sending message:", error);
    return new Response("Error sending message", { status: 500 });
  }
});
