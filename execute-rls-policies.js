#!/usr/bin/env node

/**
 * Execute RLS Policies Migration Script
 * Connects to the NEW Supabase project and executes all RLS policies
 */

const fs = require('fs');
const path = require('path');

// NEW Project Configuration
const SUPABASE_URL = 'https://aeijlzokobuqcyznljvn.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFlaWpsem9rb2J1cWN5em5sanZuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ1NjYwNTYsImV4cCI6MjA3MDE0MjA1Nn0.Kva8czOdONqJp2512w_94dcRq8ZPkYOnLT9oRsldmJM';

// NOTE: For RLS policy creation, we would need a service_role key, not anon key
// This script will attempt to use the RPC endpoint to execute SQL

async function executeSQL(sql) {
    try {
        const response = await fetch(`${SUPABASE_URL}/rest/v1/rpc/exec_sql`, {
            method: 'POST',
            headers: {
                'apikey': SUPABASE_ANON_KEY,
                'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
                'Content-Type': 'application/json',
                'Prefer': 'return=representation'
            },
            body: JSON.stringify({ sql: sql })
        });

        if (!response.ok) {
            throw new Error(`HTTP ${response.status}: ${response.statusText}`);
        }

        return await response.json();
    } catch (error) {
        console.error('❌ SQL Execution Error:', error.message);
        return { error: error.message };
    }
}

async function executeQuery(query) {
    try {
        // Try using the REST API with raw SQL via PostgREST
        const response = await fetch(`${SUPABASE_URL}/rest/v1/rpc/execute_sql`, {
            method: 'POST',
            headers: {
                'apikey': SUPABASE_ANON_KEY,
                'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ query: query })
        });

        if (!response.ok) {
            const error = await response.text();
            throw new Error(`HTTP ${response.status}: ${error}`);
        }

        return await response.json();
    } catch (error) {
        console.error('❌ Query Execution Error:', error.message);
        return { error: error.message };
    }
}

async function checkPolicyCount() {
    const query = `SELECT COUNT(*) as total_policies FROM pg_policies WHERE schemaname IN ('public', 'auth', 'storage')`;
    console.log('🔍 Checking current policy count...');
    
    try {
        // Try direct REST query
        const response = await fetch(`${SUPABASE_URL}/rest/v1/rpc/policy_count`, {
            method: 'POST',
            headers: {
                'apikey': SUPABASE_ANON_KEY,
                'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
                'Content-Type': 'application/json'
            }
        });

        if (response.ok) {
            const result = await response.json();
            console.log('📊 Current policy count:', result);
            return result;
        }
    } catch (error) {
        console.log('ℹ️ Could not execute policy count check - this requires service role permissions');
    }
    
    return null;
}

async function main() {
    console.log('🚀 Starting RLS Policies Migration');
    console.log('====================================');
    console.log('Target Project:', SUPABASE_URL);
    console.log('');

    // Read the migration file
    const migrationFile = path.join(__dirname, 'migrate-all-rls-policies.sql');
    
    if (!fs.existsSync(migrationFile)) {
        console.error('❌ Migration file not found:', migrationFile);
        process.exit(1);
    }

    const sqlContent = fs.readFileSync(migrationFile, 'utf8');
    console.log('📄 Loaded migration file with', sqlContent.split('\n').length, 'lines');

    // Check initial state
    await checkPolicyCount();

    // Split SQL into individual statements
    const statements = sqlContent
        .split(';')
        .map(stmt => stmt.trim())
        .filter(stmt => stmt && !stmt.startsWith('--') && stmt !== '');

    console.log('🔧 Found', statements.length, 'SQL statements to execute');
    console.log('');

    console.log('⚠️  WARNING: RLS Policy creation requires SERVICE_ROLE permissions');
    console.log('ℹ️  This script uses ANON key which has limited permissions');
    console.log('ℹ️  You may need to execute this script with a service_role key or use Supabase Dashboard');
    console.log('');

    // Try to execute the policies (will likely fail with anon key)
    let successCount = 0;
    let errorCount = 0;

    for (let i = 0; i < Math.min(5, statements.length); i++) { // Test first 5 statements only
        const statement = statements[i];
        console.log(`📝 Statement ${i + 1}:`, statement.substring(0, 100) + '...');
        
        const result = await executeSQL(statement);
        if (result.error) {
            console.log('❌ Failed:', result.error);
            errorCount++;
            if (result.error.includes('permission denied') || result.error.includes('insufficient_privilege')) {
                console.log('🛑 Permission denied - service_role key required');
                break;
            }
        } else {
            console.log('✅ Success');
            successCount++;
        }
        console.log('');
    }

    console.log('📊 RESULTS SUMMARY');
    console.log('==================');
    console.log('✅ Successful statements:', successCount);
    console.log('❌ Failed statements:', errorCount);
    console.log('');

    if (errorCount > 0 && errorCount === Math.min(5, statements.length)) {
        console.log('🚨 EXECUTION FAILED');
        console.log('Reason: Insufficient permissions (anon key cannot create RLS policies)');
        console.log('');
        console.log('RECOMMENDED ACTIONS:');
        console.log('1. Use Supabase Dashboard SQL Editor');
        console.log('2. Copy and paste the migrate-all-rls-policies.sql content');
        console.log('3. Execute in the Dashboard (has service_role permissions)');
        console.log('4. Or use service_role key instead of anon key');
        console.log('');
        console.log('SERVICE ROLE KEY LOCATION:');
        console.log('Supabase Dashboard → Settings → API → service_role key');
    }

    // Final policy count check
    await checkPolicyCount();
}

// Handle fetch for Node.js if not available
if (typeof fetch === 'undefined') {
    console.log('Installing node-fetch for HTTP requests...');
    try {
        const fetch = require('node-fetch');
        global.fetch = fetch;
    } catch (e) {
        console.error('❌ node-fetch not available. Please install: npm install node-fetch');
        console.log('ℹ️ Continuing without fetch - some features may not work');
    }
}

if (require.main === module) {
    main().catch(console.error);
}

module.exports = { executeSQL, checkPolicyCount };