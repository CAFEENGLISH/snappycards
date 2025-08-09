#!/usr/bin/env node

const https = require('https');

// Old Supabase project credentials
const SUPABASE_URL = 'https://ycxqxdhaxehspypqbnpi.supabase.co';
const ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InljeHF4ZGhheGVoc3B5cHFibnBpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMyMDMwMzEsImV4cCI6MjA2ODc3OTAzMX0.7RGVld6WOhNgeTA6xQc_U_eDXfMGzIshUlKV6j2Ru6g';

// Function to make HTTP requests
function makeRequest(url, options = {}) {
    return new Promise((resolve, reject) => {
        const req = https.request(url, options, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                try {
                    const result = JSON.parse(data);
                    resolve(result);
                } catch (e) {
                    resolve({ error: 'Parse error', data });
                }
            });
        });
        
        req.on('error', reject);
        
        if (options.body) {
            req.write(options.body);
        }
        
        req.end();
    });
}

// Comprehensive table discovery with multiple strategies
async function comprehensiveTableDiscovery() {
    console.log('🔍 COMPREHENSIVE TABLE DISCOVERY\n');
    
    // Strategy 1: Check all expected tables from the schemas we found
    const expectedTables = [
        // From supabase-setup.sql
        'schools', 'user_profiles', 'categories', 'flashcard_sets', 'cards',
        'card_categories', 'flashcard_set_cards', 'flashcard_set_categories',
        'classrooms', 'classroom_sets', 'study_sessions',
        // From additional files
        'user_card_progress', 'user_set_progress', 'study_logs', 
        'card_interactions', 'waitlist',
        // Common variations and alternative names
        'sets', 'flashcards', 'users', 'profiles', 'achievements', 'progress',
        'teachers', 'students', 'classes', 'assignments', 'progress_tracking',
        'user_progress', 'set_assignments', 'student_class_assignments'
    ];
    
    const discoveredTables = [];
    const tableSchemas = {};
    
    console.log('Strategy 1: Testing expected table names...\n');
    
    for (const tableName of expectedTables) {
        const url = `${SUPABASE_URL}/rest/v1/${tableName}?limit=1`;
        const options = {
            method: 'GET',
            headers: {
                'apikey': ANON_KEY,
                'Authorization': `Bearer ${ANON_KEY}`,
            }
        };
        
        try {
            const result = await makeRequest(url, options);
            
            if (result && Array.isArray(result)) {
                discoveredTables.push(tableName);
                console.log(`✅ ${tableName} - EXISTS`);
                
                // If table has data, extract schema
                if (result.length > 0) {
                    const sample = result[0];
                    tableSchemas[tableName] = Object.keys(sample);
                    console.log(`   Columns: ${Object.keys(sample).join(', ')}`);
                } else {
                    console.log(`   Table is empty - trying OPTIONS request for schema...`);
                    // Try to get schema from empty table
                    await getEmptyTableSchema(tableName, tableSchemas);
                }
            } else if (result && result.message) {
                console.log(`❌ ${tableName} - ${result.message}`);
            } else if (result && result.error) {
                console.log(`❌ ${tableName} - ${result.error}`);
            } else {
                console.log(`❓ ${tableName} - Unknown response:`, result);
            }
        } catch (error) {
            console.log(`❌ ${tableName} - Error: ${error.message}`);
        }
        
        // Small delay to avoid rate limiting
        await new Promise(resolve => setTimeout(resolve, 100));
    }
    
    return { discoveredTables, tableSchemas };
}

// Try to get schema from empty table using OPTIONS or INSERT attempt
async function getEmptyTableSchema(tableName, tableSchemas) {
    // Try OPTIONS request to see if we can get schema info
    const url = `${SUPABASE_URL}/rest/v1/${tableName}`;
    const options = {
        method: 'OPTIONS',
        headers: {
            'apikey': ANON_KEY,
            'Authorization': `Bearer ${ANON_KEY}`,
        }
    };
    
    try {
        const result = await makeRequest(url, options);
        console.log(`   OPTIONS response for ${tableName}:`, result);
    } catch (error) {
        // Silent fail for OPTIONS
    }
    
    // Mark as empty but existing
    tableSchemas[tableName] = ['(empty table - schema unknown)'];
}

