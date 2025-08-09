/**
 * Central Supabase admin client.
 * Loads env from .env.local (dev) or process.env (prod).
 * No insecure fallbacks!
 */
const { createClient } = require('@supabase/supabase-js');

// Töltsük be lokálisan a backend/.env.local-t (ha létezik)
try {
  const fs = require('fs');
  const path = require('path');
  const dotenv = require('dotenv');
  const envPath = path.resolve(__dirname, '../../.env.local');
  if (fs.existsSync(envPath)) {
    dotenv.config({ path: envPath, override: true });
  } else {
    // utolsó esély: .env
    const envPath2 = path.resolve(__dirname, '../../.env');
    if (fs.existsSync(envPath2)) dotenv.config({ path: envPath2 });
  }
} catch (_) { /* no-op */ }

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_KEY || process.env.SUPABASE_SERVICE_ROLE_KEY;

// Kötelező env-ek – nincs több hardcode fallback!
if (!supabaseUrl) throw new Error('Missing SUPABASE_URL in env');
if (!supabaseServiceKey) throw new Error('Missing SUPABASE_SERVICE_KEY / SUPABASE_SERVICE_ROLE_KEY in env');

const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey);

console.log(`🔗 Using Supabase project: ${supabaseUrl}`);
module.exports = { supabaseAdmin, supabaseUrl };