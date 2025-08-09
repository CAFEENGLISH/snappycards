#!/usr/bin/env node

/**
 * Extract ALL Missing RLS Policies from OLD Supabase Project
 * Based on audit findings, we need to extract all 44 missing RLS policies
 */

const https = require('https');
const fs = require('fs').promises;

const PERSONAL_ACCESS_TOKEN = 'sbp_6d50add440dc1960b3efbd639d932f4b42ece0f2';
const OLD_PROJECT_ID = 'ycxqxdhaxehspypqbnpi';
const SUPABASE_API_BASE = 'https://api.supabase.com/v1';

function makeRequest(url, options = {}) {
    return new Promise((resolve, reject) => {
        const requestOptions = {
            headers: {
                'Authorization': `Bearer ${PERSONAL_ACCESS_TOKEN}`,
                'Content-Type': 'application/json',
                ...options.headers
            },
            method: options.method || 'GET'
        };

        const req = https.request(url, requestOptions, (res) => {
            let data = '';
            res.on('data', (chunk) => {
                data += chunk;
            });
            res.on('end', () => {
                try {
                    if (res.statusCode >= 200 && res.statusCode < 300) {
                        resolve(data ? JSON.parse(data) : {});
                    } else {
                        reject(new Error(`HTTP ${res.statusCode}: ${data}`));
                    }
                } catch (error) {
                    resolve({ error: error.message, rawData: data });
                }
            });
        });

        if (options.body) {
            req.write(JSON.stringify(options.body));
        }

        req.on('error', reject);
        req.end();
    });
}

async function executeSQL(projectId, sql) {
    const url = `${SUPABASE_API_BASE}/projects/${projectId}/database/query`;
    
    try {
        const result = await makeRequest(url, {
            method: 'POST',
            body: { query: sql }
        });
        
        if (result.error) {
            throw new Error(result.error);
        }
        
        return result.result || result;
    } catch (error) {
        console.error(`❌ SQL execution failed: ${error.message}`);
        return { error: error.message };
    }
}

