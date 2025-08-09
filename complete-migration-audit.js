#!/usr/bin/env node

/**
 * COMPLETE MIGRATION AUDIT - SnappyCards Database Analysis
 * 
 * This script performs a comprehensive audit of both Supabase projects:
 * - OLD: ycxqxdhaxehspypqbnpi.supabase.co (has data, auth crashed)
 * - NEW: aeijlzokobuqcyznljvn.supabase.co (clean auth, minimal data)
 * 
 * AUDIT SCOPE:
 * 1. Complete table inventory with row counts
 * 2. Database functions extraction and comparison
 * 3. Triggers and views analysis
 * 4. RLS policies comparison
 * 5. Data analysis and dependencies
 * 6. Storage buckets and edge functions
 */

const https = require('https');
const fs = require('fs').promises;

// Configuration
const PERSONAL_ACCESS_TOKEN = 'sbp_6d50add440dc1960b3efbd639d932f4b42ece0f2';
const OLD_PROJECT_ID = 'ycxqxdhaxehspypqbnpi';
const NEW_PROJECT_ID = 'aeijlzokobuqcyznljvn';
const SUPABASE_API_BASE = 'https://api.supabase.com/v1';

// Results storage
const auditResults = {
    timestamp: new Date().toISOString(),
    projects: {
        old: { id: OLD_PROJECT_ID, url: `${OLD_PROJECT_ID}.supabase.co` },
        new: { id: NEW_PROJECT_ID, url: `${NEW_PROJECT_ID}.supabase.co` }
    },
    tables: { old: {}, new: {}, comparison: {} },
    functions: { old: [], new: [], missing: [] },
    triggers: { old: [], new: [], missing: [] },
    views: { old: [], new: [], missing: [] },
    policies: { old: [], new: [], missing: [] },
    storage: { old: [], new: [] },
    edgeFunctions: { old: [], new: [] },
    analysis: {
        dataIntegrity: {},
        dependencies: {},
        priorities: {}
    }
};

/**
 * Make HTTP request to Supabase API
 */
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
                    console.error(`❌ JSON parse error for ${url}:`, error.message);
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

/**
 * Execute SQL query on a project
 */
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
        console.error(`❌ SQL execution failed for ${projectId}: ${sql.substring(0, 100)}...`);
        console.error(`   Error: ${error.message}`);
        return { error: error.message };
    }
}

/**
 * Get complete table inventory with detailed information
 */
async function getCompleteTableInventory(projectId) {
    console.log(`📊 Analyzing table inventory for project ${projectId}...`);
    
    // Get all tables including system tables
    const tablesSQL = `
        SELECT 
            schemaname,
            tablename,
            tableowner,
            hasindexes,
            hasrules,
            hastriggers
        FROM pg_tables 
        WHERE schemaname IN ('public', 'auth', 'storage', 'realtime')
        ORDER BY schemaname, tablename;
    `;
    
    const tablesResult = await executeSQL(projectId, tablesSQL);
    if (tablesResult.error) {
        return { error: tablesResult.error };
    }
    
    const tables = {};
    
    for (const table of tablesResult) {
        const tableName = `${table.schemaname}.${table.tablename}`;
        
        // Get row count
        const countSQL = `SELECT COUNT(*) as count FROM ${tableName};`;
        const countResult = await executeSQL(projectId, countSQL);
        const rowCount = countResult.error ? 'ERROR' : (countResult[0]?.count || 0);
        
        // Get table schema
        const schemaSQL = `
            SELECT 
                column_name,
                data_type,
                is_nullable,
                column_default,
                character_maximum_length
            FROM information_schema.columns 
            WHERE table_schema = '${table.schemaname}' 
            AND table_name = '${table.tablename}'
            ORDER BY ordinal_position;
        `;
        
        const schemaResult = await executeSQL(projectId, schemaSQL);
        const schema = schemaResult.error ? [] : schemaResult;
        
        tables[tableName] = {
            schema: table.schemaname,
            name: table.tablename,
            owner: table.tableowner,
            hasIndexes: table.hasindexes,
            hasRules: table.hasrules,
            hasTriggers: table.hastriggers,
            rowCount: rowCount,
            columns: schema
        };
    }
    
    return tables;
}