// Generate CREATE TABLE statements based on discovered schemas
function generateCreateStatements(tableSchemas) {
    console.log('\n📝 GENERATING CREATE TABLE STATEMENTS\n');
    console.log('========================================\n');
    
    const createStatements = [];
    
    for (const [tableName, columns] of Object.entries(tableSchemas)) {
        if (columns.includes('(empty table - schema unknown)')) {
            console.log(`-- Table ${tableName} exists but schema is unknown (empty table)`);
            console.log(`-- Manual inspection required for: ${tableName}\n`);
        } else {
            // Generate basic CREATE TABLE based on column names
            // This won't be perfect but gives a starting point
            const columnDefs = columns.map(col => {
                // Basic type guessing based on common patterns
                if (col === 'id') return `${col} UUID PRIMARY KEY DEFAULT uuid_generate_v4()`;
                if (col.endsWith('_id')) return `${col} UUID REFERENCES ${col.replace('_id', '')}(id)`;
                if (col.includes('email')) return `${col} TEXT UNIQUE NOT NULL`;
                if (col.includes('created_at') || col.includes('updated_at')) return `${col} TIMESTAMP WITH TIME ZONE DEFAULT NOW()`;
                if (col.includes('is_') || col === 'active') return `${col} BOOLEAN DEFAULT true`;
                if (col.includes('count') || col.includes('level') || col.includes('time')) return `${col} INTEGER DEFAULT 0`;
                return `${col} TEXT`;
            }).join(',\n    ');
            
            const createStatement = `CREATE TABLE IF NOT EXISTS ${tableName} (\n    ${columnDefs}\n);`;
            createStatements.push(createStatement);
            console.log(createStatement);
            console.log('');
        }
    }
    
    return createStatements;
}

// Main execution
async function main() {
    console.log('🚀 OLD SUPABASE PROJECT SCHEMA EXTRACTION');
    console.log('==========================================\n');
    console.log(`🔗 Connecting to: ${SUPABASE_URL}\n`);
    
    const { discoveredTables, tableSchemas } = await comprehensiveTableDiscovery();
    
    console.log('\n📊 DISCOVERY SUMMARY');
    console.log('===================\n');
    console.log(`Total tables found: ${discoveredTables.length}`);
    console.log(`Tables: ${discoveredTables.sort().join(', ')}\n`);
    
    if (discoveredTables.length > 0) {
        console.log('📋 DETAILED TABLE INFORMATION');
        console.log('=============================\n');
        
        discoveredTables.sort().forEach((tableName, index) => {
            const columns = tableSchemas[tableName] || ['(schema unknown)'];
            console.log(`${index + 1}. ${tableName}`);
            console.log(`   Columns (${columns.length}): ${columns.join(', ')}`);
            console.log('');
        });
        
        // Generate CREATE TABLE statements
        generateCreateStatements(tableSchemas);
        
        console.log('🎯 COMPARISON WITH EXPECTED SCHEMA');
        console.log('==================================\n');
        
        const expectedFromNewProject = [
            'schools', 'user_profiles', 'categories', 'flashcard_sets', 'cards',
            'card_categories', 'flashcard_set_cards', 'flashcard_set_categories',
            'classrooms', 'classroom_sets', 'study_sessions', 'user_card_progress',
            'user_set_progress', 'study_logs', 'card_interactions', 'waitlist'
        ];
        
        const missingInOld = expectedFromNewProject.filter(table => !discoveredTables.includes(table));
        const extraInOld = discoveredTables.filter(table => !expectedFromNewProject.includes(table));
        
        if (missingInOld.length > 0) {
            console.log(`❌ Tables missing in OLD project (${missingInOld.length}):`);
            missingInOld.forEach(table => console.log(`   - ${table}`));
            console.log('');
        }
        
        if (extraInOld.length > 0) {
            console.log(`➕ Extra tables in OLD project (${extraInOld.length}):`);
            extraInOld.forEach(table => console.log(`   - ${table}`));
            console.log('');
        }
        
        console.log(`✅ Total unique tables in old project: ${discoveredTables.length}`);
        console.log(`🎯 Expected tables in new project: ${expectedFromNewProject.length}`);
        
        if (discoveredTables.length >= 19) {
            console.log('🎉 SUCCESS: Found all 19+ tables as expected!');
        } else {
            console.log(`⚠️  Only found ${discoveredTables.length} tables, expected ~19`);
        }
        
    } else {
        console.log('❌ No tables discovered. Possible issues:');
        console.log('   - Database is completely empty');
        console.log('   - Access permissions too restrictive');
        console.log('   - Project may be inactive or deleted');
    }
}

// Run the script
main().catch(console.error);