const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

// Supabase Admin Configuration
const supabaseUrl = process.env.SUPABASE_URL || 'https://ycxqxdhaxehspypqbnpi.supabase.co';
const supabaseServiceKey = process.env.SUPABASE_SERVICE_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InljeHF4ZGhheGVoc3B5cHFibnBpIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MzIwMzAzMSwiZXhwIjoyMDY4Nzc5MDMxfQ.0jZl6iSSz0BV9TlQhWOE5utuv71YetOWhsU0vQOdagM';

// Verify Supabase Service Key
if (!process.env.SUPABASE_SERVICE_KEY) {
    console.error('❌ SUPABASE_SERVICE_KEY environment variable is required');
    console.error('   Please set your Supabase Service Role key in .env file');
    process.exit(1);
} else {
    console.log('✅ Supabase Admin API initialized');
}

const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey);

console.log(`🔗 Using Supabase project: ${supabaseUrl}`);

module.exports = {
    supabaseAdmin,
    supabaseUrl
};