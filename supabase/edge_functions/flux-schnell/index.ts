import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import Replicate from "npm:replicate@latest";
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { getFirstShelterId } from './test.ts';
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type'
};
serve(async (req)=>{
  console.log('[START] Edge function invoked');
  console.log('[REQUEST] Method:', req.method);
  console.log('[REQUEST] URL:', req.url);
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    console.log('[CORS] Handling OPTIONS preflight request');
    return new Response('ok', {
      headers: corsHeaders
    });
  }
  try {
    console.log('[PARSE] Attempting to parse request body...');
    const { prompt, shelter_id } = await req.json();
    console.log('[PARSE] Request body parsed successfully');
    console.log('[PROMPT] Received:', prompt ? `"${prompt.substring(0, 100)}${prompt.length > 100 ? '...' : ''}"` : 'null/undefined');
    console.log('[SHELTER_ID] Received:', shelter_id || 'null/undefined (will use first shelter)');
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
    // Get the authorization header to authenticate the user
    console.log('[AUTH] Extracting authorization token...');
    const authHeader = req.headers.get('authorization');
    if (!authHeader) {
      console.error('[AUTH] No authorization header found');
      return new Response(JSON.stringify({
        error: 'Authorization header is required.'
      }), {
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        },
        status: 401
      });
    }
    // Initialize Replicate
    console.log('[ENV] Checking for REPLICATE_API_TOKEN...');
    const token = Deno.env.get('REPLICATE_API_TOKEN');
    if (!token) {
      console.error('[ENV] REPLICATE_API_TOKEN not found');
      throw new Error("REPLICATE_API_TOKEN is not set in Supabase secrets.");
    }
    console.log('[REPLICATE] Initializing Replicate client...');
    const replicate = new Replicate({
      auth: token
    });
    const input = {
      prompt
    };
    console.log('[API] Calling Replicate API...');
    const output = await replicate.run("black-forest-labs/flux-schnell", {
      input
    });
    console.log('[RESPONSE] Replicate API response received');
    if (!output || !output[0]) {
      console.error('[ERROR] No output returned from Replicate API');
      throw new Error("No output returned from Replicate API");
    }
    const imageUrl = output[0].url();
    console.log('[EXTRACT] Image URL extracted:', imageUrl);
    // Initialize Supabase client
    console.log('[SUPABASE] Initializing Supabase client...');
    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
    if (!supabaseUrl || !supabaseServiceKey) {
      throw new Error("Supabase credentials not found in environment");
    }
    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey);
    // Create a client with the user's token to get their user ID
    const supabaseUser = createClient(supabaseUrl, supabaseServiceKey, {
      global: {
        headers: {
          Authorization: authHeader
        }
      }
    });
    // Get the authenticated user
    console.log('[AUTH] Getting authenticated user...');
    const { data: { user }, error: userError } = await supabaseUser.auth.getUser();
    if (userError || !user) {
      console.error('[AUTH] Failed to get user:', userError);
      return new Response(JSON.stringify({
        error: 'Failed to authenticate user.'
      }), {
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        },
        status: 401
      });
    }
    console.log('[AUTH] User authenticated, ID:', user.id);
    // Fetch the image from Replicate
    console.log('[FETCH] Downloading image from Replicate...');
    const imageResponse = await fetch(imageUrl);
    if (!imageResponse.ok) {
      throw new Error(`Failed to fetch image: ${imageResponse.statusText}`);
    }
    const imageBlob = await imageResponse.blob();
    console.log('[FETCH] Image downloaded, size:', imageBlob.size, 'bytes');
    // Generate a unique filename
    const timestamp = Date.now();
    const filename = `badge_${timestamp}.png`;
    console.log('[UPLOAD] Uploading to shelter_badges bucket as:', filename);
    // Upload to Supabase Storage
    const { data: uploadData, error: uploadError } = await supabaseAdmin.storage.from('shelter_badges').upload(filename, imageBlob, {
      contentType: 'image/png',
      upsert: false
    });
    if (uploadError) {
      console.error('[UPLOAD] Error uploading to storage:', uploadError);
      throw uploadError;
    }
    console.log('[UPLOAD] Image uploaded successfully:', uploadData.path);
    // Get the public URL
    const { data: { publicUrl } } = supabaseAdmin.storage.from('shelter_badges').getPublicUrl(filename);
    console.log('[URL] Public URL generated:', publicUrl);
    // Determine which shelter_id to use
    let finalShelterId;
    if (shelter_id) {
      console.log('[SHELTER] Using provided shelter_id:', shelter_id);
      finalShelterId = shelter_id;
    } else {
      console.log('[SHELTER] No shelter_id provided, fetching first shelter...');
      const firstShelterId = await getFirstShelterId();
      if (!firstShelterId) {
        throw new Error("No shelters found in database. Please create a shelter first.");
      }
      console.log('[SHELTER] Using first shelter_id:', firstShelterId);
      finalShelterId = firstShelterId;
    }
    // Insert a row into the shelter_badges table
    console.log('[DATABASE] Inserting row into shelter_badges table...');
    const { data: badgeData, error: badgeError } = await supabaseAdmin.from('shelter_badges').insert({
      badge_name: filename,
      shelter_id: finalShelterId,
      first_user_id: user.id
    }).select().single();
    if (badgeError) {
      console.error('[DATABASE] Error inserting badge record:', badgeError);
      throw badgeError;
    }
    console.log('[DATABASE] Badge record created:', badgeData);
    // Return the same structure as before (only imageUrl and prompt)
    const responseBody = {
      imageUrl: publicUrl,
      prompt: prompt // Echo back the prompt
    };
    console.log('[COMPLETE] Sending successful response to client');
    console.log('[RESPONSE] Response body:', JSON.stringify(responseBody, null, 2));
    return new Response(JSON.stringify(responseBody), {
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/json'
      },
      status: 200
    });
  } catch (error) {
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
