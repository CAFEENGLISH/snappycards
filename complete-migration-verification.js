#!/usr/bin/env node

/**
 * COMPLETE MIGRATION VERIFICATION SCRIPT
 * 
 * This script verifies that the migration between OLD and NEW Supabase projects
 * has been completed successfully by checking all critical components.
 */

const https = require('https');
const fs = require('fs').promises;

const PERSONAL_ACCESS_TOKEN = 'sbp_6d50add440dc1960b3efbd639d932f4b42ece0f2';
const OLD_PROJECT_ID = 'ycxqxdhaxehspypqbnpi';
const NEW_PROJECT_ID = 'aeijlzokobuqcyznljvn';
const SUPABASE_API_BASE = 'https://api.supabase.com/v1';

// Verification results
const verificationResults = {
    timestamp: new Date().toISOString(),
    projects: { old: OLD_PROJECT_ID, new: NEW_PROJECT_ID },
    tables: { status: 'pending', details: {} },
    functions: { status: 'pending', details: {} },
    triggers: { status: 'pending', details: {} },
    policies: { status: 'pending', details: {} },
    storage: { status: 'pending', details: {} },
    overall: { status: 'pending', score: 0, maxScore: 0 }
};

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
        console.error(`❌ SQL execution failed for ${projectId}: ${error.message}`);
        return { error: error.message };
    }
}

async function verifyTables() {
    console.log('📊 Verifying Table Structure and Data...');
    
    const criticalTables = [
        'public.user_profiles',
        'public.schools', 
        'public.flashcard_sets',
        'public.cards',
        'public.waitlist',
        'public.favicons'
    ];
    
    verificationResults.tables.details = {};
    let tablesScore = 0;
    
    for (const tableName of criticalTables) {
        const [oldCount, newCount] = await Promise.all([
            executeSQL(OLD_PROJECT_ID, `SELECT COUNT(*) as count FROM ${tableName};`),
            executeSQL(NEW_PROJECT_ID, `SELECT COUNT(*) as count FROM ${tableName};`)
        ]);
        
        const oldRows = oldCount.error ? 0 : (oldCount[0]?.count || 0);
        const newRows = newCount.error ? 0 : (newCount[0]?.count || 0);
        
        const status = oldRows === newRows ? 'SYNCHRONIZED' : 'MISMATCH';
        const passed = status === 'SYNCHRONIZED' || newRows >= oldRows;
        
        verificationResults.tables.details[tableName] = {
            oldRows,
            newRows,
            status,
            passed
        };
        
        if (passed) tablesScore++;
        
        console.log(`   ${passed ? '✅' : '❌'} ${tableName}: ${oldRows} → ${newRows} (${status})`);
    }
    
    verificationResults.tables.status = tablesScore === criticalTables.length ? 'PASSED' : 'FAILED';
    verificationResults.tables.score = tablesScore;
    verificationResults.tables.maxScore = criticalTables.length;
    
    console.log(`   📊 Tables verification: ${tablesScore}/${criticalTables.length} passed`);
}

async function verifyFunctions() {
    console.log('🔧 Verifying Database Functions...');
    
    const criticalFunctions = [
        'handle_new_user',
        'create_classroom',
        'generate_invite_code',
        'join_classroom_with_code'
    ];
    
    verificationResults.functions.details = {};
    let functionsScore = 0;
    
    for (const functionName of criticalFunctions) {
        const result = await executeSQL(NEW_PROJECT_ID, `
            SELECT COUNT(*) as count 
            FROM pg_proc p
            JOIN pg_namespace n ON p.pronamespace = n.oid
            WHERE n.nspname = 'public'
            AND p.proname = '${functionName}';
        `);
        
        const exists = !result.error && result[0]?.count > 0;
        
        verificationResults.functions.details[functionName] = {
            exists,
            passed: exists
        };
        
        if (exists) functionsScore++;
        
        console.log(`   ${exists ? '✅' : '❌'} Function ${functionName}: ${exists ? 'EXISTS' : 'MISSING'}`);
    }
    
    verificationResults.functions.status = functionsScore === criticalFunctions.length ? 'PASSED' : 'FAILED';
    verificationResults.functions.score = functionsScore;
    verificationResults.functions.maxScore = criticalFunctions.length;
    
    console.log(`   📊 Functions verification: ${functionsScore}/${criticalFunctions.length} passed`);
}

