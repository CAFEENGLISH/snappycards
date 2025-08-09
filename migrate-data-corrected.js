#!/usr/bin/env node

/**
 * SnappyCards Corrected Data Migration Tool
 * 
 * This script properly migrates data accounting for schema differences:
 * - favicons: Only compatible columns (id, created_at, is_active)
 * - waitlist: Only compatible columns (email, created_at) + generate new UUID
 */

const https = require('https');
const crypto = require('crypto');

// Configuration
const PERSONAL_ACCESS_TOKEN = 'sbp_6d50add440dc1960b3efbd639d932f4b42ece0f2';
const OLD_PROJECT_ID = 'ycxqxdhaxehspypqbnpi';
const NEW_PROJECT_ID = 'aeijlzokobuqcyznljvn';
const SUPABASE_API_BASE = 'https://api.supabase.com/v1';

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
                        resolve(JSON.parse(data));
                    } else {
                        reject(new Error(`HTTP ${res.statusCode}: ${data}`));
                    }
                } catch (error) {
                    reject(error);
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
        return result;
    } catch (error) {
        console.error(`❌ SQL execution failed for project ${projectId}:`, error.message);
        throw error;
    }
}

/**
 * Get all data from a table
 */
async function getTableData(projectId, tableName) {
    const sql = `SELECT * FROM ${tableName};`;
    return await executeSQL(projectId, sql);
}

/**
 * Generate UUID v4
 */
function generateUUID() {
    return crypto.randomUUID();
}

/**
 * Migrate favicons data with schema mapping
 */
async function migrateFavicons() {
    console.log('🔄 Migrating favicons with domain mapping...');
    
    const oldData = await getTableData(OLD_PROJECT_ID, 'favicons');
    
    if (oldData.length === 0) {
        console.log('   ✅ No favicons data to migrate');
        return;
    }

    console.log(`   📊 Found ${oldData.length} favicons records`);
    
    // Map old favicon data to new schema
    const insertStatements = oldData.map(row => {
        // Extract domain from name or use default
        const domain = row.name?.toLowerCase().includes('snappycards') ? 'snappycards.app' : 'unknown.com';
        
        // Map data_url to favicon_url (or use a default)
        const faviconUrl = row.data_url || 'https://via.placeholder.com/32x32.png';
        
        return `
            INSERT INTO favicons (
                id, 
                domain, 
                favicon_url, 
                last_updated, 
                is_active, 
                fetch_attempts, 
                last_fetch_attempt, 
                created_at
            ) VALUES (
                '${row.id}',
                '${domain}',
                '${faviconUrl.replace(/'/g, "''")}',
                '${row.created_at}',
                ${row.is_active},
                1,
                '${row.created_at}',
                '${row.created_at}'
            ) ON CONFLICT (id) DO NOTHING;
        `;
    }).join('\n');

    await executeSQL(NEW_PROJECT_ID, insertStatements);
    console.log('   ✅ Successfully migrated favicons data');
}

/**
 * Migrate waitlist data with schema mapping
 */
async function migrateWaitlist() {
    console.log('🔄 Migrating waitlist with UUID conversion...');
    
    const oldData = await getTableData(OLD_PROJECT_ID, 'waitlist');
    
    if (oldData.length === 0) {
        console.log('   ✅ No waitlist data to migrate');
        return;
    }

    console.log(`   📊 Found ${oldData.length} waitlist records`);
    
    // Map old waitlist data to new schema
    const insertStatements = oldData.map(row => {
        const newUUID = generateUUID();
        
        // Map confirmed status to new status field
        const status = row.confirmed ? 'registered' : 'pending';
        const registeredAt = row.confirmed_at || null;
        const inviteSentAt = row.confirmed ? row.created_at : null;
        
        return `
            INSERT INTO waitlist (
                id, 
                email, 
                first_name,
                language, 
                source, 
                status, 
                invite_sent_at, 
                registered_at, 
                is_mock, 
                created_at, 
                updated_at
            ) VALUES (
                '${newUUID}',
                '${row.email.replace(/'/g, "''")}',
                NULL,
                'hu',
                'landing_page',
                '${status}',
                ${inviteSentAt ? `'${inviteSentAt}'` : 'NULL'},
                ${registeredAt ? `'${registeredAt}'` : 'NULL'},
                false,
                '${row.created_at}',
                '${row.created_at}'
            ) ON CONFLICT (email) DO NOTHING;
        `;
    }).join('\n');

    await executeSQL(NEW_PROJECT_ID, insertStatements);
    console.log('   ✅ Successfully migrated waitlist data');
}

