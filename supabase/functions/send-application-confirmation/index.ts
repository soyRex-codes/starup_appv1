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
    'Access-Control-Allow-Methods': 'POST, GET, OPTIONS, PUT, DELETE',
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

interface ConfirmationRequest {
  applicant_name: string
  applicant_email: string
  service_type: string
  service_type_display: string
  application_id: string
  business_name?: string
}

console.log("send-application-confirmation function loaded")

Deno.serve(async (req: Request) => {
  // Handle CORS preflight
  const preflightResponse = handleCorsPreflightRequest(req);
  if (preflightResponse) {
    return preflightResponse;
  }

  // Validate origin and create CORS headers
  const validatedOrigin = validateOrigin(req);
  const corsHeaders = createCorsHeaders(validatedOrigin);

  if (req.headers.get('origin') && !validatedOrigin) {
    return new Response('Forbidden - Origin not allowed', {
      status: 403,
      headers: corsHeaders,
    });
  }

  try {
    const requestData: ConfirmationRequest = await req.json()

    const {
      applicant_name,
      applicant_email,
      service_type_display,
      application_id,
    } = requestData

    if (!applicant_name || !applicant_email || !application_id) {
      return new Response(
        JSON.stringify({
          success: false,
          message: 'Missing required fields'
        }),
        { status: 400, headers: corsHeaders }
      )
    }

    console.log('📧 Sending simplified receipt for:', application_id)

    // Simplified HTML Receipt
    const htmlBody = `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <title>Application Receipt</title>
        <style>
          body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; line-height: 1.6; color: #333; background-color: #f9f9f9; padding: 20px; }
          .container { max-width: 500px; margin: 0 auto; background: #fff; padding: 30px; border-radius: 12px; box-shadow: 0 2px 4px rgba(0,0,0,0.05); }
          .header { text-align: center; margin-bottom: 30px; }
          .icon { font-size: 48px; margin-bottom: 10px; }
          h1 { margin: 0; font-size: 24px; color: #111; }
          .details { background: #f5f5f5; padding: 15px; border-radius: 8px; margin: 20px 0; font-size: 14px; }
          .footer { text-align: center; font-size: 12px; color: #888; margin-top: 30px; }
          .button { display: inline-block; background: #000; color: #fff; padding: 12px 24px; text-decoration: none; border-radius: 6px; font-weight: 500; margin-top: 20px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <div class="icon">✅</div>
            <h1>Application Received</h1>
          </div>
          
          <p>Hi ${applicant_name},</p>
          
          <p>We have received your application for <strong>${service_type_display}</strong>.</p>
          
          <div class="details">
            <strong>Application ID:</strong> ${application_id}<br>
            <strong>Date:</strong> ${new Date().toLocaleDateString()}<br>
            <strong>Status:</strong> Pending Review
          </div>
          
          <p>You can view the full details and track the status of your application directly in the app.</p>
          
          <div style="text-align: center;">
            <a href="https://foundervers.com/profile/applications" class="button">Open App</a>
          </div>
          
          <div class="footer">
            FounderVers Business Services<br>
            This is an automated receipt.
          </div>
        </div>
      </body>
      </html>
    `

    // Send via Resend
    const resendApiKey = Deno.env.get('RESEND_API_KEY')

    if (!resendApiKey) {
      console.warn('⚠️ No RESEND_API_KEY found')
      return new Response(
        JSON.stringify({ success: true, message: 'Simulated success (no API key)' }),
        { status: 200, headers: corsHeaders }
      )
    }

    const resendResponse = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${resendApiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        from: 'FounderVers <noreply@foundervers.com>',
        to: [applicant_email],
        subject: `Receipt: ${service_type_display} Application (#${application_id})`,
        html: htmlBody,
      }),
    })

    if (resendResponse.ok) {
      const data = await resendResponse.json()
      return new Response(
        JSON.stringify({ success: true, id: data.id }),
        { status: 200, headers: corsHeaders }
      )
    } else {
      const error = await resendResponse.text()
      console.error('Resend Error:', error)
      return new Response(
        JSON.stringify({ success: false, error }),
        { status: 500, headers: corsHeaders }
      )
    }

  } catch (error) {
    return new Response(
      JSON.stringify({ success: false, error: String(error) }),
      { status: 500, headers: corsHeaders }
    )
  }
})