/**
 * Get all database functions
 */
async function getDatabaseFunctions(projectId) {
    console.log(`🔧 Analyzing database functions for project ${projectId}...`);
    
    const functionsSQL = `
        SELECT 
            n.nspname as schema_name,
            p.proname as function_name,
            pg_get_function_result(p.oid) as return_type,
            pg_get_function_arguments(p.oid) as arguments,
            pg_get_functiondef(p.oid) as definition,
            l.lanname as language
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        JOIN pg_language l ON p.prolang = l.oid
        WHERE n.nspname IN ('public', 'auth', 'storage')
        ORDER BY n.nspname, p.proname;
    `;
    
    const result = await executeSQL(projectId, functionsSQL);
    return result.error ? [] : result;
}

/**
 * Get all triggers
 */
async function getTriggers(projectId) {
    console.log(`⚡ Analyzing triggers for project ${projectId}...`);
    
    const triggersSQL = `
        SELECT 
            t.trigger_name,
            t.event_manipulation,
            t.event_object_schema,
            t.event_object_table,
            t.trigger_schema,
            t.action_timing,
            t.action_condition,
            t.action_statement
        FROM information_schema.triggers t
        WHERE t.trigger_schema IN ('public', 'auth', 'storage')
        ORDER BY t.event_object_schema, t.event_object_table, t.trigger_name;
    `;
    
    const result = await executeSQL(projectId, triggersSQL);
    return result.error ? [] : result;
}

/**
 * Get all views
 */
async function getViews(projectId) {
    console.log(`👁️ Analyzing views for project ${projectId}...`);
    
    const viewsSQL = `
        SELECT 
            table_schema,
            table_name,
            view_definition
        FROM information_schema.views
        WHERE table_schema IN ('public', 'auth', 'storage')
        ORDER BY table_schema, table_name;
    `;
    
    const result = await executeSQL(projectId, viewsSQL);
    return result.error ? [] : result;
}

/**
 * Get all RLS policies
 */
async function getRLSPolicies(projectId) {
    console.log(`🔒 Analyzing RLS policies for project ${projectId}...`);
    
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
    
    const result = await executeSQL(projectId, policiesSQL);
    return result.error ? [] : result;
}

/**
 * Get storage buckets
 */
async function getStorageBuckets(projectId) {
    console.log(`🗄️ Analyzing storage buckets for project ${projectId}...`);
    
    const bucketsSQL = `
        SELECT 
            id,
            name,
            owner,
            public,
            avif_autodetection,
            file_size_limit,
            allowed_mime_types,
            created_at,
            updated_at
        FROM storage.buckets
        ORDER BY name;
    `;
    
    const result = await executeSQL(projectId, bucketsSQL);
    return result.error ? [] : result;
}

/**
 * Get edge functions (via API)
 */
async function getEdgeFunctions(projectId) {
    console.log(`⚡ Checking edge functions for project ${projectId}...`);
    
    const url = `${SUPABASE_API_BASE}/projects/${projectId}/functions`;
    
    try {
        const result = await makeRequest(url);
        return result.error ? [] : (result.functions || result);
    } catch (error) {
        console.error(`❌ Failed to get edge functions: ${error.message}`);
        return [];
    }
}

/**
 * Analyze data dependencies and foreign keys
 */
async function analyzeDataDependencies(projectId) {
    console.log(`🔗 Analyzing data dependencies for project ${projectId}...`);
    
    const fkSQL = `
        SELECT
            tc.table_schema,
            tc.constraint_name,
            tc.table_name,
            kcu.column_name,
            ccu.table_schema AS foreign_table_schema,
            ccu.table_name AS foreign_table_name,
            ccu.column_name AS foreign_column_name
        FROM information_schema.table_constraints AS tc
        JOIN information_schema.key_column_usage AS kcu
            ON tc.constraint_name = kcu.constraint_name
            AND tc.table_schema = kcu.table_schema
        JOIN information_schema.constraint_column_usage AS ccu
            ON ccu.constraint_name = tc.constraint_name
            AND ccu.table_schema = tc.table_schema
        WHERE tc.constraint_type = 'FOREIGN KEY'
        AND tc.table_schema = 'public'
        ORDER BY tc.table_name, tc.constraint_name;
    `;
    
    const result = await executeSQL(projectId, fkSQL);
    return result.error ? [] : result;
}