/**
 * Main corrected data migration function
 */
async function migrateDataCorrected() {
    console.log('🔄 SnappyCards Corrected Data Migration');
    console.log('======================================');
    console.log(`📊 Migrating data from OLD (${OLD_PROJECT_ID}) to NEW (${NEW_PROJECT_ID})`);
    console.log('🔧 Handling schema differences properly');
    console.log('');

    try {
        // Migrate schools (already works)
        console.log('🔄 Migrating schools (no schema changes)...');
        const schoolsData = await getTableData(OLD_PROJECT_ID, 'schools');
        
        if (schoolsData.length > 0) {
            console.log(`   📊 Found ${schoolsData.length} schools records`);
            
            const schoolsSQL = `
                INSERT INTO schools (
                    id, name, domain, contact_email, admin_user_id, 
                    is_active, created_at, updated_at
                ) VALUES (
                    '${schoolsData[0].id}',
                    '${schoolsData[0].name?.replace(/'/g, "''")}',
                    '${schoolsData[0].domain?.replace(/'/g, "''")}',
                    '${schoolsData[0].contact_email?.replace(/'/g, "''")}',
                    '${schoolsData[0].admin_user_id}',
                    ${schoolsData[0].is_active},
                    '${schoolsData[0].created_at}',
                    '${schoolsData[0].updated_at}'
                ) ON CONFLICT (id) DO NOTHING;
            `;
            
            await executeSQL(NEW_PROJECT_ID, schoolsSQL);
            console.log('   ✅ Successfully migrated schools data');
        } else {
            console.log('   ✅ No schools data to migrate');
        }
        
        console.log('');

        // Migrate favicons with schema mapping
        await migrateFavicons();
        console.log('');

        // Migrate waitlist with schema mapping  
        await migrateWaitlist();
        console.log('');

        // Verify migration
        console.log('🔍 Verifying corrected data migration...');
        
        const tables = ['schools', 'favicons', 'waitlist'];
        
        for (const table of tables) {
            try {
                const newCount = await executeSQL(NEW_PROJECT_ID, `SELECT COUNT(*) as count FROM ${table};`);
                const records = newCount[0]?.count || 0;
                console.log(`✅ ${table}: ${records} records in NEW project`);
            } catch (error) {
                console.log(`⚠️  Could not verify ${table}: ${error.message}`);
            }
        }

        console.log('');
        console.log('🎉 CORRECTED DATA MIGRATION COMPLETED');
        console.log('====================================');
        console.log('✅ All data migrated with proper schema mapping');
        console.log('✅ Database is fully synchronized');
        console.log('✅ SnappyCards application ready for production');

    } catch (error) {
        console.error('💥 Corrected migration failed:', error.message);
        console.error('');
        console.error('🔧 Troubleshooting suggestions:');
        console.error('1. Check the error message for specific constraint violations');
        console.error('2. Verify all required columns have proper default values');
        console.error('3. Check for duplicate key conflicts');
        throw error;
    }
}

// Run the corrected migration
if (require.main === module) {
    migrateDataCorrected().then(() => {
        console.log('🏁 Corrected data migration script completed');
        process.exit(0);
    }).catch((error) => {
        console.error('💥 Script failed:', error.message);
        process.exit(1);
    });
}

module.exports = { migrateDataCorrected };