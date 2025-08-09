#!/usr/bin/env node

/**
 * Verify Connection and Current RLS State
 * Tests connection to NEW Supabase project and checks current policies
 */

// Node.js 24+ has native fetch, but fallback to node-fetch if needed
if (typeof fetch === 'undefined') {
    global.fetch = require('node-fetch');
}

// NEW Project Configuration
const SUPABASE_URL = 'https://aeijlzokobuqcyznljvn.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFlaWpsem9rb2J1cWN5em5sanZuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ1NjYwNTYsImV4cCI6MjA3MDE0MjA1Nn0.Kva8czOdONqJp2512w_94dcRq8ZPkYOnLT9oRsldmJM';

async function testConnection() {
    console.log('🔍 Testing Supabase Connection');
    console.log('==============================');
    console.log('URL:', SUPABASE_URL);
    console.log('');

    try {
        // Test basic health
        const healthResponse = await fetch(`${SUPABASE_URL}/rest/v1/`);
        console.log('✅ REST API Health:', healthResponse.status, healthResponse.statusText);
        
        // Test auth health
        const authResponse = await fetch(`${SUPABASE_URL}/auth/v1/health`);
        console.log('✅ Auth API Health:', authResponse.status, authResponse.statusText);
        
        return true;
    } catch (error) {
        console.error('❌ Connection failed:', error.message);
        return false;
    }
}

async function checkTables() {
    console.log('🔍 Checking Available Tables');
    console.log('============================');
    
    const tables = [
        'user_profiles',
        'cards', 
        'categories',
        'flashcard_sets',
        'classrooms',
        'schools'
    ];

    for (const table of tables) {
        try {
            const response = await fetch(`${SUPABASE_URL}/rest/v1/${table}?limit=1`, {
                headers: {
                    'apikey': SUPABASE_ANON_KEY,
                    'Authorization': `Bearer ${SUPABASE_ANON_KEY}`
                }
            });

            if (response.ok) {
                console.log(`✅ ${table}: Accessible (${response.status})`);
            } else {
                console.log(`❌ ${table}: ${response.status} ${response.statusText}`);
            }
        } catch (error) {
            console.log(`❌ ${table}: ${error.message}`);
        }
    }
    console.log('');
}

async function testRLSStatus() {
    console.log('🔐 Testing RLS Policy Status');
    console.log('============================');
    
    // Try to access a table that might have RLS enabled
    try {
        const response = await fetch(`${SUPABASE_URL}/rest/v1/user_profiles?limit=1`, {
            headers: {
                'apikey': SUPABASE_ANON_KEY,
                'Authorization': `Bearer ${SUPABASE_ANON_KEY}`
            }
        });

        if (response.ok) {
            const data = await response.json();
            console.log('✅ user_profiles accessible (RLS may be disabled or permissive)');
            console.log('📊 Sample records:', data.length);
        } else if (response.status === 403) {
            console.log('🔐 user_profiles: Access denied (RLS likely enabled)');
        } else {
            console.log(`❓ user_profiles: ${response.status} ${response.statusText}`);
        }
    } catch (error) {
        console.log('❌ user_profiles test failed:', error.message);
    }
    console.log('');
}

