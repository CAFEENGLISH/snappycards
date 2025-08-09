/**
 * DEBUG SCRIPT: Check database structure and existing data
 */

const { createClient } = require('@supabase/supabase-js');

const SUPABASE_URL = 'https://aeijlzokobuqcyznljvn.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFlaWpsem9rb2J1cWN5em5sanZuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ1NjYwNTYsImV4cCI6MjA3MDE0MjA1Nn0.Kva8czOdONqJp2512w_94dcRq8ZPkYOnLT9oRsldmJM';

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

async function checkDatabaseStructure() {
    console.log('🔍 DEBUG: Checking database structure...');
    
    // List of tables to check
    const tablesToCheck = [
        'user_profiles',
        'flashcard_sets',
        'flashcard_set_cards',
        'flashcard_set_categories',
        'categories',
        'user_card_progress',
        'user_set_progress',
        'study_sessions'
    ];
    
    for (const table of tablesToCheck) {
        try {
            console.log(`\n🔍 DEBUG: Checking table "${table}"...`);
            
            // Try to get the structure by selecting 0 rows
            const { data, error } = await supabase
                .from(table)
                .select('*')
                .limit(0);
                
            if (error) {
                console.log(`❌ DEBUG: Table "${table}" error:`, error.message);
            } else {
                console.log(`✅ DEBUG: Table "${table}" exists`);
                
                // Now try to count rows
                const { count, error: countError } = await supabase
                    .from(table)
                    .select('*', { count: 'exact', head: true });
                    
                if (countError) {
                    console.log(`⚠️  DEBUG: Cannot count rows in "${table}":`, countError.message);
                } else {
                    console.log(`📊 DEBUG: Table "${table}" has ${count} rows`);
                    
                    // If table has data, show a sample
                    if (count > 0) {
                        const { data: sampleData, error: sampleError } = await supabase
                            .from(table)
                            .select('*')
                            .limit(3);
                            
                        if (!sampleError && sampleData) {
                            console.log(`📄 DEBUG: Sample data from "${table}":`, sampleData);
                        }
                    }
                }
            }
        } catch (error) {
            console.log(`❌ DEBUG: Unexpected error checking "${table}":`, error.message);
        }
    }
    
    // Check auth.users - this is a special system table
    console.log('\n🔍 DEBUG: Checking authentication status...');
    try {
        const { data: { session }, error } = await supabase.auth.getSession();
        
        if (error) {
            console.log('❌ DEBUG: Auth session error:', error.message);
        } else if (!session) {
            console.log('❌ DEBUG: No active auth session');
        } else {
            console.log('✅ DEBUG: Active auth session found');
            console.log('🔍 DEBUG: User ID:', session.user.id);
            console.log('🔍 DEBUG: User email:', session.user.email);
        }
    } catch (error) {
        console.log('❌ DEBUG: Auth check error:', error.message);
    }
}

checkDatabaseStructure();