import type { } from '../_shared/deno-runtime.d.ts';

export { };

// Import Stripe (will be installed via deno.json)
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

interface PaymentIntentRequest {
  amount: number;
  applicationId: string;
  userId: string;
  email: string;
  applicant_name: string;
  couponCode?: string;
}

interface PaymentIntentResponse {
  clientSecret: string;
  paymentIntentId: string;
}

console.log('create-payment-intent function loaded');

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
    const body: PaymentIntentRequest = await req.json();

    // Validate required fields
    if (!body.amount || !body.applicationId || !body.userId || !body.email) {
      return new Response(
        JSON.stringify({
          error: 'Missing required fields: amount, applicationId, userId, email',
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

    let finalAmount = body.amount;
    let couponId = null;

    // Apply Coupon if provided
    if (body.couponCode) {
      try {
        console.log(`🎟️ Validating coupon: ${body.couponCode}`);

        // List coupons to find by code (Stripe "coupons" are IDs, "promotion codes" are customer facing)
        // We assume the user enters a Promotion Code or a Coupon ID. 
        // For simplicity, we'll try to retrieve it as a Coupon ID first, 
        // if that fails, we might need a more complex lookup, but usually Coupon ID = Code for simple setups.
        // Actually, standard Stripe practice: Promotion Codes map to Coupons.
        // Let's try to retrieve the coupon directly assuming Code = ID for now, or list promotion codes.

        // Better approach: List promotion codes that match the code
        const promotionCodes = await stripe.promotionCodes.list({
          code: body.couponCode,
          active: true,
          limit: 1,
        });

        let coupon = null;

        if (promotionCodes.data.length > 0) {
          coupon = promotionCodes.data[0].coupon;
          console.log('✅ Found Promotion Code');
        } else {
          // Fallback: Try to retrieve coupon directly by ID (if code == ID)
          try {
            coupon = await stripe.coupons.retrieve(body.couponCode);
            console.log('✅ Found Coupon by ID');
          } catch (e) {
            console.log('❌ Coupon not found by ID');
          }
        }

        if (coupon && coupon.valid) {
          console.log(`💰 Applying discount: ${coupon.percent_off}% off or -${coupon.amount_off}`);

          if (coupon.percent_off) {
            finalAmount = finalAmount * (1 - (coupon.percent_off / 100));
          } else if (coupon.amount_off) {
            finalAmount = finalAmount - (coupon.amount_off / 100); // amount_off is in cents
          }

          couponId = coupon.id;

          // If amount drops below $0.50, we consider it a "Free Transaction" if it was due to a coupon
          // Otherwise Stripe would error.
          if (finalAmount < 0.50) {
            console.log('🎉 Transaction is effectively free (below Stripe minimum)');
            return new Response(
              JSON.stringify({
                success: true,
                isFree: true,
                message: 'Transaction is free due to coupon',
                couponCode: body.couponCode,
              }),
              {
                status: 200,
                headers: corsHeaders,
              }
            );
          }

          console.log(`📉 New Amount: ${finalAmount}`);
        } else {
          console.warn('⚠️ Invalid or inactive coupon');
          // We don't fail the request, just ignore the coupon
        }
      } catch (error) {
        console.error('❌ Error validating coupon:', error);
      }
    }

    // Create Stripe PaymentIntent
    const paymentIntent = await stripe.paymentIntents.create({
      amount: Math.round(finalAmount * 100), // Convert to cents
      currency: 'usd',
      metadata: {
        applicationId: body.applicationId,
        userId: body.userId,
        applicantName: body.applicant_name,
        couponCode: body.couponCode || null,
        couponId: couponId,
        originalAmount: body.amount,
      },
      description: `FounderVers Application Fee - App ID: ${body.applicationId}`,
      receipt_email: body.email,
      automatic_payment_methods: {
        enabled: true,
      },
    });

    // Verify PaymentIntent was created successfully
    if (!paymentIntent.client_secret) {
      throw new Error('Failed to create payment intent: no client secret');
    }

    console.log(`PaymentIntent created: ${paymentIntent.id}`);

    // Return success response
    return new Response(
      JSON.stringify({
        success: true,
        clientSecret: paymentIntent.client_secret,
        paymentIntentId: paymentIntent.id,
      } as PaymentIntentResponse),
      {
        status: 200,
        headers: corsHeaders,
      }
    );
  } catch (error) {
    console.error('❌ Error creating payment intent:', error);
    console.error('Error details:', {
      name: error instanceof Error ? error.name : 'Unknown',
      message: error instanceof Error ? error.message : String(error),
      stack: error instanceof Error ? error.stack : undefined,
    });

    const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred';

    return new Response(
      JSON.stringify({
        success: false,
        error: 'Failed to create payment intent',
        details: errorMessage,
      }),
      {
        status: 500,
        headers: corsHeaders,
      }
    );
  }
});
