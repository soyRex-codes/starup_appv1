// Placeholder scaffold for Supabase Edge Function: send-dm-notification
// Purpose: Send FCM push on INSERT into public.personal_messages
// NOTE: Move this file into your supabase/functions/ folder when implementing.

// Pseudo-implementation (Node/Typescript)
// import { createClient } from 'https://esm.sh/@supabase/supabase-js';
// import fetch from 'node-fetch';

// export default async function handler(req: Request): Promise<Response> {
//   try {
//     const event = await req.json();
//     if (event.type !== 'INSERT' || event.table !== 'personal_messages') {
//       return new Response('ignored', { status: 200 });
//     }
//     const record = event.record;
//     const supabase = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);
//
//     // 1) Lookup recipient device tokens
//     const { data: devices, error } = await supabase
//       .from('user_devices')
//       .select('fcm_token')
//       .eq('user_id', record.recipient_id);
//     if (error) throw error;
//
//     // 2) Send notification to each token via FCM HTTP v1
//     for (const d of devices ?? []) {
//       try {
//         await sendFcm(d.fcm_token, {
//           title: record.subject ?? 'New message',
//           body: record.content?.slice(0, 120) ?? 'You have a new message',
//         });
//       } catch (e) {
//         // TODO: Optionally remove invalid tokens
//       }
//     }
//
//     return new Response('ok', { status: 200 });
//   } catch (e) {
//     console.error('send-dm-notification error', e);
//     return new Response('error', { status: 500 });
//   }
// }
//
// async function sendFcm(token: string, notification: { title: string; body: string }) {
//   // TODO: Implement using FCM HTTP v1 with a service account
//   // Docs: https://firebase.google.com/docs/cloud-messaging/send-message
// }