async function verifyTriggers() {
    console.log('⚡ Verifying Database Triggers...');
    
    const criticalTriggers = [
        { name: 'on_auth_user_created', table: 'users' },
        { name: 'update_user_profiles_updated_at', table: 'user_profiles' }
    ];
    
    verificationResults.triggers.details = {};
    let triggersScore = 0;
    
    for (const trigger of criticalTriggers) {
        const result = await executeSQL(NEW_PROJECT_ID, `
            SELECT COUNT(*) as count 
            FROM information_schema.triggers
            WHERE trigger_name = '${trigger.name}'
            AND event_object_table = '${trigger.table}';
        `);
        
        const exists = !result.error && result[0]?.count > 0;
        const triggerKey = `${trigger.name}_on_${trigger.table}`;
        
        verificationResults.triggers.details[triggerKey] = {
            exists,
            passed: exists
        };
        
        if (exists) triggersScore++;
        
        console.log(`   ${exists ? '✅' : '❌'} Trigger ${trigger.name} on ${trigger.table}: ${exists ? 'EXISTS' : 'MISSING'}`);
    }
    
    verificationResults.triggers.status = triggersScore === criticalTriggers.length ? 'PASSED' : 'FAILED';
    verificationResults.triggers.score = triggersScore;
    verificationResults.triggers.maxScore = criticalTriggers.length;
    
    console.log(`   📊 Triggers verification: ${triggersScore}/${criticalTriggers.length} passed`);
}

async function verifyRLSPolicies() {
    console.log('🔒 Verifying RLS Policies...');
    
    const criticalTables = [
        'public.user_profiles',
        'public.flashcard_sets',
        'public.cards',
        'public.schools',
        'public.waitlist'
    ];
    
    verificationResults.policies.details = {};
    let policiesScore = 0;
    
    for (const tableName of criticalTables) {
        const [oldPolicies, newPolicies] = await Promise.all([
            executeSQL(OLD_PROJECT_ID, `
                SELECT COUNT(*) as count 
                FROM pg_policies 
                WHERE schemaname = '${tableName.split('.')[0]}'
                AND tablename = '${tableName.split('.')[1]}';
            `),
            executeSQL(NEW_PROJECT_ID, `
                SELECT COUNT(*) as count 
                FROM pg_policies 
                WHERE schemaname = '${tableName.split('.')[0]}'
                AND tablename = '${tableName.split('.')[1]}';
            `)
        ]);
        
        const oldCount = oldPolicies.error ? 0 : (oldPolicies[0]?.count || 0);
        const newCount = newPolicies.error ? 0 : (newPolicies[0]?.count || 0);
        
        const passed = newCount >= oldCount && newCount > 0;
        
        verificationResults.policies.details[tableName] = {
            oldCount,
            newCount,
            passed
        };
        
        if (passed) policiesScore++;
        
        console.log(`   ${passed ? '✅' : '❌'} ${tableName} RLS policies: ${oldCount} → ${newCount}`);
    }
    
    verificationResults.policies.status = policiesScore === criticalTables.length ? 'PASSED' : 'FAILED';
    verificationResults.policies.score = policiesScore;
    verificationResults.policies.maxScore = criticalTables.length;
    
    console.log(`   📊 RLS policies verification: ${policiesScore}/${criticalTables.length} passed`);
}

async function verifyStorage() {
    console.log('🗄️ Verifying Storage...');
    
    const [oldBuckets, newBuckets] = await Promise.all([
        executeSQL(OLD_PROJECT_ID, 'SELECT COUNT(*) as count FROM storage.buckets;'),
        executeSQL(NEW_PROJECT_ID, 'SELECT COUNT(*) as count FROM storage.buckets;')
    ]);
    
    const [oldObjects, newObjects] = await Promise.all([
        executeSQL(OLD_PROJECT_ID, 'SELECT COUNT(*) as count FROM storage.objects;'),
        executeSQL(NEW_PROJECT_ID, 'SELECT COUNT(*) as count FROM storage.objects;')
    ]);
    
    const oldBucketCount = oldBuckets.error ? 0 : (oldBuckets[0]?.count || 0);
    const newBucketCount = newBuckets.error ? 0 : (newBuckets[0]?.count || 0);
    const oldObjectCount = oldObjects.error ? 0 : (oldObjects[0]?.count || 0);
    const newObjectCount = newObjects.error ? 0 : (newObjects[0]?.count || 0);
    
    const bucketsPassed = newBucketCount >= oldBucketCount;
    const objectsPassed = newObjectCount >= oldObjectCount;
    const storageScore = (bucketsPassed ? 1 : 0) + (objectsPassed ? 1 : 0);
    
    verificationResults.storage.details = {
        buckets: { old: oldBucketCount, new: newBucketCount, passed: bucketsPassed },
        objects: { old: oldObjectCount, new: newObjectCount, passed: objectsPassed }
    };
    
    verificationResults.storage.status = storageScore === 2 ? 'PASSED' : 'FAILED';
    verificationResults.storage.score = storageScore;
    verificationResults.storage.maxScore = 2;
    
    console.log(`   ${bucketsPassed ? '✅' : '❌'} Storage buckets: ${oldBucketCount} → ${newBucketCount}`);
    console.log(`   ${objectsPassed ? '✅' : '❌'} Storage objects: ${oldObjectCount} → ${newObjectCount}`);
    console.log(`   📊 Storage verification: ${storageScore}/2 passed`);
}