async function extractAllRLSPolicies() {
    console.log('🔒 Extracting ALL RLS Policies from OLD Project');
    console.log('===============================================');
    
    // Get all RLS policies from OLD project
    const policiesSQL = `
        SELECT 
            schemaname,
            tablename,
            policyname,
            permissive,
            roles,
            cmd,
            qual,
            with_check
        FROM pg_policies
        WHERE schemaname IN ('public', 'auth', 'storage')
        ORDER BY schemaname, tablename, policyname;
    `;
    
    const policies = await executeSQL(OLD_PROJECT_ID, policiesSQL);
    
    if (policies.error) {
        console.error('❌ Failed to extract RLS policies:', policies.error);
        return;
    }
    
    console.log(`📊 Found ${policies.length} RLS policies in OLD project`);
    
    let migrationSQL = `-- COMPREHENSIVE RLS POLICIES MIGRATION SCRIPT
-- Generated: ${new Date().toISOString()}
-- Source: ${OLD_PROJECT_ID}
-- Target: NEW project
-- Total policies: ${policies.length}

-- WARNING: This will recreate ALL RLS policies from the OLD project
-- Make sure to backup your NEW project before running this script

`;

    // Group policies by schema and table
    const policiesByTable = {};
    
    policies.forEach(policy => {
        const tableKey = `${policy.schemaname}.${policy.tablename}`;
        if (!policiesByTable[tableKey]) {
            policiesByTable[tableKey] = [];
        }
        policiesByTable[tableKey].push(policy);
    });
    
    // Generate migration script for each table
    for (const [tableKey, tablePolicies] of Object.entries(policiesByTable)) {
        const [schema, table] = tableKey.split('.');
        
        console.log(`📋 Processing ${tablePolicies.length} policies for ${tableKey}`);
        
        migrationSQL += `-- =============================================\n`;
        migrationSQL += `-- RLS Policies for ${tableKey}\n`;
        migrationSQL += `-- =============================================\n\n`;
        
        // Enable RLS on the table first
        migrationSQL += `-- Enable RLS on ${tableKey}\n`;
        migrationSQL += `ALTER TABLE ${schema}.${table} ENABLE ROW LEVEL SECURITY;\n\n`;
        
        // Create each policy
        for (const policy of tablePolicies) {
            migrationSQL += `-- Policy: ${policy.policyname}\n`;
            
            // Build CREATE POLICY statement
            let policySQL = `CREATE POLICY "${policy.policyname}" ON ${schema}.${table}`;
            
            // Add AS clause if not permissive (restrictive)
            if (policy.permissive === 'RESTRICTIVE') {
                policySQL += ' AS RESTRICTIVE';
            }
            
            // Add FOR clause (command type)
            if (policy.cmd && policy.cmd !== 'ALL') {
                policySQL += ` FOR ${policy.cmd}`;
            }
            
            // Add TO clause (roles)
            if (policy.roles && policy.roles.length > 0) {
                const rolesList = Array.isArray(policy.roles) ? policy.roles.join(', ') : policy.roles;
                policySQL += ` TO ${rolesList}`;
            }
            
            // Add USING clause (qual - the condition for SELECT/UPDATE/DELETE)
            if (policy.qual) {
                policySQL += `\n  USING (${policy.qual})`;
            }
            
            // Add WITH CHECK clause (for INSERT/UPDATE)
            if (policy.with_check && policy.with_check !== policy.qual) {
                policySQL += `\n  WITH CHECK (${policy.with_check})`;
            }
            
            policySQL += ';\n\n';
            migrationSQL += policySQL;
        }
        
        migrationSQL += '\n';
    }
    
    // Add verification section
    migrationSQL += `-- =============================================\n`;
    migrationSQL += `-- VERIFICATION QUERIES\n`;
    migrationSQL += `-- =============================================\n\n`;
    
    migrationSQL += `-- Check total number of policies created\n`;
    migrationSQL += `SELECT COUNT(*) as total_policies FROM pg_policies WHERE schemaname IN ('public', 'auth', 'storage');\n\n`;
    
    migrationSQL += `-- Check policies by table\n`;
    migrationSQL += `SELECT schemaname, tablename, COUNT(*) as policy_count 
FROM pg_policies 
WHERE schemaname IN ('public', 'auth', 'storage')
GROUP BY schemaname, tablename 
ORDER BY schemaname, tablename;\n\n`;
    
    migrationSQL += `-- Check if RLS is enabled on all tables\n`;
    migrationSQL += `SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname IN ('public', 'auth', 'storage')
ORDER BY schemaname, tablename;\n\n`;
    
    // Save to file
    await fs.writeFile(
        '/Volumes/PASSPORT/TELJES/IT/CURSOR/SNAPPYCARDS/migrate-all-rls-policies.sql',
        migrationSQL
    );
    
    console.log('');
    console.log('✅ RLS policies extraction complete');
    console.log('📝 Generated: migrate-all-rls-policies.sql');
    console.log(`🔒 Total policies extracted: ${policies.length}`);
    console.log(`📊 Tables with policies: ${Object.keys(policiesByTable).length}`);
    
    // Also create a summary file
    let summary = `# RLS POLICIES MIGRATION SUMMARY\n\n`;
    summary += `Generated: ${new Date().toISOString()}\n`;
    summary += `Total policies: ${policies.length}\n`;
    summary += `Tables with policies: ${Object.keys(policiesByTable).length}\n\n`;
    
    summary += `## Policies by Table\n\n`;
    for (const [tableKey, tablePolicies] of Object.entries(policiesByTable)) {
        summary += `### ${tableKey} (${tablePolicies.length} policies)\n`;
        tablePolicies.forEach(policy => {
            summary += `- **${policy.policyname}** (${policy.cmd || 'ALL'})\n`;
        });
        summary += '\n';
    }
    
    await fs.writeFile(
        '/Volumes/PASSPORT/TELJES/IT/CURSOR/SNAPPYCARDS/RLS_POLICIES_SUMMARY.md',
        summary
    );
    
    console.log('📋 Generated: RLS_POLICIES_SUMMARY.md');
}

if (require.main === module) {
    extractAllRLSPolicies().then(() => {
        console.log('🏁 RLS policies extraction completed');
        process.exit(0);
    }).catch((error) => {
        console.error('💥 RLS policies extraction failed:', error.message);
        process.exit(1);
    });
}

module.exports = { extractAllRLSPolicies };