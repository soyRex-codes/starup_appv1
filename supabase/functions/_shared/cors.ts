// Global Deno declaration for Edge Functions
declare const Deno: {
  env: {
    get(key: string): string | undefined;
  };
};

// Read allowed origins from environment variables
const ALLOWED_ORIGINS = Deno.env.get('ALLOWED_ORIGINS')?.split(',').map((origin: string) => origin.trim()) || [
  'https://foundervers.com',
  'https://app.foundervers.com',
  'https://www.foundervers.com',
  'http://localhost:3000', // Development
  'http://127.0.0.1:3000', // Development
  'http://localhost:8080', // Development alternative
];

/**
 * Validates the request origin against the allowed origins list
 * @param request - The incoming request
 * @returns The validated origin or null if not allowed
 */
export function validateOrigin(request: Request): string | null {
  const origin = request.headers.get('origin');
  
  if (!origin) {
    // No origin header (e.g., same-origin requests, direct API calls)
    return null;
  }

  // Check for exact match in allowed origins
  if (ALLOWED_ORIGINS.includes(origin)) {
    return origin;
  }

  // Additional regex-based validation for dynamic subdomains (optional)
  const dynamicPatterns = [
    /^https:\/\/[a-zA-Z0-9-]+\.foundervers\.com$/,
    /^https:\/\/[a-zA-Z0-9-]+\.vercel\.app$/, // For Vercel deployments
    /^https:\/\/[a-zA-Z0-9-]+\.netlify\.app$/, // For Netlify deployments
  ];

  for (const pattern of dynamicPatterns) {
    if (pattern.test(origin)) {
      return origin;
    }
  }

  return null;
}

/**
 * Creates CORS headers for a validated origin
 * @param validatedOrigin - The validated origin or null
 * @returns CORS headers object
 */
export function createCorsHeaders(validatedOrigin: string | null): Record<string, string> {
  const headers: Record<string, string> = {
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
    'Access-Control-Allow-Methods': 'POST, GET, OPTIONS, PUT, DELETE',
    'Access-Control-Max-Age': '86400', // 24 hours
    'Vary': 'Origin', // Important for caching behavior with different origins
    'Content-Type': 'application/json',
  };

  if (validatedOrigin) {
    headers['Access-Control-Allow-Origin'] = validatedOrigin;
    headers['Access-Control-Allow-Credentials'] = 'true';
  } else {
    // For requests without origin or invalid origins, don't set CORS headers
    delete headers['Access-Control-Allow-Origin'];
    delete headers['Access-Control-Allow-Credentials'];
  }

  return headers;
}

/**
 * Handles CORS preflight requests
 * @param request - The incoming OPTIONS request
 * @returns Response for preflight or null if not a preflight request
 */
export function handleCorsPreflightRequest(request: Request): Response | null {
  if (request.method !== 'OPTIONS') {
    return null;
  }

  const validatedOrigin = validateOrigin(request);
  
  if (!validatedOrigin && request.headers.get('origin')) {
    // Reject preflight from unauthorized origins (only if origin header is present)
    return new Response(null, {
      status: 403,
      statusText: 'Forbidden - Origin not allowed',
      headers: {
        'Vary': 'Origin',
      },
    });
  }

  return new Response(null, {
    status: 204, // 204 No Content is more appropriate for successful OPTIONS
    headers: createCorsHeaders(validatedOrigin),
  });
}

/**
 * Example usage in an Edge Function:
 * 
 * ```typescript
 * import { validateOrigin, createCorsHeaders, handleCorsPreflightRequest } from "../_shared/cors.ts"
 * 
 * serve(async (req) => {
 *   // Handle CORS preflight requests
 *   const preflightResponse = handleCorsPreflightRequest(req);
 *   if (preflightResponse) {
 *     return preflightResponse;
 *   }
 * 
 *   // Validate origin for all requests
 *   const validatedOrigin = validateOrigin(req);
 *   const corsHeaders = createCorsHeaders(validatedOrigin);
 * 
 *   // Reject unauthorized origins
 *   if (req.headers.get('origin') && !validatedOrigin) {
 *     return new Response('Forbidden - Origin not allowed', {
 *       status: 403,
 *       headers: corsHeaders,
 *     });
 *   }
 * 
 *   // Your function logic here
 *   const result = await yourFunctionLogic();
 * 
 *   return new Response(JSON.stringify(result), {
 *     headers: { ...corsHeaders, 'Content-Type': 'application/json' },
 *   });
 * });
 * ```
 * 
 * Environment variables:
 * ALLOWED_ORIGINS=https://foundervers.com,https://app.foundervers.com,http://localhost:3000
 * 
 * Security Features:
 * - Origin validation against allowlist
 * - Proper CORS header management with Vary: Origin
 * - 403 responses for unauthorized origins
 * - 204 responses for valid preflight requests
 * - Support for dynamic subdomain patterns
 * - Credentials support for validated origins only
 */

// Legacy export for backward compatibility (DEPRECATED - DO NOT USE)
// Use createCorsHeaders() with validateOrigin() instead
export const corsHeaders = {
  'Access-Control-Allow-Origin': '*', // ⚠️ INSECURE - Only for backward compatibility
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}