async function calculateOverallScore() {
    const totalScore = 
        verificationResults.tables.score +
        verificationResults.functions.score +
        verificationResults.triggers.score +
        verificationResults.policies.score +
        verificationResults.storage.score;
        
    const maxScore = 
        verificationResults.tables.maxScore +
        verificationResults.functions.maxScore +
        verificationResults.triggers.maxScore +
        verificationResults.policies.maxScore +
        verificationResults.storage.maxScore;
    
    verificationResults.overall.score = totalScore;
    verificationResults.overall.maxScore = maxScore;
    
    const percentage = Math.round((totalScore / maxScore) * 100);
    
    if (percentage >= 95) {
        verificationResults.overall.status = 'EXCELLENT';
    } else if (percentage >= 85) {
        verificationResults.overall.status = 'GOOD';
    } else if (percentage >= 70) {
        verificationResults.overall.status = 'ACCEPTABLE';
    } else {
        verificationResults.overall.status = 'NEEDS_WORK';
    }
    
    return { totalScore, maxScore, percentage };
}

async function generateVerificationReport() {
    const { totalScore, maxScore, percentage } = await calculateOverallScore();
    
    let report = `# COMPLETE MIGRATION VERIFICATION REPORT\n\n`;
    report += `**Generated:** ${verificationResults.timestamp}\n`;
    report += `**Projects:** ${OLD_PROJECT_ID} → ${NEW_PROJECT_ID}\n`;
    report += `**Overall Score:** ${totalScore}/${maxScore} (${percentage}%)\n`;
    report += `**Status:** ${verificationResults.overall.status}\n\n`;
    
    // Summary table
    report += `## Verification Summary\n\n`;
    report += `| Component | Status | Score | Details |\n`;
    report += `|-----------|--------|-------|----------|\n`;
    report += `| Tables | ${verificationResults.tables.status} | ${verificationResults.tables.score}/${verificationResults.tables.maxScore} | Critical data tables |\n`;
    report += `| Functions | ${verificationResults.functions.status} | ${verificationResults.functions.score}/${verificationResults.functions.maxScore} | Custom database functions |\n`;
    report += `| Triggers | ${verificationResults.triggers.status} | ${verificationResults.triggers.score}/${verificationResults.triggers.maxScore} | Database triggers |\n`;
    report += `| RLS Policies | ${verificationResults.policies.status} | ${verificationResults.policies.score}/${verificationResults.policies.maxScore} | Row-level security |\n`;
    report += `| Storage | ${verificationResults.storage.status} | ${verificationResults.storage.score}/${verificationResults.storage.maxScore} | File storage |\n\n`;
    
    // Detailed results
    report += `## Detailed Results\n\n`;
    
    report += `### Tables Verification\n`;
    for (const [table, details] of Object.entries(verificationResults.tables.details)) {
        report += `- **${table}**: ${details.oldRows} → ${details.newRows} (${details.status}) ${details.passed ? '✅' : '❌'}\n`;
    }
    report += '\n';
    
    report += `### Functions Verification\n`;
    for (const [func, details] of Object.entries(verificationResults.functions.details)) {
        report += `- **${func}**: ${details.exists ? 'EXISTS' : 'MISSING'} ${details.passed ? '✅' : '❌'}\n`;
    }
    report += '\n';
    
    report += `### Triggers Verification\n`;
    for (const [trigger, details] of Object.entries(verificationResults.triggers.details)) {
        report += `- **${trigger}**: ${details.exists ? 'EXISTS' : 'MISSING'} ${details.passed ? '✅' : '❌'}\n`;
    }
    report += '\n';
    
    report += `### RLS Policies Verification\n`;
    for (const [table, details] of Object.entries(verificationResults.policies.details)) {
        report += `- **${table}**: ${details.oldCount} → ${details.newCount} policies ${details.passed ? '✅' : '❌'}\n`;
    }
    report += '\n';
    
    report += `### Storage Verification\n`;
    report += `- **Buckets**: ${verificationResults.storage.details.buckets.old} → ${verificationResults.storage.details.buckets.new} ${verificationResults.storage.details.buckets.passed ? '✅' : '❌'}\n`;
    report += `- **Objects**: ${verificationResults.storage.details.objects.old} → ${verificationResults.storage.details.objects.new} ${verificationResults.storage.details.objects.passed ? '✅' : '❌'}\n\n`;
    
    // Recommendations
    report += `## Recommendations\n\n`;
    
    if (percentage >= 95) {
        report += `🎉 **EXCELLENT!** Migration is nearly complete. You can proceed with confidence.\n\n`;
    } else if (percentage >= 85) {
        report += `👍 **GOOD!** Migration is mostly complete with minor issues to address.\n\n`;
    } else if (percentage >= 70) {
        report += `⚠️ **ACCEPTABLE** but needs attention. Several components require fixing.\n\n`;
    } else {
        report += `🚨 **CRITICAL** issues found. Migration needs significant work before production use.\n\n`;
    }
    
    // Next steps
    const failedComponents = [];
    if (verificationResults.tables.status === 'FAILED') failedComponents.push('tables');
    if (verificationResults.functions.status === 'FAILED') failedComponents.push('functions');
    if (verificationResults.triggers.status === 'FAILED') failedComponents.push('triggers');
    if (verificationResults.policies.status === 'FAILED') failedComponents.push('RLS policies');
    if (verificationResults.storage.status === 'FAILED') failedComponents.push('storage');
    
    if (failedComponents.length > 0) {
        report += `### Action Items:\n`;
        report += `1. Address failed components: ${failedComponents.join(', ')}\n`;
        report += `2. Run the generated migration scripts\n`;
        report += `3. Re-run this verification script\n`;
        report += `4. Test application functionality\n\n`;
    } else {
        report += `### Next Steps:\n`;
        report += `1. Test application functionality with NEW project\n`;
        report += `2. Update production configuration to use NEW project\n`;
        report += `3. Monitor for any issues\n`;
        report += `4. Decommission OLD project when stable\n\n`;
    }
    
    // Save report
    await fs.writeFile(
        '/Volumes/PASSPORT/TELJES/IT/CURSOR/SNAPPYCARDS/MIGRATION_VERIFICATION_REPORT.md',
        report
    );
    
    await fs.writeFile(
        '/Volumes/PASSPORT/TELJES/IT/CURSOR/SNAPPYCARDS/VERIFICATION_RESULTS.json',
        JSON.stringify(verificationResults, null, 2)
    );
    
    return { report, percentage, status: verificationResults.overall.status };
}