async function testAuthenticatedAccess() {
    console.log('🔑 Testing Authentication');
    console.log('=========================');
    
    try {
        const authResponse = await fetch(`${SUPABASE_URL}/auth/v1/token?grant_type=password`, {
            method: 'POST',
            headers: {
                'apikey': SUPABASE_ANON_KEY,
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                email: 'vidamkos@gmail.com',
                password: 'Teaching123'  // Default password as per previous fixes
            })
        });

        if (authResponse.ok) {
            const authData = await authResponse.json();
            if (authData.access_token) {
                console.log('✅ Authentication successful');
                console.log('🔑 Access token obtained');
                
                // Test authenticated access
                const profileResponse = await fetch(`${SUPABASE_URL}/rest/v1/user_profiles?select=id,email,user_role&limit=1`, {
                    headers: {
                        'apikey': SUPABASE_ANON_KEY,
                        'Authorization': `Bearer ${authData.access_token}`
                    }
                });

                if (profileResponse.ok) {
                    const profileData = await profileResponse.json();
                    console.log('✅ Authenticated profile access successful');
                    console.log('👤 Profile data:', profileData.length > 0 ? 'Found' : 'Empty');
                } else {
                    console.log('❌ Authenticated profile access failed:', profileResponse.status);
                }
            } else {
                console.log('❌ No access token in response');
            }
        } else {
            console.log('❌ Authentication failed:', authResponse.status);
            const error = await authResponse.text();
            console.log('Error:', error);
        }
    } catch (error) {
        console.log('❌ Authentication test failed:', error.message);
    }
    console.log('');
}

async function generateExecutionInstructions() {
    console.log('📋 MANUAL EXECUTION INSTRUCTIONS');
    console.log('================================');
    console.log('');
    console.log('Since automated execution requires service_role permissions,');
    console.log('here are the manual steps to execute the RLS policies:');
    console.log('');
    console.log('1. 🌐 Open Supabase Dashboard:');
    console.log('   https://supabase.com/dashboard/project/aeijlzokobuqcyznljvn');
    console.log('');
    console.log('2. 📝 Navigate to SQL Editor:');
    console.log('   Dashboard → SQL Editor → New query');
    console.log('');
    console.log('3. 📄 Copy Migration Content:');
    console.log('   - Open: migrate-all-rls-policies.sql');
    console.log('   - Select all content (Ctrl+A / Cmd+A)');
    console.log('   - Copy (Ctrl+C / Cmd+C)');
    console.log('');
    console.log('4. ▶️  Execute in Dashboard:');
    console.log('   - Paste content in SQL Editor');
    console.log('   - Click "Run" button');
    console.log('   - Wait for execution to complete');
    console.log('');
    console.log('5. ✅ Verify Results:');
    console.log('   Run these verification queries separately:');
    console.log('');
    console.log('   Query 1 - Total Policies:');
    console.log('   SELECT COUNT(*) as total_policies FROM pg_policies WHERE schemaname IN (\'public\', \'auth\', \'storage\');');
    console.log('');
    console.log('   Query 2 - Policies by Table:');
    console.log('   SELECT schemaname, tablename, COUNT(*) as policy_count');
    console.log('   FROM pg_policies'); 
    console.log('   WHERE schemaname IN (\'public\', \'auth\', \'storage\')');
    console.log('   GROUP BY schemaname, tablename');
    console.log('   ORDER BY schemaname, tablename;');
    console.log('');
    console.log('   Query 3 - RLS Status:');
    console.log('   SELECT schemaname, tablename, rowsecurity');
    console.log('   FROM pg_tables');
    console.log('   WHERE schemaname IN (\'public\', \'auth\', \'storage\')');
    console.log('   ORDER BY schemaname, tablename;');
    console.log('');
    console.log('🎯 Expected Results:');
    console.log('- Total policies: 44');
    console.log('- Tables with RLS: 20');
    console.log('- All rowsecurity should be true');
    console.log('');
}

async function main() {
    console.log('🚀 Supabase RLS Policies Migration Verification');
    console.log('===============================================');
    console.log('Target: SnappyCards NEW Project (aeijlzokobuqcyznljvn)');
    console.log('Date:', new Date().toISOString());
    console.log('');

    const connected = await testConnection();
    if (!connected) {
        console.log('❌ Connection failed. Cannot proceed with verification.');
        return;
    }

    console.log('');
    await checkTables();
    await testRLSStatus();
    await testAuthenticatedAccess();
    
    generateExecutionInstructions();
    
    console.log('🏁 Verification Complete');
    console.log('Please proceed with manual execution via Supabase Dashboard.');
}

if (require.main === module) {
    main().catch(console.error);
}