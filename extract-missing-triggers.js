#!/usr/bin/env node

/**
 * Extract Missing Triggers from OLD Supabase Project
 * Based on audit findings, we need to extract these 2 triggers:
 * - on_auth_user_created (on users table)
 * - update_user_profiles_updated_at (on user_profiles table)
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

async function extractMissingTriggers() {
    console.log('⚡ Extracting Missing Triggers from OLD Project');
    console.log('==============================================');
    
    const missingTriggers = [
        { name: 'on_auth_user_created', table: 'users' },
        { name: 'update_user_profiles_updated_at', table: 'user_profiles' }
    ];
    
    let migrationSQL = `-- MISSING TRIGGERS MIGRATION SCRIPT
-- Generated: ${new Date().toISOString()}
-- Source: ${OLD_PROJECT_ID}
-- Target: NEW project

`;

    for (const trigger of missingTriggers) {
        console.log(`📋 Extracting trigger: ${trigger.name} on ${trigger.table}`);
        
        // Get trigger definition
        const triggerSQL = `
            SELECT 
                t.trigger_name,
                t.event_manipulation,
                t.event_object_schema,
                t.event_object_table,
                t.action_timing,
                t.action_condition,
                t.action_statement
            FROM information_schema.triggers t
            WHERE t.trigger_name = '${trigger.name}'
            AND t.event_object_table = '${trigger.table}';
        `;
        
        const result = await executeSQL(OLD_PROJECT_ID, triggerSQL);
        
        if (result.error) {
            console.log(`   ❌ Failed to extract ${trigger.name}: ${result.error}`);
            migrationSQL += `-- FAILED TO EXTRACT: ${trigger.name}\n-- Error: ${result.error}\n\n`;
        } else if (result.length > 0) {
            console.log(`   ✅ Successfully extracted ${trigger.name}`);
            const triggerInfo = result[0];
            
            migrationSQL += `-- Trigger: ${trigger.name} on ${trigger.table}\n`;
            migrationSQL += `CREATE OR REPLACE TRIGGER ${triggerInfo.trigger_name}\n`;
            migrationSQL += `  ${triggerInfo.action_timing} ${triggerInfo.event_manipulation}\n`;
            migrationSQL += `  ON ${triggerInfo.event_object_schema}.${triggerInfo.event_object_table}\n`;
            migrationSQL += `  FOR EACH ROW\n`;
            if (triggerInfo.action_condition) {
                migrationSQL += `  WHEN (${triggerInfo.action_condition})\n`;
            }
            migrationSQL += `  ${triggerInfo.action_statement};\n\n`;
        } else {
            console.log(`   ⚠️ Trigger ${trigger.name} not found`);
            migrationSQL += `-- Trigger ${trigger.name} not found in OLD project\n\n`;
        }
    }
    
    // Also extract any trigger functions that might be needed
    console.log('📋 Extracting related trigger functions...');
    
    const triggerFunctionsSQL = `
        SELECT 
            n.nspname as schema_name,
            p.proname as function_name,
            pg_get_functiondef(p.oid) as definition
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname IN ('public', 'auth')
        AND (p.proname LIKE '%trigger%' OR p.proname LIKE '%handle_%' OR p.proname LIKE '%updated_at%')
        ORDER BY n.nspname, p.proname;
    `;
    
    const functionsResult = await executeSQL(OLD_PROJECT_ID, triggerFunctionsSQL);
    
    if (!functionsResult.error && functionsResult.length > 0) {
        migrationSQL += `-- TRIGGER-RELATED FUNCTIONS\n`;
        migrationSQL += `-- ===========================\n\n`;
        
        for (const func of functionsResult) {
            console.log(`   📋 Found trigger function: ${func.schema_name}.${func.function_name}`);
            migrationSQL += `-- Function: ${func.schema_name}.${func.function_name}\n`;
            migrationSQL += `${func.definition};\n\n`;
        }
    }
    
    // Save to file
    await fs.writeFile(
        '/Volumes/PASSPORT/TELJES/IT/CURSOR/SNAPPYCARDS/migrate-missing-triggers.sql',
        migrationSQL
    );
    
    console.log('');
    console.log('✅ Trigger extraction complete');
    console.log('📝 Generated: migrate-missing-triggers.sql');
}

if (require.main === module) {
    extractMissingTriggers().then(() => {
        console.log('🏁 Trigger extraction completed');
        process.exit(0);
    }).catch((error) => {
        console.error('💥 Trigger extraction failed:', error.message);
        process.exit(1);
    });
}

module.exports = { extractMissingTriggers };