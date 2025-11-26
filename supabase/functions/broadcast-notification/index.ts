import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import admin from "npm:firebase-admin@11.11.1";

// Initialize Firebase Admin
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
}

serve(async (req) => {
    const logs: string[] = [];
    const log = (msg: any) => {
        console.log(msg);
        logs.push(JSON.stringify(msg));
    };
    const errorLog = (msg: any) => {
        console.error(msg);
        logs.push("ERROR: " + JSON.stringify(msg));
    };

    log("🚀 Function started");

    // CORS headers
    const corsHeaders = {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
    };

    if (req.method === "OPTIONS") {
        return new Response("ok", { headers: corsHeaders });
    }

    try {
        // 1. Verify User is Admin
        const supabaseClient = createClient(
            Deno.env.get("SUPABASE_URL") ?? "",
            Deno.env.get("SUPABASE_ANON_KEY") ?? "",
            {
                global: {
                    headers: { Authorization: req.headers.get("Authorization")! },
                },
            }
        );

        const {
            data: { user },
        } = await supabaseClient.auth.getUser();

        if (!user) {
            errorLog("No user found");
            return new Response(JSON.stringify({ error: "Unauthorized", logs }), { status: 401, headers: corsHeaders });
        }

        log(`User authenticated: ${user.id}`);

        // Check if user is admin in your 'profiles' or 'users' table
        // Adjust table name and column based on your schema
        const { data: profile } = await supabaseClient
            .from("users")
            .select("is_admin")
            .eq("id", user.id)
            .single();

        if (!profile?.is_admin) {
            errorLog("User is not admin");
            return new Response(JSON.stringify({ error: "Forbidden: Admins only", logs }), { status: 403, headers: corsHeaders });
        }

        log("User is admin");

        // 2. Parse Payload
        const { title, body, test_user_id } = await req.json();

        if (!title || !body) {
            errorLog("Missing title or body");
            return new Response(JSON.stringify({ error: "Missing title or body", logs }), { status: 400, headers: corsHeaders });
        }

        log("Initializing Firebase...");
        if (admin.apps.length === 0) {
            const serviceAccount = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");
            if (!serviceAccount) {
                throw new Error("Missing FIREBASE_SERVICE_ACCOUNT");
            }
            admin.initializeApp({
                credential: admin.credential.cert(JSON.parse(serviceAccount)),
            });
            log("Firebase initialized");
        }

        let response;

        if (test_user_id) {
            log(`🧪 Sending TEST to user: ${test_user_id}`);

            // Fetch tokens for this user
            const { data: devices, error: deviceError } = await supabaseClient
                .from("user_devices")
                .select("fcm_token")
                .eq("user_id", test_user_id);

            if (deviceError) {
                throw new Error("DB Error: " + deviceError.message);
            }

            if (!devices || devices.length === 0) {
                throw new Error("No devices found for this user. Please open the app to register a token.");
            }

            const tokens = devices.map(d => d.fcm_token).filter(t => t); // Filter nulls
            log(`Found ${tokens.length} tokens`);

            if (tokens.length === 0) {
                throw new Error("No valid tokens found");
            }

            const message = {
                notification: {
                    title: title,
                    body: body,
                },
                android: {
                    priority: "high",
                    notification: {
                        sound: "default",
                    },
                },
                apns: {
                    payload: {
                        aps: {
                            sound: "default",
                            contentAvailable: true,
                        },
                    },
                },
                tokens: tokens,
            };

            log("Sending multicast message...");
            const batchResponse = await admin.messaging().sendMulticast(message);
            log(`Success: ${batchResponse.successCount}, Failure: ${batchResponse.failureCount}`);

            if (batchResponse.failureCount > 0) {
                batchResponse.responses.forEach((resp, idx) => {
                    if (!resp.success) {
                        errorLog(`Token ${idx} failed: ${resp.error?.message}`);
                    }
                });
            }

            response = `Sent to ${batchResponse.successCount} devices`;

        } else {
            log(`📢 Sending BROADCAST: ${title}`);

            // 1. Save to Database (Persistence)
            log("Saving to database...");
            const { error: rpcError, data: count } = await supabaseClient.rpc('create_broadcast_notifications', {
                title: title,
                body: body
            });

            if (rpcError) {
                errorLog("Failed to save to DB: " + JSON.stringify(rpcError));
            } else {
                log(`Saved to DB for ${count} users`);
            }

            // 2. Send Push Notifications
            log("Sending push notifications...");

            // For iOS reliability, fetch tokens and send directly instead of using topics
            const { data: devices, error: devicesError } = await supabaseClient
                .from('user_devices')
                .select('fcm_token, platform');

            if (devicesError) {
                errorLog("Failed to fetch devices: " + JSON.stringify(devicesError));
            }

            const androidTokens = devices?.filter((d: any) => d.platform === 'android' && d.fcm_token)
                .map((d: any) => d.fcm_token) || [];
            const iosTokens = devices?.filter((d: any) => d.platform === 'ios' && d.fcm_token)
                .map((d: any) => d.fcm_token) || [];

            let androidSuccess = 0, iosSuccess = 0;

            // Send to Android via topic (works reliably)
            if (androidTokens.length > 0) {
                const androidMessage = {
                    topic: 'all_users',
                    notification: { title, body },
                    android: {
                        priority: 'high' as const,
                        notification: {
                            sound: 'default',
                            channelId: 'high_importance_channel',
                        },
                    },
                };

                try {
                    const androidResponse = await admin.messaging().send(androidMessage);
                    log(`✅ Android topic message sent: ${androidResponse}`);
                    androidSuccess = androidTokens.length; // Estimate
                } catch (androidError: any) {
                    errorLog("Android send failed: " + androidError.message);
                }
            }

            // Send to iOS devices directly (bypass topics)
            if (iosTokens.length > 0) {
                log(`Sending to ${iosTokens.length} iOS devices directly...`);

                const iosMessage = {
                    tokens: iosTokens,
                    notification: { title, body },
                    apns: {
                        payload: {
                            aps: {
                                alert: { title, body },
                                sound: 'default',
                                badge: 1,
                                'content-available': 1,
                            },
                        },
                    },
                };

                try {
                    const iosResponse = await admin.messaging().sendEachForMulticast(iosMessage);
                    iosSuccess = iosResponse.successCount;
                    log(`✅ iOS messages sent: ${iosSuccess}/${iosTokens.length} successful`);

                    if (iosResponse.failureCount > 0) {
                        errorLog(`iOS failures: ${iosResponse.failureCount}`);
                        iosResponse.responses.forEach((resp: any, idx: number) => {
                            if (!resp.success) {
                                errorLog(`Token ${idx}: ${resp.error?.message}`);
                            }
                        });
                    }
                } catch (iosError: any) {
                    errorLog("iOS send failed: " + iosError.message);
                }
            }

            response = `Sent to ${androidSuccess} Android + ${iosSuccess} iOS devices`;
        }

        return new Response(JSON.stringify({ success: true, messageId: response, logs }), {
            headers: { ...corsHeaders, "Content-Type": "application/json" },
            status: 200,
        });
    } catch (error) {
        errorLog(error);
        return new Response(JSON.stringify({ error: error.message, logs }), {
            headers: { ...corsHeaders, "Content-Type": "application/json" },
            status: 500,
        });
    }
});
