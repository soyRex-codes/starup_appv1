import { validateOrigin, createCorsHeaders, handleCorsPreflightRequest } from "../_shared/cors.ts";

// Global Deno declaration for Edge Functions
declare const Deno: {
  env: {
    get(key: string): string | undefined;
  };
  serve: (handler: (req: Request) => Response | Promise<Response>) => void;
};

interface NotificationRequest {
  applicant_name: string
  business_name: string
  service_type: string
  applicant_email: string
  admin_email: string
  subject: string
  body: string
  application_id: string
}

interface EmailResponse {
  success: boolean
  message: string
  application_id: string
  admin_email: string
  email_sent: boolean
  email_id?: string
  logged?: boolean
  note?: string
}

// HTML escaping helper to prevent XSS attacks
function escapeHtml(unsafe: string): string {
  if (!unsafe) return '';
  return unsafe
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;")
    .replace(/`/g, "&#x60;");
}

console.log("send-business-notification function loaded")

Deno.serve(async (req: Request) => {
  // Handle CORS preflight requests
  const preflightResponse = handleCorsPreflightRequest(req);
  if (preflightResponse) {
    return preflightResponse;
  }

  // Validate origin and create CORS headers
  const validatedOrigin = validateOrigin(req);
  const corsHeaders = createCorsHeaders(validatedOrigin);

  // Reject unauthorized origins (if origin header is present but not validated)
  if (req.headers.get('origin') && !validatedOrigin) {
    return new Response('Forbidden - Origin not allowed', {
      status: 403,
      headers: corsHeaders,
    });
  }

  try {
    const requestData: NotificationRequest = await req.json()
    
    const { 
      applicant_name, 
      business_name, 
      service_type, 
      applicant_email, 
      admin_email, 
      subject, 
      body,
      application_id 
    } = requestData

    // Validate required fields
    if (!applicant_name || !admin_email || !application_id) {
      return new Response(
        JSON.stringify({ 
          success: false, 
          message: 'Missing required fields: applicant_name, admin_email, or application_id' 
        }),
        { status: 400, headers: corsHeaders }
      )
    }

    console.log('🚀 Processing notification for application:', application_id)
    console.log('📧 Admin email:', admin_email)
    console.log('👤 Applicant:', applicant_name, '(' + applicant_email + ')')
    console.log('🏢 Business:', business_name || 'Not specified')
    console.log('📋 Service:', service_type || 'Not specified')

    // Detailed logging for debugging
    console.log('='.repeat(60))
    console.log('📬 EMAIL NOTIFICATION DETAILS')
    console.log('='.repeat(60))
    console.log(`Subject: ${subject || 'New Business Application'}`)
    console.log(`To: ${admin_email}`)
    console.log(`Application ID: ${application_id}`)
    console.log(`Applicant: ${applicant_name} (${applicant_email || 'No email'})`)
    console.log(`Business: ${business_name || 'Not specified'}`)
    console.log(`Service Type: ${service_type || 'Not specified'}`)
    console.log('='.repeat(60))

    // Create properly formatted email body with HTML escaping for security
    const htmlBody = `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <title>New Business Application</title>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: #f4f4f4; padding: 20px; border-radius: 5px; margin-bottom: 20px; }
          .content { background: #fff; padding: 20px; border: 1px solid #ddd; border-radius: 5px; }
          .field { margin-bottom: 15px; }
          .label { font-weight: bold; color: #555; }
          .value { margin-left: 10px; }
          .footer { margin-top: 20px; padding: 15px; background: #f9f9f9; text-align: center; font-size: 12px; color: #666; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h2>🚀 New Business Application Received</h2>
            <p>A new business application has been submitted through FounderVers.</p>
          </div>
          
          <div class="content">
            <div class="field">
              <span class="label">📄 Application ID:</span>
              <span class="value">${escapeHtml(application_id)}</span>
            </div>
            
            <div class="field">
              <span class="label">👤 Applicant Name:</span>
              <span class="value">${escapeHtml(applicant_name)}</span>
            </div>
            
            <div class="field">
              <span class="label">📧 Applicant Email:</span>
              <span class="value">${escapeHtml(applicant_email || 'Not provided')}</span>
            </div>
            
            <div class="field">
              <span class="label">🏢 Business Name:</span>
              <span class="value">${escapeHtml(business_name || 'Not specified')}</span>
            </div>
            
            <div class="field">
              <span class="label">📋 Service Type:</span>
              <span class="value">${escapeHtml(service_type || 'Not specified')}</span>
            </div>
            
            <div class="field">
              <span class="label">⏰ Submitted:</span>
              <span class="value">${escapeHtml(new Date().toLocaleString())}</span>
            </div>
          </div>
          
          <div class="footer">
            <p>This is an automated notification from FounderVers Business Portal</p>
            <p>Log in to your admin dashboard to view the complete application details</p>
          </div>
        </div>
      </body>
      </html>
    `

    // Send email via Resend API
    try {
      console.log('📧 Attempting to send email...')
      
      // Send via Resend (recommended for production)
      const resendApiKey = Deno.env.get('RESEND_API_KEY')
      
      if (resendApiKey) {
        console.log('📧 Sending via Resend...')
        const resendResponse = await fetch('https://api.resend.com/emails', {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${resendApiKey}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            from: `FounderVers <noreply@foundervers.com>`,
            to: [admin_email],
            subject: subject,
            html: htmlBody,
            reply_to: applicant_email,
            headers: {
              'X-Application-ID': application_id,
              'X-Service-Type': service_type
            }
          }),
        })

        if (resendResponse.ok) {
          const resendResult = await resendResponse.json()
          console.log('✅ Email sent successfully via Resend!', resendResult)
          return new Response(
            JSON.stringify({ 
              success: true, 
              message: 'Business application notification sent successfully via Resend',
              application_id: application_id,
              admin_email: admin_email,
              email_sent: true,
              email_id: resendResult.id
            }),
            { 
              status: 200, 
              headers: corsHeaders 
            }
          )
        } else {
          const errorText = await resendResponse.text()
          console.error('❌ Resend error:', errorText)
          throw new Error(`Resend API failed: ${errorText}`)
        }
      } else {
        console.log('📝 No Resend API key found, email logged but not sent')
        console.log('🔧 To enable email sending:')
        console.log('   1. Sign up at https://resend.com')
        console.log('   2. Get API key')
        console.log('   3. Add RESEND_API_KEY to Supabase Environment Variables')
      }
      
    } catch (emailError) {
      console.error('❌ Email sending failed:', emailError)
      console.log('📝 Continuing with logged notification as fallback...')
    }

    return new Response(
      JSON.stringify({ 
        success: true, 
        message: 'Business application notification logged (email failed but notification preserved)',
        application_id: application_id,
        admin_email: admin_email,
        logged: true,
        email_sent: false,
        note: 'Check Supabase logs for email error details'
      }),
      { 
        status: 200, 
        headers: corsHeaders 
      }
    )

  } catch (error) {
    console.error('❌ Function error:', error)
    console.log('📋 Fallback: Error logged, but function succeeded to prevent database trigger failure')
    
    return new Response(
      JSON.stringify({ 
        success: true, 
        message: 'Function executed with error (logged for debugging)',
        error: String(error),
        fallback: true
      }), 
      { 
        status: 200, 
        headers: corsHeaders 
      }
    )
  }
})