/**
 * Compare two objects and find differences
 */
function compareObjects(obj1, obj2, path = '') {
    const differences = [];
    
    const keys1 = Object.keys(obj1 || {});
    const keys2 = Object.keys(obj2 || {});
    const allKeys = [...new Set([...keys1, ...keys2])];
    
    for (const key of allKeys) {
        const currentPath = path ? `${path}.${key}` : key;
        
        if (!(key in obj1)) {
            differences.push({ type: 'missing_in_old', path: currentPath, value: obj2[key] });
        } else if (!(key in obj2)) {
            differences.push({ type: 'missing_in_new', path: currentPath, value: obj1[key] });
        } else if (typeof obj1[key] === 'object' && typeof obj2[key] === 'object') {
            differences.push(...compareObjects(obj1[key], obj2[key], currentPath));
        } else if (obj1[key] !== obj2[key]) {
            differences.push({
                type: 'different',
                path: currentPath,
                oldValue: obj1[key],
                newValue: obj2[key]
            });
        }
    }
    
    return differences;
}

/**
 * Generate migration priority analysis
 */
function generateMigrationPriorities(auditResults) {
    const priorities = {
        critical: [],
        high: [],
        medium: [],
        low: []
    };
    
    // Analyze table data
    for (const [tableName, oldTable] of Object.entries(auditResults.tables.old)) {
        const newTable = auditResults.tables.new[tableName];
        const rowCount = typeof oldTable.rowCount === 'number' ? oldTable.rowCount : 0;
        
        if (!newTable) {
            if (rowCount > 0) {
                priorities.critical.push({
                    type: 'missing_table',
                    name: tableName,
                    reason: `Table missing in NEW project with ${rowCount} rows of data`,
                    action: 'Create table and migrate data'
                });
            } else {
                priorities.medium.push({
                    type: 'missing_empty_table',
                    name: tableName,
                    reason: 'Table missing but has no data',
                    action: 'Create table structure'
                });
            }
        } else if (rowCount > 0 && (!newTable.rowCount || newTable.rowCount === 0)) {
            priorities.high.push({
                type: 'missing_data',
                name: tableName,
                reason: `Table exists but missing ${rowCount} rows of data`,
                action: 'Migrate data'
            });
        }
    }
    
    // Analyze functions
    auditResults.functions.missing.forEach(func => {
        if (func.schema_name === 'public') {
            priorities.high.push({
                type: 'missing_function',
                name: `${func.schema_name}.${func.function_name}`,
                reason: 'Custom function missing in NEW project',
                action: 'Create function'
            });
        } else {
            priorities.medium.push({
                type: 'missing_system_function',
                name: `${func.schema_name}.${func.function_name}`,
                reason: 'System function missing',
                action: 'Review if needed'
            });
        }
    });
    
    // Analyze triggers
    auditResults.triggers.missing.forEach(trigger => {
        priorities.high.push({
            type: 'missing_trigger',
            name: trigger.trigger_name,
            reason: `Trigger missing on ${trigger.event_object_table}`,
            action: 'Create trigger'
        });
    });
    
    // Analyze RLS policies
    auditResults.policies.missing.forEach(policy => {
        priorities.critical.push({
            type: 'missing_rls_policy',
            name: policy.policyname,
            reason: `RLS policy missing on ${policy.tablename}`,
            action: 'Create security policy'
        });
    });
    
    return priorities;
}

/**
 * Generate detailed report
 */
