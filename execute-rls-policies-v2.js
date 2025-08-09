#!/usr/bin/env node

/**
 * Execute RLS Policies Migration Script - Version 2
 * Creates a detailed execution plan and attempts to execute via Supabase Dashboard approach
 */

const fs = require('fs');
const path = require('path');

// NEW Project Configuration
const SUPABASE_URL = 'https://aeijlzokobuqcyznljvn.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFlaWpsem9rb2J1cWN5em5sanZuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ1NjYwNTYsImV4cCI6MjA3MDE0MjA1Nn0.Kva8czOdONqJp2512w_94dcRq8ZPkYOnLT9oRsldmJM';

async function main() {
    console.log('🚀 RLS Policies Migration Analysis');
    console.log('===================================');
    console.log('Target Project:', SUPABASE_URL);
    console.log('Project ID: aeijlzokobuqcyznljvn');
    console.log('');

    // Read the migration file
    const migrationFile = path.join(__dirname, 'migrate-all-rls-policies.sql');
    
    if (!fs.existsSync(migrationFile)) {
        console.error('❌ Migration file not found:', migrationFile);
        process.exit(1);
    }

    const sqlContent = fs.readFileSync(migrationFile, 'utf8');
    const lines = sqlContent.split('\n');
    
    console.log('📄 Migration File Analysis:');
    console.log('- Total lines:', lines.length);
    console.log('- File size:', Math.round(sqlContent.length / 1024), 'KB');
    console.log('');

    // Count different types of statements
    let enableRLSCount = 0;
    let createPolicyCount = 0;
    let commentCount = 0;
    let verificationCount = 0;

    const tables = new Set();
    const schemas = new Set();

    lines.forEach(line => {
        const trimmed = line.trim();
        if (trimmed.startsWith('--')) {
            commentCount++;
        } else if (trimmed.includes('ENABLE ROW LEVEL SECURITY')) {
            enableRLSCount++;
            // Extract table name
            const match = trimmed.match(/ALTER TABLE (\w+\.\w+)/);
            if (match) {
                const fullTable = match[1];
                const [schema, table] = fullTable.split('.');
                tables.add(fullTable);
                schemas.add(schema);
            }
        } else if (trimmed.startsWith('CREATE POLICY')) {
            createPolicyCount++;
            // Extract table name from policy
            const match = trimmed.match(/ON (\w+\.\w+)/);
            if (match) {
                tables.add(match[1]);
                schemas.add(match[1].split('.')[0]);
            }
        } else if (trimmed.startsWith('SELECT') && trimmed.includes('pg_policies')) {
            verificationCount++;
        }
    });

    console.log('📊 Statement Analysis:');
    console.log('- ENABLE ROW LEVEL SECURITY statements:', enableRLSCount);
    console.log('- CREATE POLICY statements:', createPolicyCount);
    console.log('- Comment lines:', commentCount);
    console.log('- Verification queries:', verificationCount);
    console.log('');

    console.log('📋 Tables to be secured:');
    Array.from(tables).sort().forEach(table => {
        console.log('  -', table);
    });
    console.log('');

    console.log('📦 Schemas affected:');
    Array.from(schemas).sort().forEach(schema => {
        console.log('  -', schema);
    });
    console.log('');

    // Extract verification queries
    const verificationQueries = [];
    let inVerificationSection = false;
    
    lines.forEach(line => {
        const trimmed = line.trim();
        if (trimmed.includes('VERIFICATION QUERIES')) {
            inVerificationSection = true;
        } else if (inVerificationSection && trimmed.startsWith('SELECT')) {
            let query = trimmed;
            // Handle multi-line queries
            const nextLines = lines.slice(lines.indexOf(line) + 1);
            for (const nextLine of nextLines) {
                const nextTrimmed = nextLine.trim();
                if (nextTrimmed && !nextTrimmed.startsWith('--') && !nextTrimmed.startsWith('SELECT')) {
                    query += ' ' + nextTrimmed;
                } else {
                    break;
                }
            }
            if (query.endsWith(';')) {
                query = query.slice(0, -1);
            }
            verificationQueries.push(query);
        }
    });

    console.log('🔍 Verification Queries Found:');
    verificationQueries.forEach((query, i) => {
        console.log(`  ${i + 1}. ${query.substring(0, 100)}${query.length > 100 ? '...' : ''}`);
    });
    console.log('');

    console.log('⚠️  EXECUTION REQUIREMENTS:');
    console.log('============================');
    console.log('❗ RLS Policy creation requires SERVICE_ROLE key');
    console.log('❗ ANON key cannot create policies (insufficient privileges)');
    console.log('');

    console.log('🎯 RECOMMENDED EXECUTION METHODS:');
    console.log('==================================');
    console.log('');
    console.log('METHOD 1: Supabase Dashboard (RECOMMENDED)');
    console.log('------------------------------------------');
    console.log('1. Go to:', SUPABASE_URL.replace('//', '//dashboard.'));
    console.log('2. Navigate to: SQL Editor');
    console.log('3. Copy the entire content of migrate-all-rls-policies.sql');
    console.log('4. Paste and execute');
    console.log('5. Dashboard has service_role permissions automatically');
    console.log('');
    
    console.log('METHOD 2: Service Role Key');
    console.log('-------------------------');
    console.log('1. Get service_role key from Dashboard → Settings → API');
    console.log('2. Replace SUPABASE_ANON_KEY with service_role key in this script');
    console.log('3. Re-run this script');
    console.log('');

    console.log('METHOD 3: Supabase CLI (if configured)');
    console.log('--------------------------------------');
    console.log('1. supabase login');
    console.log('2. supabase link --project-ref aeijlzokobuqcyznljvn');
    console.log('3. supabase db push --schema auth,public,storage');
    console.log('');

    console.log('📋 POST-EXECUTION VERIFICATION:');
    console.log('===============================');
    console.log('After executing the policies, run these queries to verify:');
    console.log('');
    verificationQueries.forEach((query, i) => {
        console.log(`${i + 1}. ${query};`);
        console.log('');
    });

    console.log('🎯 EXPECTED RESULTS:');
    console.log('====================');
    console.log('- Total policies should be: 44');
    console.log('- Tables with RLS enabled:', enableRLSCount);
    console.log('- Schemas: auth, public, storage');
    console.log('');

    console.log('✅ Analysis Complete!');
    console.log('Ready to execute via Supabase Dashboard SQL Editor.');
}

if (require.main === module) {
    main().catch(console.error);
}