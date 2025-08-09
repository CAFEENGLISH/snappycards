#!/usr/bin/env node

/**
 * Schema Difference Checker
 * 
 * This script checks the column differences between OLD and NEW projects
 * for tables that failed migration
 */

const https = require('https');

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
        return [];
    }
}

/**
 * Get table schema
 */
async function getTableSchema(projectId, tableName) {
    const sql = `
        SELECT 
            column_name,
            data_type,
            is_nullable,
            column_default
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = '${tableName}'
        ORDER BY ordinal_position;
    `;
    
    return await executeSQL(projectId, sql);
}

/**
 * Get table data sample
 */
async function getTableData(projectId, tableName) {
    const sql = `SELECT * FROM ${tableName} LIMIT 1;`;
    return await executeSQL(projectId, sql);
}

/**
 * Main schema checking function
 */
async function checkSchemas() {
    console.log('🔍 SnappyCards Schema Difference Checker');
    console.log('========================================');
    
    const problematicTables = ['favicons', 'waitlist'];
    
    for (const tableName of problematicTables) {
        console.log(`\n📊 Checking ${tableName} table:`);
        console.log('--------------------------------');
        
        try {
            const [oldSchema, newSchema, oldData, newData] = await Promise.all([
                getTableSchema(OLD_PROJECT_ID, tableName),
                getTableSchema(NEW_PROJECT_ID, tableName),
                getTableData(OLD_PROJECT_ID, tableName),
                getTableData(NEW_PROJECT_ID, tableName)
            ]);

            console.log(`\n🗂️  OLD project ${tableName} schema:`);
            oldSchema.forEach(col => {
                console.log(`   ${col.column_name} (${col.data_type})`);
            });

            console.log(`\n🗂️  NEW project ${tableName} schema:`);
            newSchema.forEach(col => {
                console.log(`   ${col.column_name} (${col.data_type})`);
            });

            console.log(`\n📋 OLD project ${tableName} sample data:`);
            if (oldData.length > 0) {
                console.log('   Columns:', Object.keys(oldData[0]).join(', '));
                console.log('   Sample:', JSON.stringify(oldData[0], null, 2));
            } else {
                console.log('   No data');
            }

            console.log(`\n📋 NEW project ${tableName} sample data:`);
            if (newData.length > 0) {
                console.log('   Columns:', Object.keys(newData[0]).join(', '));
                console.log('   Sample:', JSON.stringify(newData[0], null, 2));
            } else {
                console.log('   No data');
            }

            // Generate compatible INSERT statements
            if (oldData.length > 0) {
                const oldColumns = Object.keys(oldData[0]);
                const newColumns = newSchema.map(col => col.column_name);
                const compatibleColumns = oldColumns.filter(col => newColumns.includes(col));
                
                console.log(`\n🔧 Compatible columns for migration: ${compatibleColumns.join(', ')}`);
                
                const row = oldData[0];
                const values = compatibleColumns.map(col => {
                    const value = row[col];
                    if (value === null) return 'NULL';
                    if (typeof value === 'string') {
                        return `'${value.replace(/'/g, "''")}'`; // Escape single quotes
                    }
                    if (typeof value === 'boolean') return value;
                    if (value instanceof Date) return `'${value.toISOString()}'`;
                    return value;
                }).join(', ');

                const insertSQL = `INSERT INTO ${tableName} (${compatibleColumns.join(', ')}) VALUES (${values}) ON CONFLICT DO NOTHING;`;
                console.log(`\n📝 Compatible INSERT statement:`);
                console.log(insertSQL);
            }

        } catch (error) {
            console.error(`❌ Failed to check ${tableName}:`, error.message);
        }
    }
}

// Run the checker
if (require.main === module) {
    checkSchemas().then(() => {
        console.log('\n🏁 Schema checking completed');
        process.exit(0);
    }).catch((error) => {
        console.error('💥 Script failed:', error.message);
        process.exit(1);
    });
}

module.exports = { checkSchemas };