async function generateReport(auditResults) {
    const report = {
        summary: {
            timestamp: auditResults.timestamp,
            projects: auditResults.projects,
            totalTables: {
                old: Object.keys(auditResults.tables.old).length,
                new: Object.keys(auditResults.tables.new).length
            },
            totalFunctions: {
                old: auditResults.functions.old.length,
                new: auditResults.functions.new.length,
                missing: auditResults.functions.missing.length
            },
            totalTriggers: {
                old: auditResults.triggers.old.length,
                new: auditResults.triggers.new.length,
                missing: auditResults.triggers.missing.length
            },
            totalPolicies: {
                old: auditResults.policies.old.length,
                new: auditResults.policies.new.length,
                missing: auditResults.policies.missing.length
            }
        },
        details: auditResults,
        priorities: generateMigrationPriorities(auditResults)
    };
    
    // Write detailed JSON report
    await fs.writeFile(
        '/Volumes/PASSPORT/TELJES/IT/CURSOR/SNAPPYCARDS/COMPLETE_MIGRATION_AUDIT.json',
        JSON.stringify(report, null, 2)
    );
    
    // Write human-readable summary
    let summary = '';
    summary += '# COMPLETE MIGRATION AUDIT REPORT\n';
    summary += `Generated: ${report.summary.timestamp}\n\n`;
    
    summary += '## PROJECT INFORMATION\n';
    summary += `OLD PROJECT: ${report.summary.projects.old.id} (${report.summary.projects.old.url})\n`;
    summary += `NEW PROJECT: ${report.summary.projects.new.id} (${report.summary.projects.new.url})\n\n`;
    
    summary += '## SUMMARY STATISTICS\n';
    summary += `Tables: ${report.summary.totalTables.old} (OLD) → ${report.summary.totalTables.new} (NEW)\n`;
    summary += `Functions: ${report.summary.totalFunctions.old} (OLD) → ${report.summary.totalFunctions.new} (NEW) | Missing: ${report.summary.totalFunctions.missing}\n`;
    summary += `Triggers: ${report.summary.totalTriggers.old} (OLD) → ${report.summary.totalTriggers.new} (NEW) | Missing: ${report.summary.totalTriggers.missing}\n`;
    summary += `RLS Policies: ${report.summary.totalPolicies.old} (OLD) → ${report.summary.totalPolicies.new} (NEW) | Missing: ${report.summary.totalPolicies.missing}\n\n`;
    
    summary += '## MIGRATION PRIORITIES\n\n';
    
    ['critical', 'high', 'medium', 'low'].forEach(level => {
        if (report.priorities[level].length > 0) {
            summary += `### ${level.toUpperCase()} PRIORITY (${report.priorities[level].length} items)\n`;
            report.priorities[level].forEach(item => {
                summary += `- **${item.name}**: ${item.reason}\n`;
                summary += `  Action: ${item.action}\n\n`;
            });
        }
    });
    
    summary += '## DETAILED TABLE COMPARISON\n\n';
    
    // Table comparison
    for (const [tableName, oldTable] of Object.entries(auditResults.tables.old)) {
        const newTable = auditResults.tables.new[tableName];
        summary += `### ${tableName}\n`;
        summary += `OLD: ${oldTable.rowCount} rows | NEW: ${newTable ? newTable.rowCount : 'MISSING'} rows\n`;
        
        if (!newTable) {
            summary += `⚠️ **MISSING IN NEW PROJECT**\n`;
        } else if (oldTable.rowCount !== newTable.rowCount) {
            summary += `⚠️ **ROW COUNT MISMATCH**\n`;
        } else {
            summary += `✅ **SYNCHRONIZED**\n`;
        }
        summary += '\n';
    }
    
    await fs.writeFile(
        '/Volumes/PASSPORT/TELJES/IT/CURSOR/SNAPPYCARDS/MIGRATION_AUDIT_SUMMARY.md',
        summary
    );
    
    return report;
}

/**
 * Main audit function
 */
