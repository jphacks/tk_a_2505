import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
// Define CORS headers directly in the function file.
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type'
};
// The Gemini API endpoint for the specified model
const GEMINI_API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent";
/**
 * Main function to handle incoming requests.
 */ serve(async (req)=>{
  console.log('[START] Edge function invoked');
  console.log('[REQUEST] Method:', req.method);
  console.log('[REQUEST] URL:', req.url);
  // This is needed to handle CORS preflight requests.
  if (req.method === 'OPTIONS') {
    console.log('[CORS] Handling OPTIONS preflight request');
    return new Response('ok', {
      headers: corsHeaders
    });
  }
  try {
    console.log('[PARSE] Attempting to parse request body...');
    // 1. Extract the 'prompt' from the request body.
    const { prompt } = await req.json();
    console.log('[PARSE] Request body parsed successfully');
    console.log('[PROMPT] Received:', prompt ? `"${prompt.substring(0, 100)}${prompt.length > 100 ? '...' : ''}"` : 'null/undefined');
    console.log('[PROMPT] Length:', prompt?.length || 0, 'characters');
    if (!prompt) {
      console.warn('[VALIDATION] Missing prompt in request body');
      return new Response(JSON.stringify({
        error: 'The "prompt" field is required.'
      }), {
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        },
        status: 400
      });
    }
    // 2. Securely get the Gemini API key from Supabase environment variables.
    console.log('[ENV] Checking for GEMINI_API_KEY in environment...');
    const apiKey = Deno.env.get('GEMINI_API_KEY');
    if (!apiKey) {
      console.error('[ENV] GEMINI_API_KEY not found in environment variables');
      throw new Error("GEMINI_API_KEY is not set in Supabase secrets.");
    }
    console.log('[ENV] GEMINI_API_KEY found (length:', apiKey.length, 'chars)');
    // 3. Construct the payload for the Gemini API.
    const payload = {
      contents: [
        {
          parts: [
            {
              text: prompt
            }
          ]
        }
      ]
    };
    console.log('[PAYLOAD] Constructed:', JSON.stringify(payload, null, 2));
    console.log('[API] Calling Gemini API at:', GEMINI_API_URL);
    // 4. Call the Gemini API using fetch.
    const response = await fetch(`${GEMINI_API_URL}?key=${apiKey}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(payload)
    });
    console.log('[RESPONSE] Gemini API status:', response.status, response.statusText);
    // 5. Handle potential errors from the API call.
    if (!response.ok) {
      console.error('[ERROR] Gemini API returned non-OK status:', response.status);
      const errorBody = await response.json();
      console.error('[ERROR] Gemini API Error Body:', JSON.stringify(errorBody, null, 2));
      throw new Error(`Gemini API request failed with status ${response.status}: ${errorBody.error?.message || 'Unknown error'}`);
    }
    const responseData = await response.json();
    console.log('[SUCCESS] Gemini API response received');
    console.log('[DATA] Response structure:', JSON.stringify(responseData, null, 2));
    // 6. Safely extract the generated text from the response.
    const generatedText = responseData.candidates?.[0]?.content?.parts?.[0]?.text;
    if (!generatedText) {
      console.error('[ERROR] Could not extract generated text from response');
      console.error('[ERROR] Unexpected Gemini Response Body:', JSON.stringify(responseData, null, 2));
      throw new Error("Could not extract generated text from the Gemini API response.");
    }
    console.log('[EXTRACT] Generated text extracted (length:', generatedText.length, 'chars)');
    console.log('[EXTRACT] Text preview:', generatedText.substring(0, 200) + (generatedText.length > 200 ? '...' : ''));
    // 7. Return the successful response to the client.
    console.log('[COMPLETE] Sending successful response to client');
    return new Response(JSON.stringify({
      scenario: generatedText
    }), {
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/json'
      },
      status: 200
    });
  } catch (error) {
    // Generic error handler
    console.error('[EXCEPTION] Error caught in main handler');
    console.error('[EXCEPTION] Error type:', error.constructor.name);
    console.error('[EXCEPTION] Error message:', error.message);
    console.error('[EXCEPTION] Error stack:', error.stack);
    return new Response(JSON.stringify({
      error: error.message
    }), {
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/json'
      },
      status: 500
    });
  }
});
