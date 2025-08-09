#!/usr/bin/env node

/**
 * Script to create missing tables in NEW Supabase project
 * This script uses the Supabase JS client to execute SQL DDL commands
 */

const { createClient } = require('./backend/node_modules/@supabase/supabase-js');

// NEW Supabase project configuration
const supabaseUrl = 'https://aeijlzokobuqcyznljvn.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFlaWpsem9rb2J1cWN5em5sanZuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ1NjYwNTYsImV4cCI6MjA3MDE0MjA1Nn0.Kva8czOdONqJp2512w_94dcRq8ZPkYOnLT9oRsldmJM';

const supabase = createClient(supabaseUrl, supabaseKey);

async function createMissingTables() {
    console.log('🏗️  Creating missing tables in NEW Supabase project...');
    console.log('====================================================');

    try {
        // 1. Create favicons table
        console.log('1️⃣ Creating favicons table...');
        const { data: faviconsResult, error: faviconsError } = await supabase.rpc('exec_sql', {
            sql: `
                CREATE TABLE IF NOT EXISTS favicons (
                    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
                    name TEXT NOT NULL,
                    data_url TEXT NOT NULL,
                    mime_type TEXT NOT NULL,
                    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
                    is_active BOOLEAN DEFAULT true
                );
            `
        });

        if (faviconsError) {
            console.log('⚠️  Using direct table creation approach...');
            
            // Try inserting the favicon data directly using the REST API
            console.log('2️⃣ Inserting favicon data...');
            const { data: faviconData, error: faviconInsertError } = await supabase
                .from('favicons')
                .insert([{
                    id: '410ad964-fdee-4a87-8d72-1e359aa209c9',
                    name: 'SnappyCards Main Favicon',
                    data_url: 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMzIiIGhlaWdodD0iMzIiIHZpZXdCb3g9IjAgMCAzMiAzMiIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KPCEtLSBCYWNrZ3JvdW5kIC0tPgo8cmVjdCB3aWR0aD0iMzIiIGhlaWdodD0iMzIiIHJ4PSI0IiBmaWxsPSIjNjM2NmYxIi8+CjwhLS0gQ2FyZCBTaGFwZSAtLT4KPHJlY3QgeD0iNCIgeT0iNiIgd2lkdGg9IjI0IiBoZWlnaHQ9IjE2IiByeD0iMyIgZmlsbD0iI2ZmZmZmZiIgc3Ryb2tlPSIjZGRkZGRkIiBzdHJva2Utd2lkdGg9IjAuNSIvPgo8IS0tIFRleHQgUyAtLT4KPHRleHQgeD0iMTYiIHk9IjE4IiBmb250LWZhbWlseT0iQXJpYWwsIHNhbnMtc2VyaWYiIGZvbnQtc2l6ZT0iMTQiIGZvbnQtd2VpZ2h0PSJib2xkIiBmaWxsPSIjNjM2NmYxIiB0ZXh0LWFuY2hvcj0ibWlkZGxlIiBkb21pbmFudC1iYXNlbGluZT0iY2VudHJhbCI+UzwvdGV4dD4KPCEtLSBTbWFsbCBkb3RzIGZvciBmbGFzaGNhcmQgZWZmZWN0IC0tPgo8Y2lyY2xlIGN4PSI4IiBjeT0iMTAiIHI9IjEiIGZpbGw9IiM2MzY2ZjEiLz4KPGNpcmNsZSBjeD0iMjQiIGN5PSIxOCIgcj0iMSIgZmlsbD0iIzYzNjZmMSIvPgo8L3N2Zz4K',
                    mime_type: 'image/svg+xml',
                    created_at: '2025-08-04T22:18:16.773773+00:00',
                    is_active: true
                }]);

            if (faviconInsertError) {
                console.error('❌ Failed to insert favicon data:', faviconInsertError.message);
            } else {
                console.log('✅ Favicon data inserted successfully!');
            }
        } else {
            console.log('✅ Favicons table created successfully!');
        }

        // 3. Test table access
        console.log('3️⃣ Testing table access...');
        const { data: testData, error: testError } = await supabase
            .from('favicons')
            .select('*')
            .limit(1);

        if (testError) {
            console.error('❌ Table access test failed:', testError.message);
        } else {
            console.log('✅ Table access test successful!');
            console.log('📊 Favicon data:', testData);
        }

        console.log('\n🎉 Script completed!');
        console.log('📝 Note: Some tables may need to be created manually via SQL Editor in Supabase Dashboard');

    } catch (error) {
        console.error('❌ Script failed:', error.message);
        console.log('\n💡 Alternative approach:');
        console.log('1. Go to Supabase Dashboard → SQL Editor');
        console.log('2. Run the create-missing-tables.sql script manually');
        console.log('3. This will create all missing tables with proper RLS policies');
    }
}

// Run the script
createMissingTables();