async function executeCompleteAudit() {
    console.log('🎯 COMPLETE MIGRATION AUDIT - SnappyCards');
    console.log('==========================================');
    console.log(`🔍 Analyzing OLD project: ${OLD_PROJECT_ID}`);
    console.log(`🔍 Analyzing NEW project: ${NEW_PROJECT_ID}`);
    console.log('');
    
    try {
        // 1. Complete table inventory
        console.log('📊 STEP 1: Complete Table Inventory');
        console.log('-----------------------------------');
        auditResults.tables.old = await getCompleteTableInventory(OLD_PROJECT_ID);
        auditResults.tables.new = await getCompleteTableInventory(NEW_PROJECT_ID);
        
        // Compare tables
        auditResults.tables.comparison = compareObjects(auditResults.tables.old, auditResults.tables.new);
        console.log(`✅ Found ${Object.keys(auditResults.tables.old).length} tables in OLD project`);
        console.log(`✅ Found ${Object.keys(auditResults.tables.new).length} tables in NEW project`);
        console.log('');
        
        // 2. Database functions
        console.log('🔧 STEP 2: Database Functions Analysis');
        console.log('-------------------------------------');
        auditResults.functions.old = await getDatabaseFunctions(OLD_PROJECT_ID);
        auditResults.functions.new = await getDatabaseFunctions(NEW_PROJECT_ID);
        
        // Find missing functions
        auditResults.functions.missing = auditResults.functions.old.filter(oldFunc => 
            !auditResults.functions.new.some(newFunc => 
                newFunc.schema_name === oldFunc.schema_name && 
                newFunc.function_name === oldFunc.function_name
            )
        );
        
        console.log(`✅ Found ${auditResults.functions.old.length} functions in OLD project`);
        console.log(`✅ Found ${auditResults.functions.new.length} functions in NEW project`);
        console.log(`⚠️ ${auditResults.functions.missing.length} functions missing in NEW project`);
        console.log('');
        
        // 3. Triggers analysis
        console.log('⚡ STEP 3: Triggers Analysis');
        console.log('---------------------------');
        auditResults.triggers.old = await getTriggers(OLD_PROJECT_ID);
        auditResults.triggers.new = await getTriggers(NEW_PROJECT_ID);
        
        // Find missing triggers
        auditResults.triggers.missing = auditResults.triggers.old.filter(oldTrigger => 
            !auditResults.triggers.new.some(newTrigger => 
                newTrigger.trigger_name === oldTrigger.trigger_name &&
                newTrigger.event_object_table === oldTrigger.event_object_table
            )
        );
        
        console.log(`✅ Found ${auditResults.triggers.old.length} triggers in OLD project`);
        console.log(`✅ Found ${auditResults.triggers.new.length} triggers in NEW project`);
        console.log(`⚠️ ${auditResults.triggers.missing.length} triggers missing in NEW project`);
        console.log('');
        
        // 4. Views analysis
        console.log('👁️ STEP 4: Views Analysis');
        console.log('-------------------------');
        auditResults.views.old = await getViews(OLD_PROJECT_ID);
        auditResults.views.new = await getViews(NEW_PROJECT_ID);
        
        // Find missing views
        auditResults.views.missing = auditResults.views.old.filter(oldView => 
            !auditResults.views.new.some(newView => 
                newView.table_schema === oldView.table_schema &&
                newView.table_name === oldView.table_name
            )
        );
        
        console.log(`✅ Found ${auditResults.views.old.length} views in OLD project`);
        console.log(`✅ Found ${auditResults.views.new.length} views in NEW project`);
        console.log(`⚠️ ${auditResults.views.missing.length} views missing in NEW project`);
        console.log('');
        
        // 5. RLS policies analysis
        console.log('🔒 STEP 5: RLS Policies Analysis');
        console.log('--------------------------------');
        auditResults.policies.old = await getRLSPolicies(OLD_PROJECT_ID);
        auditResults.policies.new = await getRLSPolicies(NEW_PROJECT_ID);
        
        // Find missing policies
        auditResults.policies.missing = auditResults.policies.old.filter(oldPolicy => 
            !auditResults.policies.new.some(newPolicy => 
                newPolicy.schemaname === oldPolicy.schemaname &&
                newPolicy.tablename === oldPolicy.tablename &&
                newPolicy.policyname === oldPolicy.policyname
            )
        );
        
        console.log(`✅ Found ${auditResults.policies.old.length} RLS policies in OLD project`);
        console.log(`✅ Found ${auditResults.policies.new.length} RLS policies in NEW project`);
        console.log(`⚠️ ${auditResults.policies.missing.length} RLS policies missing in NEW project`);
        console.log('');
        
        // 6. Storage and edge functions
        console.log('🗄️ STEP 6: Storage & Edge Functions');
        console.log('-----------------------------------');
        auditResults.storage.old = await getStorageBuckets(OLD_PROJECT_ID);
        auditResults.storage.new = await getStorageBuckets(NEW_PROJECT_ID);
        auditResults.edgeFunctions.old = await getEdgeFunctions(OLD_PROJECT_ID);
        auditResults.edgeFunctions.new = await getEdgeFunctions(NEW_PROJECT_ID);
        
        console.log(`✅ Found ${auditResults.storage.old.length} storage buckets in OLD project`);
        console.log(`✅ Found ${auditResults.storage.new.length} storage buckets in NEW project`);
        console.log(`✅ Found ${auditResults.edgeFunctions.old.length} edge functions in OLD project`);
        console.log(`✅ Found ${auditResults.edgeFunctions.new.length} edge functions in NEW project`);
        console.log('');
        
        // 7. Data dependencies analysis
        console.log('🔗 STEP 7: Data Dependencies Analysis');
        console.log('------------------------------------');
        auditResults.analysis.dependencies.old = await analyzeDataDependencies(OLD_PROJECT_ID);
        auditResults.analysis.dependencies.new = await analyzeDataDependencies(NEW_PROJECT_ID);
        
        console.log(`✅ Analyzed foreign key dependencies`);
        console.log('');
        
        // 8. Generate comprehensive report
        console.log('📋 STEP 8: Generating Comprehensive Report');
        console.log('-----------------------------------------');
        const report = await generateReport(auditResults);
        
        console.log('✅ Generated COMPLETE_MIGRATION_AUDIT.json');
        console.log('✅ Generated MIGRATION_AUDIT_SUMMARY.md');
        console.log('');
        
        // 9. Summary
        console.log('🎉 AUDIT COMPLETED SUCCESSFULLY');
        console.log('===============================');
        console.log('📊 Summary of findings:');
        console.log(`   Tables: ${Object.keys(auditResults.tables.old).length} → ${Object.keys(auditResults.tables.new).length}`);
        console.log(`   Functions: ${auditResults.functions.missing.length} missing`);
        console.log(`   Triggers: ${auditResults.triggers.missing.length} missing`);
        console.log(`   RLS Policies: ${auditResults.policies.missing.length} missing`);
        console.log(`   Views: ${auditResults.views.missing.length} missing`);
        console.log('');
        console.log('🚨 CRITICAL ITEMS:');
        const criticalItems = report.priorities.critical.length;
        const highItems = report.priorities.high.length;
        console.log(`   ${criticalItems} Critical priority items`);
        console.log(`   ${highItems} High priority items`);
        console.log('');
        console.log('📋 Next Steps:');
        console.log('1. Review MIGRATION_AUDIT_SUMMARY.md for human-readable analysis');
        console.log('2. Check COMPLETE_MIGRATION_AUDIT.json for detailed technical data');
        console.log('3. Address critical and high priority items first');
        console.log('4. Create migration scripts for missing components');
        console.log('5. Validate data integrity after migration');
        
        return report;
        
    } catch (error) {
        console.error('💥 AUDIT FAILED:', error.message);
        console.error('Stack trace:', error.stack);
        throw error;
    }
}

// Run the audit
if (require.main === module) {
    executeCompleteAudit().then((report) => {
        console.log('🏁 Complete migration audit finished successfully');
        process.exit(0);
    }).catch((error) => {
        console.error('💥 Audit script failed:', error.message);
        process.exit(1);
    });
}

module.exports = { executeCompleteAudit, auditResults };