/**
 * Extract Missing Table Structures from Old Supabase Project
 * 
 * This script connects to the old Supabase project (ycxqxdhaxehspypqbnpi.supabase.co)
 * and extracts the exact table structures for the 3 missing tables:
 * 1. classroom_details (11 columns)
 * 2. classroom_members (5 columns)
 * 3. favicons (6 columns) - HAS 1 ROW OF DATA!
 */

// You need to run this in Node.js with the @supabase/supabase-js package installed
// npm install @supabase/supabase-js

const { createClient } = require('@supabase/supabase-js');

// Old Supabase project configuration
// You need to replace these with the actual values from the old project
const OLD_SUPABASE_URL = 'https://ycxqxdhaxehspypqbnpi.supabase.co';
const OLD_SUPABASE_ANON_KEY = 'YOUR_OLD_PROJECT_ANON_KEY_HERE'; // You need to get this from the old project

// Create Supabase client
const supabase = createClient(OLD_SUPABASE_URL, OLD_SUPABASE_ANON_KEY);

async function extractTableStructures() {
    console.log('🔍 Extracting table structures from old Supabase project...\n');

    try {
        // 1. Get column structure for all missing tables
        console.log('📊 Getting column structures for missing tables...');
        
        const { data: columns, error: columnsError } = await supabase.rpc('sql', {
            query: `
                SELECT 
                    table_name,
                    column_name,
                    data_type,
                    is_nullable,
                    column_default,
                    character_maximum_length,
                    ordinal_position
                FROM information_schema.columns
                WHERE table_schema = 'public' 
                AND table_name IN ('classroom_details', 'classroom_members', 'favicons')
                ORDER BY table_name, ordinal_position;
            `
        });

        if (columnsError) {
            console.error('❌ Error getting columns:', columnsError);
        } else if (columns) {
            console.log('✅ Column structures retrieved:');
            console.log(JSON.stringify(columns, null, 2));
        }

        // 2. Get actual data from favicons table
        console.log('\n📋 Getting data from favicons table...');
        
        const { data: faviconData, error: faviconError } = await supabase
            .from('favicons')
            .select('*');

        if (faviconError) {
            console.error('❌ Error getting favicons data:', faviconError);
        } else if (faviconData) {
            console.log('✅ Favicons data retrieved:');
            console.log(JSON.stringify(faviconData, null, 2));
        }

        // 3. Try to get CREATE TABLE statements (this might not work with RLS)
        console.log('\n🔧 Attempting to get table definitions...');
        
        const tableNames = ['classroom_details', 'classroom_members', 'favicons'];
        
        for (const tableName of tableNames) {
            try {
                const { data: tableDef, error: tableDefError } = await supabase.rpc('sql', {
                    query: `
                        SELECT 
                            'CREATE TABLE ' || table_name || ' (' ||
                            string_agg(
                                column_name || ' ' || 
                                CASE 
                                    WHEN data_type = 'character varying' THEN 'TEXT'
                                    WHEN data_type = 'timestamp with time zone' THEN 'TIMESTAMP WITH TIME ZONE'
                                    WHEN data_type = 'uuid' THEN 'UUID'
                                    WHEN data_type = 'boolean' THEN 'BOOLEAN'
                                    WHEN data_type = 'integer' THEN 'INTEGER'
                                    ELSE UPPER(data_type)
                                END ||
                                CASE WHEN is_nullable = 'NO' THEN ' NOT NULL' ELSE '' END ||
                                CASE WHEN column_default IS NOT NULL THEN ' DEFAULT ' || column_default ELSE '' END,
                                ', '
                            ) || ');' as create_statement
                        FROM information_schema.columns
                        WHERE table_schema = 'public' 
                        AND table_name = '${tableName}'
                        GROUP BY table_name;
                    `
                });

                if (tableDefError) {
                    console.error(`❌ Error getting ${tableName} definition:`, tableDefError);
                } else if (tableDef && tableDef.length > 0) {
                    console.log(`\n✅ ${tableName.toUpperCase()} CREATE statement:`);
                    console.log(tableDef[0].create_statement);
                }
            } catch (error) {
                console.error(`❌ Error processing ${tableName}:`, error);
            }
        }

        // 4. Get table constraints and indexes
        console.log('\n🔗 Getting table constraints...');
        
        const { data: constraints, error: constraintsError } = await supabase.rpc('sql', {
            query: `
                SELECT 
                    tc.table_name,
                    tc.constraint_name,
                    tc.constraint_type,
                    kcu.column_name,
                    ccu.table_name AS references_table,
                    ccu.column_name AS references_column
                FROM information_schema.table_constraints AS tc
                LEFT JOIN information_schema.key_column_usage AS kcu
                    ON tc.constraint_name = kcu.constraint_name
                LEFT JOIN information_schema.constraint_column_usage AS ccu
                    ON ccu.constraint_name = tc.constraint_name
                WHERE tc.table_schema = 'public'
                AND tc.table_name IN ('classroom_details', 'classroom_members', 'favicons')
                ORDER BY tc.table_name, tc.constraint_type;
            `
        });

        if (constraintsError) {
            console.error('❌ Error getting constraints:', constraintsError);
        } else if (constraints) {
            console.log('✅ Table constraints:');
            console.log(JSON.stringify(constraints, null, 2));
        }

    } catch (error) {
        console.error('❌ General error:', error);
    }
}

