import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
/**
 * Gets the first shelter ID from the shelters table
 * @returns The UUID of the first shelter, or null if no shelters exist
 */ export async function getFirstShelterId() {
  console.log('[TEST] Getting first shelter ID...');
  // Initialize Supabase client
  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!supabaseUrl || !supabaseServiceKey) {
    console.error('[TEST] Supabase credentials not found in environment');
    throw new Error("Supabase credentials not found in environment");
  }
  const supabase = createClient(supabaseUrl, supabaseServiceKey);
  // Query for the first shelter
  const { data, error } = await supabase.from('shelters').select('id').order('last_updated', {
    ascending: true
  }).limit(1).single();
  if (error) {
    console.error('[TEST] Error fetching shelter:', error);
    throw error;
  }
  if (!data) {
    console.warn('[TEST] No shelters found in database');
    return null;
  }
  console.log('[TEST] First shelter ID:', data.id);
  return data.id;
}
/**
 * Gets a random shelter ID from the shelters table
 * @returns A random shelter UUID, or null if no shelters exist
 */ export async function getRandomShelterId() {
  console.log('[TEST] Getting random shelter ID...');
  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!supabaseUrl || !supabaseServiceKey) {
    throw new Error("Supabase credentials not found in environment");
  }
  const supabase = createClient(supabaseUrl, supabaseServiceKey);
  // Get all shelter IDs
  const { data, error } = await supabase.from('shelters').select('id');
  if (error) {
    console.error('[TEST] Error fetching shelters:', error);
    throw error;
  }
  if (!data || data.length === 0) {
    console.warn('[TEST] No shelters found in database');
    return null;
  }
  // Pick a random shelter
  const randomIndex = Math.floor(Math.random() * data.length);
  const shelterId = data[randomIndex].id;
  console.log('[TEST] Random shelter ID:', shelterId);
  return shelterId;
}
/**
 * Gets a shelter ID by name
 * @param shelterName The name of the shelter to find
 * @returns The shelter UUID, or null if not found
 */ export async function getShelterIdByName(shelterName) {
  console.log('[TEST] Getting shelter ID for name:', shelterName);
  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!supabaseUrl || !supabaseServiceKey) {
    throw new Error("Supabase credentials not found in environment");
  }
  const supabase = createClient(supabaseUrl, supabaseServiceKey);
  // Query for shelter by name (assuming you have a 'name' column)
  const { data, error } = await supabase.from('shelters').select('id').eq('name', shelterName).single();
  if (error) {
    console.error('[TEST] Error fetching shelter by name:', error);
    return null;
  }
  if (!data) {
    console.warn('[TEST] No shelter found with name:', shelterName);
    return null;
  }
  console.log('[TEST] Shelter ID for', shelterName, ':', data.id);
  return data.id;
}
