import { requireUser } from '../_shared/auth.ts';
import {
  createCorsHeaders,
  handleCorsPreflightRequest,
  validateOrigin,
} from '../_shared/cors.ts';

const MAX_IMAGE_BYTES = 5 * 1024 * 1024;
const thresholds: Record<string, number> = {
  yes_sexual_activity: 0.85,
  yes_sexual_nudity: 0.85,
  animated_sexual_activity: 0.90,
  general_suggestive: 0.92,
  yes_blood: 0.80,
  yes_gore: 0.75,
  yes_violence: 0.85,
  yes_drugs: 0.88,
  yes_weapon: 0.90,
  yes_hate_symbols: 0.70,
};

function json(body: unknown, status: number, headers: HeadersInit) {
  return new Response(JSON.stringify(body), { status, headers });
}

Deno.serve(async (req: Request) => {
  const preflight = handleCorsPreflightRequest(req);
  if (preflight) return preflight;

  const origin = validateOrigin(req);
  const headers = createCorsHeaders(origin);
  if (req.headers.get('origin') && !origin) {
    return json({ error: 'Origin not allowed' }, 403, headers);
  }
  if (req.method !== 'POST') return json({ error: 'Method not allowed' }, 405, headers);

  const user = await requireUser(req);
  if (!user) return json({ error: 'Unauthorized' }, 401, headers);

  let body: { imageUrl?: unknown };
  try {
    body = await req.json();
  } catch (_) {
    return json({ error: 'Invalid JSON body' }, 400, headers);
  }

  if (typeof body.imageUrl !== 'string') {
    return json({ error: 'imageUrl is required' }, 400, headers);
  }

  let imageUrl: URL;
  let supabaseUrl: URL;
  try {
    imageUrl = new URL(body.imageUrl);
    supabaseUrl = new URL(Deno.env.get('SUPABASE_URL') ?? '');
  } catch (_) {
    return json({ error: 'Invalid image URL' }, 400, headers);
  }

  if (
    imageUrl.protocol !== 'https:' ||
    imageUrl.hostname !== supabaseUrl.hostname ||
    !imageUrl.pathname.startsWith('/storage/v1/object/')
  ) {
    return json({ error: 'Only project storage images are allowed' }, 400, headers);
  }

  const hiveKey = Deno.env.get('HIVE_AI_API_KEY');
  if (!hiveKey) return json({ error: 'Image moderation is not configured' }, 503, headers);

  try {
    const imageResponse = await fetch(imageUrl);
    if (!imageResponse.ok) return json({ error: 'Unable to download image' }, 422, headers);

    const declaredLength = Number(imageResponse.headers.get('content-length') ?? '0');
    if (declaredLength > MAX_IMAGE_BYTES) return json({ error: 'Image is too large' }, 413, headers);

    const imageBytes = new Uint8Array(await imageResponse.arrayBuffer());
    if (imageBytes.byteLength > MAX_IMAGE_BYTES) return json({ error: 'Image is too large' }, 413, headers);

    let binary = '';
    for (let offset = 0; offset < imageBytes.length; offset += 0x8000) {
      binary += String.fromCharCode(...imageBytes.subarray(offset, offset + 0x8000));
    }
    const encoded = btoa(binary);
    const mediaType = imageResponse.headers.get('content-type')?.split(';')[0] || 'image/jpeg';

    const hiveResponse = await fetch('https://api.thehive.ai/api/v3/sync/moderation', {
      method: 'POST',
      headers: {
        authorization: `token ${hiveKey}`,
        'Content-Type': 'application/json',
        accept: 'application/json',
      },
      body: JSON.stringify({ media: [{ data: encoded, media_type: mediaType }] }),
    });

    if (!hiveResponse.ok) {
      console.error('Hive moderation error', hiveResponse.status);
      return json({ blocked: false, pending: true, reasons: ['moderation_unavailable'] }, 502, headers);
    }

    const payload = await hiveResponse.json();
    const classes = payload?.media?.[0]?.classes;
    if (!classes || typeof classes !== 'object') throw new Error('Invalid Hive response');

    const scores: Record<string, number> = {};
    const reasons: string[] = [];
    for (const [name, value] of Object.entries(classes)) {
      if (typeof value !== 'number') continue;
      scores[name] = value;
      if (thresholds[name] !== undefined && value >= thresholds[name]) {
        reasons.push(`${name} (${(value * 100).toFixed(1)}%)`);
      }
    }

    return json({ blocked: reasons.length > 0, pending: false, reasons, scores }, 200, headers);
  } catch (error) {
    console.error('Image moderation failed', error);
    return json({ blocked: false, pending: true, reasons: ['moderation_unavailable'] }, 500, headers);
  }
});