async function runCompleteVerification() {
    console.log('🎯 COMPLETE MIGRATION VERIFICATION');
    console.log('==================================');
    console.log(`📊 Verifying migration from ${OLD_PROJECT_ID} to ${NEW_PROJECT_ID}`);
    console.log('');
    
    try {
        await verifyTables();
        console.log('');
        
        await verifyFunctions();
        console.log('');
        
        await verifyTriggers();
        console.log('');
        
        await verifyRLSPolicies();
        console.log('');
        
        await verifyStorage();
        console.log('');
        
        const { percentage, status } = await generateVerificationReport();
        
        console.log('📋 VERIFICATION COMPLETED');
        console.log('=========================');
        console.log(`🎯 Overall Score: ${verificationResults.overall.score}/${verificationResults.overall.maxScore} (${percentage}%)`);
        console.log(`📊 Status: ${status}`);
        console.log('');
        console.log('📝 Generated Reports:');
        console.log('   - MIGRATION_VERIFICATION_REPORT.md');
        console.log('   - VERIFICATION_RESULTS.json');
        
        return verificationResults;
        
    } catch (error) {
        console.error('💥 Verification failed:', error.message);
        throw error;
    }
}

if (require.main === module) {
    runCompleteVerification().then((results) => {
        const success = results.overall.score / results.overall.maxScore >= 0.85;
        console.log(`🏁 Verification ${success ? 'PASSED' : 'FAILED'}`);
        process.exit(success ? 0 : 1);
    }).catch((error) => {
        console.error('💥 Verification script failed:', error.message);
        process.exit(1);
    });
}

module.exports = { runCompleteVerification };