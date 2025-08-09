const { createClient } = require('@supabase/supabase-js');

// Supabase configuration
const supabaseUrl = 'https://aeijlzokobuqcyznljvn.supabase.co';
const supabaseServiceKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFlaWpsem9rb2J1cWN5em5sanZuIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NDU2NjA1NiwiZXhwIjoyMDcwMTQyMDU2fQ.wwrrCv8xd3uECT24fBKasPk5MJPz3hlS_32jzJebbhs';
const supabase = createClient(supabaseUrl, supabaseServiceKey);

async function debugUserAndSets() {
    console.log('🔍 Starting user and sets debugging...\n');

    // 1. Check all users with email vidamkos@gmail.com
    console.log('1. 👤 Checking users with email vidamkos@gmail.com:');
    try {
        const { data: authUsers } = await supabase.auth.admin.listUsers();
        const targetUsers = authUsers.users.filter(user => user.email === 'vidamkos@gmail.com');
        
        console.log(`Found ${targetUsers.length} auth users:`);
        targetUsers.forEach(user => {
            console.log(`  - ID: ${user.id}`);
            console.log(`  - Email: ${user.email}`);
            console.log(`  - Confirmed: ${user.email_confirmed_at ? 'Yes' : 'No'}`);
            console.log(`  - Role: ${user.user_metadata?.user_role || 'Not set'}`);
            console.log(`  - Name: ${user.user_metadata?.first_name || 'Not set'}`);
            console.log('  ---');
        });
    } catch (error) {
        console.error('  ❌ Error checking auth users:', error.message);
    }

    // 2. Check user_profiles table
    console.log('\n2. 📋 Checking user_profiles table:');
    try {
        const { data: profiles, error } = await supabase
            .from('user_profiles')
            .select('*')
            .or('email.eq.vidamkos@gmail.com,id.eq.1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3,id.eq.9802312d-e7ce-4005-994b-ee9437fb5326');
        
        if (error) {
            console.error('  ❌ Error:', error.message);
        } else {
            console.log(`  Found ${profiles.length} profiles:`);
            profiles.forEach(profile => {
                console.log(`    - ID: ${profile.id}`);
                console.log(`    - Email: ${profile.email}`);
                console.log(`    - Name: ${profile.first_name} ${profile.last_name}`);
                console.log(`    - Role: ${profile.user_role}`);
                console.log(`    - School: ${profile.school_id}`);
                console.log('    ---');
            });
        }
    } catch (error) {
        console.error('  ❌ Error checking user profiles:', error.message);
    }

    // 3. Check flashcard_sets for both possible user IDs
    console.log('\n3. 🎴 Checking flashcard_sets:');
    const userIds = ['1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3', '9802312d-e7ce-4005-994b-ee9437fb5326'];
    
    for (const userId of userIds) {
        console.log(`\n  Checking sets for user ID: ${userId}`);
        try {
            const { data: sets, error } = await supabase
                .from('flashcard_sets')
                .select('id, title, description, user_id, created_at, language_a, language_b')
                .eq('user_id', userId);
            
            if (error) {
                console.error(`    ❌ Error: ${error.message}`);
            } else {
                console.log(`    Found ${sets.length} sets:`);
                sets.forEach(set => {
                    console.log(`      - ID: ${set.id}`);
                    console.log(`      - Title: "${set.title}"`);
                    console.log(`      - Description: ${set.description || 'None'}`);
                    console.log(`      - Languages: ${set.language_a} → ${set.language_b}`);
                    console.log(`      - Created: ${set.created_at}`);
                    console.log('      ---');
                });
            }
        } catch (error) {
            console.error(`    ❌ Error checking sets for ${userId}:`, error.message);
        }
    }

    // 4. Look for "konyha" set specifically
    console.log('\n4. 🔍 Searching for "konyha" set:');
    try {
        const { data: konyhaSet, error } = await supabase
            .from('flashcard_sets')
            .select('*')
            .eq('id', '438fcd77-e21a-45b3-9c0c-d370d54c3420');
        
        if (error) {
            console.error('  ❌ Error:', error.message);
        } else if (konyhaSet.length === 0) {
            console.log('  ❌ "konyha" set not found with specific ID');
        } else {
            console.log('  ✅ Found "konyha" set:');
            console.log('    ID:', konyhaSet[0].id);
            console.log('    Title:', konyhaSet[0].title);
            console.log('    User ID:', konyhaSet[0].user_id);
            console.log('    Description:', konyhaSet[0].description);
            console.log('    Created:', konyhaSet[0].created_at);
        }
    } catch (error) {
        console.error('  ❌ Error searching for konyha set:', error.message);
    }

    // 5. Check database schema relationships
    console.log('\n5. 🗄️ Checking table relationships:');
    try {
        // Check if flashcard_set_cards table exists
        const { data: cards, error: cardsError } = await supabase
            .from('flashcard_set_cards')
            .select('*')
            .limit(1);
        
        if (cardsError) {
            console.error('  ❌ flashcard_set_cards table issue:', cardsError.message);
        } else {
            console.log('  ✅ flashcard_set_cards table accessible');
        }

        // Check if flashcard_set_categories table exists  
        const { data: categories, error: catError } = await supabase
            .from('flashcard_set_categories')
            .select('*')
            .limit(1);
        
        if (catError) {
            console.error('  ❌ flashcard_set_categories table issue:', catError.message);
        } else {
            console.log('  ✅ flashcard_set_categories table accessible');
        }
    } catch (error) {
        console.error('  ❌ Error checking table relationships:', error.message);
    }

    console.log('\n✅ Debug complete!\n');
}

// Run the debug
debugUserAndSets().catch(console.error);