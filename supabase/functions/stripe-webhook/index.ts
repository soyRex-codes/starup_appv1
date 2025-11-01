import type {} from '../_shared/deno-runtime.d.ts';

export {};

import { createClient } from 'npm:@supabase/supabase-js@2.39.7';
import Stripe from 'npm:stripe@14.19.0';

const stripeSecretKey = Deno.env.get('stripe_secret_key');
const stripeWebhookSecret = Deno.env.get('stripe_webhook_secret');
const supabaseUrl = Deno.env.get('SUPABASE_URL');
const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

const stripe = new Stripe(stripeSecretKey, {
  apiVersion: '2023-10-16',
});

const supabase = createClient(supabaseUrl, supabaseServiceKey);

// Helper to verify Stripe webhook signature
async function verifyStripeWebhookSignature(
  req: Request,
  secret: string
): Promise<Stripe.Event> {
  const signature = req.headers.get('stripe-signature');
  if (!signature) {
    throw new Error('Missing stripe-signature header');
  }

  const body = await req.text();
  const event = stripe.webhooks.constructEvent(body, signature, secret);
  return event;
}

console.log('stripe-webhook function loaded');

Deno.serve(async (req: Request) => {
  // Only accept POST requests
  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  try {
    // Verify webhook signature
    const event = await verifyStripeWebhookSignature(req, stripeWebhookSecret);

    console.log(`Webhook event received: ${event.type}`);

    // Handle different event types
    switch (event.type) {
      case 'payment_intent.succeeded':
        return await handlePaymentIntentSucceeded(event.data.object as Stripe.PaymentIntent);

      case 'payment_intent.payment_failed':
        return await handlePaymentIntentFailed(event.data.object as Stripe.PaymentIntent);

      case 'charge.refunded':
        return await handleChargeRefunded(event.data.object as Stripe.Charge);

      default:
        // Acknowledge other events
        return new Response(
          JSON.stringify({
            success: true,
            message: `Event ${event.type} received and acknowledged`,
          }),
          {
            status: 200,
            headers: { 'Content-Type': 'application/json' },
          }
        );
    }
  } catch (error) {
    console.error('Webhook error:', error);

    const statusCode = error instanceof Error && error.message.includes('signature')
      ? 403
      : 500;

    return new Response(
      JSON.stringify({
        error: 'Webhook processing failed',
        details: error instanceof Error ? error.message : 'Unknown error',
      }),
      {
        status: statusCode,
        headers: { 'Content-Type': 'application/json' },
      }
    );
  }
});

// Handle successful payment
async function handlePaymentIntentSucceeded(
  paymentIntent: Stripe.PaymentIntent
): Promise<Response> {
  try {
    const applicationId = paymentIntent.metadata?.applicationId;

    if (!applicationId) {
      console.error('No applicationId in metadata:', paymentIntent.id);
      return new Response(
        JSON.stringify({
          success: false,
          error: 'Missing applicationId in metadata',
        }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // Update payment record in database
    const { error: updateError } = await supabase
      .from('application_payments')
      .update({
        status: 'succeeded',
        payment_intent_id: paymentIntent.id,
        updated_at: new Date().toISOString(),
      })
      .eq('application_id', applicationId)
      .order('created_at', { ascending: false })
      .limit(1);

    if (updateError) {
      console.error('Database update error:', updateError);
      throw updateError;
    }

    console.log(
      `Payment succeeded for application ${applicationId}, PaymentIntent: ${paymentIntent.id}`
    );

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Payment recorded successfully',
        applicationId,
        paymentIntentId: paymentIntent.id,
      }),
      {
        status: 200,
        headers: { 'Content-Type': 'application/json' },
      }
    );
  } catch (error) {
    console.error('Error handling payment success:', error);
    return new Response(
      JSON.stringify({
        error: 'Failed to record payment',
        details: error instanceof Error ? error.message : 'Unknown error',
      }),
      {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      }
    );
  }
}

// Handle payment failure
async function handlePaymentIntentFailed(
  paymentIntent: Stripe.PaymentIntent
): Promise<Response> {
  try {
    const applicationId = paymentIntent.metadata?.applicationId;
    const errorMessage = paymentIntent.last_payment_error?.message || 'Payment failed';

    if (!applicationId) {
      console.error('No applicationId in metadata:', paymentIntent.id);
      return new Response(
        JSON.stringify({
          success: false,
          error: 'Missing applicationId in metadata',
        }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // Update payment record with failure status
    const { error: updateError } = await supabase
      .from('application_payments')
      .update({
        status: 'failed',
        error_message: errorMessage,
        payment_intent_id: paymentIntent.id,
        updated_at: new Date().toISOString(),
      })
      .eq('application_id', applicationId)
      .order('created_at', { ascending: false })
      .limit(1);

    if (updateError) {
      console.error('Database update error:', updateError);
      throw updateError;
    }

    console.log(
      `Payment failed for application ${applicationId}, PaymentIntent: ${paymentIntent.id}`
    );

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Payment failure recorded',
        applicationId,
        paymentIntentId: paymentIntent.id,
        error: errorMessage,
      }),
      {
        status: 200,
        headers: { 'Content-Type': 'application/json' },
      }
    );
  } catch (error) {
    console.error('Error handling payment failure:', error);
    return new Response(
      JSON.stringify({
        error: 'Failed to record payment failure',
        details: error instanceof Error ? error.message : 'Unknown error',
      }),
      {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      }
    );
  }
}

// Handle refund
async function handleChargeRefunded(charge: Stripe.Charge): Promise<Response> {
  try {
    const paymentIntentId = charge.payment_intent as string;

    // Find the payment record by payment_intent_id
    const { data: paymentData, error: queryError } = await supabase
      .from('application_payments')
      .select('id, application_id')
      .eq('payment_intent_id', paymentIntentId)
      .single();

    if (queryError) {
      console.error('Query error:', queryError);
      return new Response(
        JSON.stringify({
          success: false,
          error: 'Payment record not found',
        }),
        { status: 404, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // Update payment record with refunded status
    const { error: updateError } = await supabase
      .from('application_payments')
      .update({
        status: 'refunded',
        updated_at: new Date().toISOString(),
      })
      .eq('id', paymentData.id);

    if (updateError) {
      console.error('Database update error:', updateError);
      throw updateError;
    }

    console.log(
      `Refund processed for application ${paymentData.application_id}, PaymentIntent: ${paymentIntentId}`
    );

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Refund recorded successfully',
        applicationId: paymentData.application_id,
      }),
      {
        status: 200,
        headers: { 'Content-Type': 'application/json' },
      }
    );
  } catch (error) {
    console.error('Error handling refund:', error);
    return new Response(
      JSON.stringify({
        error: 'Failed to record refund',
        details: error instanceof Error ? error.message : 'Unknown error',
      }),
      {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      }
    );
  }
}