// Alternative method using direct SQL queries
async function extractWithDirectSQL() {
    console.log('🔍 Using direct SQL approach...\n');

    const queries = [
        // Get column information
        {
            name: 'Column Structures',
            query: `
                SELECT 
                    table_name,
                    column_name,
                    data_type,
                    is_nullable,
                    column_default,
                    character_maximum_length,
                    ordinal_position
                FROM information_schema.columns
                WHERE table_schema = 'public' 
                AND table_name IN ('classroom_details', 'classroom_members', 'favicons')
                ORDER BY table_name, ordinal_position;
            `
        },
        // Get favicons data
        {
            name: 'Favicons Data',
            query: 'SELECT * FROM favicons;'
        },
        // Get table info
        {
            name: 'Table Information',
            query: `
                SELECT 
                    table_name,
                    table_type
                FROM information_schema.tables
                WHERE table_schema = 'public' 
                AND table_name IN ('classroom_details', 'classroom_members', 'favicons');
            `
        }
    ];

    for (const queryInfo of queries) {
        try {
            console.log(`📊 Running: ${queryInfo.name}`);
            
            const { data, error } = await supabase.rpc('exec_sql', {
                sql: queryInfo.query
            });

            if (error) {
                console.error(`❌ Error in ${queryInfo.name}:`, error);
            } else {
                console.log(`✅ ${queryInfo.name} results:`);
                console.log(JSON.stringify(data, null, 2));
            }
            console.log('\n' + '='.repeat(50) + '\n');
        } catch (error) {
            console.error(`❌ Exception in ${queryInfo.name}:`, error);
        }
    }
}

// Main execution
async function main() {
    console.log('🚀 Starting table structure extraction...\n');
    console.log('Old Project URL:', OLD_SUPABASE_URL);
    console.log('Target Tables: classroom_details, classroom_members, favicons\n');

    if (OLD_SUPABASE_ANON_KEY === 'YOUR_OLD_PROJECT_ANON_KEY_HERE') {
        console.error('❌ Please replace OLD_SUPABASE_ANON_KEY with the actual key from your old project');
        return;
    }

    // Try both methods
    await extractTableStructures();
    console.log('\n' + '='.repeat(80) + '\n');
    await extractWithDirectSQL();
}

// Export for use in other scripts
module.exports = {
    extractTableStructures,
    extractWithDirectSQL
};

// Run if called directly
if (require.main === module) {
    main().catch(console.error);
}