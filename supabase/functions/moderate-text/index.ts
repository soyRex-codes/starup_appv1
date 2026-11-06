import { requireUser } from '../_shared/auth.ts';
import {
  createCorsHeaders,
  handleCorsPreflightRequest,
  validateOrigin,
} from '../_shared/cors.ts';

const MAX_CONTENT_LENGTH = 10_000;
const OPENAI_MODEL = 'gpt-4o-mini';

const systemPrompt = `You moderate a professional community where people find partners, solve problems, and build projects.
Block explicit sexual content, graphic violence, hate or severe harassment, threats, illegal sales, malicious spam, and targeted severe abuse.
Allow professional discussion, constructive disagreement, problem solving, collaboration requests, personal stories, and mild profanity in context.
Respond only as JSON: {"block":boolean,"severity":"none|low|medium|high","categories":string[],"explanation":string}.`;

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
  if (req.method !== 'POST') {
    return json({ error: 'Method not allowed' }, 405, headers);
  }

  const user = await requireUser(req);
  if (!user) return json({ error: 'Unauthorized' }, 401, headers);

  let body: { content?: unknown; contentType?: unknown };
  try {
    body = await req.json();
  } catch (_) {
    return json({ error: 'Invalid JSON body' }, 400, headers);
  }

  const content = typeof body.content === 'string' ? body.content.trim() : '';
  const contentType = typeof body.contentType === 'string'
    ? body.contentType.slice(0, 40)
    : 'content';

  if (!content) return json({ blocked: false, pending: false, reasons: [] }, 200, headers);
  if (content.length > MAX_CONTENT_LENGTH) {
    return json({ error: 'Content is too long' }, 413, headers);
  }

  const apiKey = Deno.env.get('OPENAI_API_KEY');
  if (!apiKey) return json({ error: 'Moderation service is not configured' }, 503, headers);

  try {
    const response = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: OPENAI_MODEL,
        messages: [
          { role: 'system', content: systemPrompt },
          { role: 'user', content: `${contentType}:\n${content}` },
        ],
        response_format: { type: 'json_object' },
        temperature: 0.2,
        max_tokens: 180,
      }),
    });

    if (!response.ok) {
      console.error('OpenAI moderation error', response.status);
      return json({ blocked: false, pending: true, reasons: ['moderation_unavailable'] }, 502, headers);
    }

    const payload = await response.json();
    const raw = payload?.choices?.[0]?.message?.content;
    if (typeof raw !== 'string') throw new Error('Missing model response');
    const decision = JSON.parse(raw);
    const blocked = decision.block === true;
    const reasons = Array.isArray(decision.categories)
      ? decision.categories.map(String).slice(0, 10)
      : [];

    return json({
      blocked,
      pending: false,
      reasons,
      severity: typeof decision.severity === 'string' ? decision.severity : 'none',
      explanation: blocked && typeof decision.explanation === 'string'
        ? decision.explanation.slice(0, 500)
        : null,
    }, 200, headers);
  } catch (error) {
    console.error('Text moderation failed', error);
    return json({ blocked: false, pending: true, reasons: ['moderation_unavailable'] }, 500, headers);
  }
});
