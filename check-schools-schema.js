#!/usr/bin/env node

/**
 * Schools Schema Checker
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
 * Check schools table schema
 */
async function checkSchoolsSchema() {
    console.log('🔍 Schools Table Schema Comparison');
    console.log('==================================');
    
    const getSchemaSQL = `
        SELECT 
            column_name,
            data_type,
            is_nullable,
            column_default
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'schools'
        ORDER BY ordinal_position;
    `;

    const getDataSQL = `SELECT * FROM schools LIMIT 1;`;
    
    try {
        const [oldSchema, newSchema, oldData, newData] = await Promise.all([
            executeSQL(OLD_PROJECT_ID, getSchemaSQL),
            executeSQL(NEW_PROJECT_ID, getSchemaSQL),
            executeSQL(OLD_PROJECT_ID, getDataSQL),
            executeSQL(NEW_PROJECT_ID, getDataSQL)
        ]);

        console.log('\n🗂️  OLD project schools schema:');
        oldSchema.forEach(col => {
            console.log(`   ${col.column_name} (${col.data_type})`);
        });

        console.log('\n🗂️  NEW project schools schema:');
        newSchema.forEach(col => {
            console.log(`   ${col.column_name} (${col.data_type})`);
        });

        console.log('\n📋 OLD project schools sample data:');
        if (oldData.length > 0) {
            console.log('   Columns:', Object.keys(oldData[0]).join(', '));
            console.log('   Sample:', JSON.stringify(oldData[0], null, 2));
        } else {
            console.log('   No data');
        }

        console.log('\n📋 NEW project schools sample data:');
        if (newData.length > 0) {
            console.log('   Columns:', Object.keys(newData[0]).join(', '));
            console.log('   Sample:', JSON.stringify(newData[0], null, 2));
        } else {
            console.log('   No data');
        }

        // Generate compatible migration
        if (oldData.length > 0) {
            const oldColumns = Object.keys(oldData[0]);
            const newColumns = newSchema.map(col => col.column_name);
            const compatibleColumns = oldColumns.filter(col => newColumns.includes(col));
            
            console.log(`\n🔧 Compatible columns: ${compatibleColumns.join(', ')}`);
            
            const row = oldData[0];
            const values = compatibleColumns.map(col => {
                const value = row[col];
                if (value === null) return 'NULL';
                if (typeof value === 'string') {
                    return `'${value.replace(/'/g, "''")}'`;
                }
                if (typeof value === 'boolean') return value;
                if (value instanceof Date) return `'${value.toISOString()}'`;
                return value;
            });

            const insertSQL = `INSERT INTO schools (${compatibleColumns.join(', ')}) VALUES (${values.join(', ')}) ON CONFLICT DO NOTHING;`;
            console.log(`\n📝 Compatible INSERT statement:`);
            console.log(insertSQL);
        }

    } catch (error) {
        console.error('❌ Failed to check schools schema:', error.message);
    }
}

// Run the checker
if (require.main === module) {
    checkSchoolsSchema().then(() => {
        console.log('\n🏁 Schools schema checking completed');
        process.exit(0);
    }).catch((error) => {
        console.error('💥 Script failed:', error.message);
        process.exit(1);
    });
}