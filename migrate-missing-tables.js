#!/usr/bin/env node

/**
 * SnappyCards Complete Database Migration Tool
 * 
 * This script migrates ALL missing tables from OLD to NEW Supabase project
 * using the Supabase Management API and Personal Access Token
 */

const https = require('https');
const fs = require('fs');

// Configuration
const PERSONAL_ACCESS_TOKEN = 'sbp_6d50add440dc1960b3efbd639d932f4b42ece0f2';
const OLD_PROJECT_ID = 'ycxqxdhaxehspypqbnpi';
const NEW_PROJECT_ID = 'aeijlzokobuqcyznljvn';

// API endpoints
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
 * Get list of tables in a project
 */
async function getTables(projectId) {
    const sql = `
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = 'public' 
        ORDER BY table_name;
    `;
    
    try {
        const result = await executeSQL(projectId, sql);
        return result.map(row => row.table_name);
    } catch (error) {
        console.error(`❌ Failed to get tables from project ${projectId}:`, error.message);
        return [];
    }
}

/**
 * Get table structure
 */
async function getTableStructure(projectId, tableName) {
    const sql = `
        SELECT 
            column_name,
            data_type,
            is_nullable,
            column_default,
            character_maximum_length,
            numeric_precision,
            numeric_scale
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = '${tableName}'
        ORDER BY ordinal_position;
    `;
    
    try {
        const result = await executeSQL(projectId, sql);
        return result;
    } catch (error) {
        console.error(`❌ Failed to get structure for table ${tableName}:`, error.message);
        return [];
    }
}

/**
 * Main migration function
 */
async function migrateAllTables() {
    console.log('🚀 Starting SnappyCards Database Migration');
    console.log('=====================================');
    console.log(`📊 OLD Project: ${OLD_PROJECT_ID}`);
    console.log(`📊 NEW Project: ${NEW_PROJECT_ID}`);
    console.log('');

    try {
        // Step 1: Get tables from both projects
        console.log('📋 Step 1: Analyzing current database state...');
        
        const [oldTables, newTables] = await Promise.all([
            getTables(OLD_PROJECT_ID),
            getTables(NEW_PROJECT_ID)
        ]);

        console.log(`✅ OLD project has ${oldTables.length} tables:`);
        oldTables.forEach(table => console.log(`   - ${table}`));
        console.log('');

        console.log(`✅ NEW project has ${newTables.length} tables:`);
        newTables.forEach(table => console.log(`   - ${table}`));
        console.log('');

        // Step 2: Identify missing tables
        const missingTables = oldTables.filter(table => !newTables.includes(table));
        
        if (missingTables.length === 0) {
            console.log('🎉 All tables already exist in the NEW project!');
            console.log('✅ No migration needed.');
            return;
        }

        console.log(`⚠️  Found ${missingTables.length} missing tables:`);
        missingTables.forEach(table => console.log(`   - ${table}`));
        console.log('');

        // Step 3: Execute the complete database fix
        console.log('🔧 Step 3: Executing complete database migration...');
        
        // Read the comprehensive SQL file
        const sqlFilePath = '/Volumes/PASSPORT/TELJES/IT/CURSOR/SNAPPYCARDS/create-all-missing-tables.sql';
        
        if (!fs.existsSync(sqlFilePath)) {
            throw new Error(`SQL file not found: ${sqlFilePath}`);
        }

        const completeSql = fs.readFileSync(sqlFilePath, 'utf8');
        
        console.log('📝 Executing create-all-missing-tables.sql...');
        await executeSQL(NEW_PROJECT_ID, completeSql);
        
        console.log('✅ Complete database fix executed successfully!');
        console.log('');

        // Step 4: Verify migration
        console.log('🔍 Step 4: Verifying migration results...');
        
        const newTablesAfterMigration = await getTables(NEW_PROJECT_ID);
        const stillMissing = oldTables.filter(table => !newTablesAfterMigration.includes(table));
        
        if (stillMissing.length === 0) {
            console.log('🎉 MIGRATION COMPLETED SUCCESSFULLY!');
            console.log(`✅ All ${oldTables.length} tables now exist in the NEW project`);
            console.log('✅ Database structure is fully synchronized');
        } else {
            console.log(`⚠️  ${stillMissing.length} tables still missing:`);
            stillMissing.forEach(table => console.log(`   - ${table}`));
        }

        console.log('');
        console.log('📊 Final table count comparison:');
        console.log(`   OLD project: ${oldTables.length} tables`);
        console.log(`   NEW project: ${newTablesAfterMigration.length} tables`);
        console.log('');

        // Step 5: Show next steps
        console.log('✅ NEXT STEPS:');
        console.log('1. Test student login functionality');
        console.log('2. Verify flashcard study features work');
        console.log('3. Check that progress saving works correctly');
        console.log('4. Run application tests');

    } catch (error) {
        console.error('💥 Migration failed:', error.message);
        console.error('');
        console.error('🔧 Troubleshooting suggestions:');
        console.error('1. Check that your Personal Access Token is valid');
        console.error('2. Verify project IDs are correct');
        console.error('3. Ensure you have admin access to both projects');
        console.error('4. Try running the SQL manually in Supabase dashboard');
    }
}

// Run the migration
if (require.main === module) {
    migrateAllTables().then(() => {
        console.log('🏁 Migration script completed');
        process.exit(0);
    }).catch((error) => {
        console.error('💥 Script failed:', error.message);
        process.exit(1);
    });
}

module.exports = { migrateAllTables, getTables, executeSQL };