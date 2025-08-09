#!/usr/bin/env node

/**
 * Extract Missing Functions from OLD Supabase Project
 * Based on audit findings, we need to extract these 4 functions:
 * - public.create_classroom
 * - public.generate_invite_code  
 * - public.handle_new_user
 * - public.join_classroom_with_code
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

async function extractMissingFunctions() {
    console.log('🔧 Extracting Missing Functions from OLD Project');
    console.log('==============================================');
    
    const missingFunctions = [
        'create_classroom',
        'generate_invite_code', 
        'handle_new_user',
        'join_classroom_with_code'
    ];
    
    let migrationSQL = `-- MISSING FUNCTIONS MIGRATION SCRIPT
-- Generated: ${new Date().toISOString()}
-- Source: ${OLD_PROJECT_ID}
-- Target: NEW project

`;

    for (const functionName of missingFunctions) {
        console.log(`📋 Extracting function: ${functionName}`);
        
        const sql = `
            SELECT 
                pg_get_functiondef(p.oid) as definition
            FROM pg_proc p
            JOIN pg_namespace n ON p.pronamespace = n.oid
            WHERE n.nspname = 'public'
            AND p.proname = '${functionName}';
        `;
        
        const result = await executeSQL(OLD_PROJECT_ID, sql);
        
        if (result.error) {
            console.log(`   ❌ Failed to extract ${functionName}: ${result.error}`);
            migrationSQL += `-- FAILED TO EXTRACT: ${functionName}\n-- Error: ${result.error}\n\n`;
        } else if (result.length > 0) {
            console.log(`   ✅ Successfully extracted ${functionName}`);
            migrationSQL += `-- Function: ${functionName}\n`;
            migrationSQL += `${result[0].definition};\n\n`;
        } else {
            console.log(`   ⚠️ Function ${functionName} not found`);
            migrationSQL += `-- Function ${functionName} not found in OLD project\n\n`;
        }
    }
    
    // Save to file
    await fs.writeFile(
        '/Volumes/PASSPORT/TELJES/IT/CURSOR/SNAPPYCARDS/migrate-missing-functions.sql',
        migrationSQL
    );
    
    console.log('');
    console.log('✅ Function extraction complete');
    console.log('📝 Generated: migrate-missing-functions.sql');
}

if (require.main === module) {
    extractMissingFunctions().then(() => {
        console.log('🏁 Function extraction completed');
        process.exit(0);
    }).catch((error) => {
        console.error('💥 Function extraction failed:', error.message);
        process.exit(1);
    });
}

module.exports = { extractMissingFunctions };