import type { } from '../_shared/deno-runtime.d.ts';

export { };

// Import Stripe
import Stripe from 'npm:stripe@14.19.0';

const stripeSecretKey = Deno.env.get('stripe_secret_key');

if (!stripeSecretKey) {
  console.error('❌ CRITICAL: stripe_secret_key environment variable not set!');
  console.error('Check Supabase secrets configuration');
}

const stripe = new Stripe(stripeSecretKey, {
  apiVersion: '2023-10-16',
});

// CORS Configuration
const ALLOWED_ORIGINS = [
  'https://foundervers.com',
  'https://app.foundervers.com',
  'https://www.foundervers.com',
  'http://localhost:3000',
  'http://127.0.0.1:3000',
  'http://localhost:8080',
];

const DYNAMIC_ORIGIN_PATTERNS = [
  /^https:\/\/[a-zA-Z0-9-]+\.foundervers\.com$/,
  /^https:\/\/[a-zA-Z0-9-]+\.vercel\.app$/,
  /^https:\/\/[a-zA-Z0-9-]+\.netlify\.app$/,
  /^http:\/\/localhost:\d+$/,  // Flutter web dev server
  /^http:\/\/127\.0\.0\.1:\d+$/,  // Flutter web dev server (IP)
];

function validateOrigin(request: Request): string | null {
  const origin = request.headers.get('origin');
  if (!origin) return null;
  if (ALLOWED_ORIGINS.includes(origin)) return origin;
  for (const pattern of DYNAMIC_ORIGIN_PATTERNS) {
    if (pattern.test(origin)) return origin;
  }
  return null;
}

function createCorsHeaders(validatedOrigin: string | null): Record<string, string> {
  const headers: Record<string, string> = {
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Max-Age': '86400',
    'Vary': 'Origin',
    'Content-Type': 'application/json',
  };
  if (validatedOrigin) {
    headers['Access-Control-Allow-Origin'] = validatedOrigin;
    headers['Access-Control-Allow-Credentials'] = 'true';
  }
  return headers;
}

function handleCorsPreflightRequest(request: Request): Response | null {
  if (request.method !== 'OPTIONS') return null;
  const validatedOrigin = validateOrigin(request);
  if (!validatedOrigin && request.headers.get('origin')) {
    return new Response(null, {
      status: 403,
      statusText: 'Forbidden',
      headers: { 'Vary': 'Origin' },
    });
  }
  return new Response(null, {
    status: 204,
    headers: createCorsHeaders(validatedOrigin),
  });
}

interface PremiumSubscriptionRequest {
  amount: number;
  userId: string;
  email: string;
  subscriptionType: 'monthly' | 'annual';
}

interface PremiumSubscriptionResponse {
  clientSecret: string;
  paymentIntentId: string;
}

console.log('create-premium-subscription function loaded');

Deno.serve(async (req: Request) => {
  // Handle CORS preflight
  const preflightResponse = handleCorsPreflightRequest(req);
  if (preflightResponse) {
    return preflightResponse;
  }

  // Validate origin and create CORS headers
  const validatedOrigin = validateOrigin(req);
  const corsHeaders = createCorsHeaders(validatedOrigin);

  // Only allow POST requests
  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: corsHeaders,
    });
  }

  try {
    // Parse request body
    const body: PremiumSubscriptionRequest = await req.json();

    // Validate required fields
    if (!body.amount || !body.userId || !body.email || !body.subscriptionType) {
      return new Response(
        JSON.stringify({
          error: 'Missing required fields: amount, userId, email, subscriptionType',
        }),
        {
          status: 400,
          headers: corsHeaders,
        }
      );
    }

    // Validate subscription type
    if (!['monthly', 'annual'].includes(body.subscriptionType)) {
      return new Response(
        JSON.stringify({
          error: 'Invalid subscription type. Must be "monthly" or "annual"',
        }),
        {
          status: 400,
          headers: corsHeaders,
        }
      );
    }

    // Validate amount (must be >= $0.50 for Stripe)
    if (body.amount < 0.50) {
      return new Response(
        JSON.stringify({
          error: 'Amount must be at least $0.50',
        }),
        {
          status: 400,
          headers: corsHeaders,
        }
      );
    }

    // Create Stripe PaymentIntent
    const paymentIntent = await stripe.paymentIntents.create({
      amount: Math.round(body.amount * 100), // Convert to cents
      currency: 'usd',
      metadata: {
        userId: body.userId,
        subscriptionType: body.subscriptionType,
        productType: 'premium_subscription',
      },
      description: `FounderVers Premium Subscription - ${body.subscriptionType === 'monthly' ? 'Monthly' : 'Annual'}`,
      receipt_email: body.email,
      automatic_payment_methods: {
        enabled: true,
      },
    });

    // Verify PaymentIntent was created successfully
    if (!paymentIntent.client_secret) {
      throw new Error('Failed to create payment intent: no client secret');
    }

    console.log(`Premium Subscription PaymentIntent created: ${paymentIntent.id}`);
    console.log(`Subscription type: ${body.subscriptionType}, Amount: $${body.amount}`);

    // Return success response
    return new Response(
      JSON.stringify({
        success: true,
        clientSecret: paymentIntent.client_secret,
        paymentIntentId: paymentIntent.id,
      } as PremiumSubscriptionResponse),
      {
        status: 200,
        headers: corsHeaders,
      }
    );
  } catch (error) {
    console.error('❌ Error creating premium subscription payment intent:', error);
    console.error('Error details:', {
      name: error instanceof Error ? error.name : 'Unknown',
      message: error instanceof Error ? error.message : String(error),
      stack: error instanceof Error ? error.stack : undefined,
    });

    const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred';

    return new Response(
      JSON.stringify({
        success: false,
        error: 'Failed to create premium subscription payment intent',
        details: errorMessage,
      }),
      {
        status: 500,
        headers: corsHeaders,
      }
    );
  }
});
