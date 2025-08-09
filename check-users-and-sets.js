/**
 * DEBUG SCRIPT: Check existing users and flashcard sets
 */

const { createClient } = require('@supabase/supabase-js');

const SUPABASE_URL = 'https://aeijlzokobuqcyznljvn.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFlaWpsem9rb2J1cWN5em5sanZuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ1NjYwNTYsImV4cCI6MjA3MDE0MjA1Nn0.Kva8czOdONqJp2512w_94dcRq8ZPkYOnLT9oRsldmJM';

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

const TARGET_SET_ID = '438fcd77-e21a-45b3-9c0c-d370d54c3420';
const TARGET_USER_ID = '1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3';

async function checkUsersAndSets() {
    console.log('🔍 DEBUG: Checking existing users and sets...');
    
    try {
        // Step 1: Check all user profiles
        console.log('🔍 DEBUG: Step 1 - Checking all user profiles...');
        const { data: allProfiles, error: profilesError } = await supabase
            .from('user_profiles')
            .select('id, email, first_name, last_name, role')
            .limit(10);
            
        if (profilesError) {
            console.log('❌ DEBUG: Error fetching profiles:', profilesError.message);
        } else {
            console.log('✅ DEBUG: Found', allProfiles?.length || 0, 'user profiles:');
            allProfiles?.forEach(profile => {
                console.log('   - ID:', profile.id);
                console.log('   - Email:', profile.email);
                console.log('   - Name:', profile.first_name, profile.last_name);
                console.log('   - Role:', profile.role);
                console.log('   - Is Target User:', profile.id === TARGET_USER_ID);
                console.log('   ---');
            });
        }
        
        // Step 2: Check the specific target set
        console.log('🔍 DEBUG: Step 2 - Checking target flashcard set...');
        const { data: targetSet, error: targetSetError } = await supabase
            .from('flashcard_sets')
            .select('*')
            .eq('id', TARGET_SET_ID)
            .single();
            
        if (targetSetError) {
            console.log('❌ DEBUG: Target set error:', targetSetError.message);
        } else if (targetSet) {
            console.log('✅ DEBUG: Target set found:');
            console.log('   - ID:', targetSet.id);
            console.log('   - Title:', targetSet.title);
            console.log('   - User ID:', targetSet.user_id);
            console.log('   - Is Public:', targetSet.is_public);
            console.log('   - Created:', targetSet.created_at);
        } else {
            console.log('❌ DEBUG: Target set not found');
        }
        
        // Step 3: Check all flashcard sets
        console.log('🔍 DEBUG: Step 3 - Checking all flashcard sets...');
        const { data: allSets, error: setsError } = await supabase
            .from('flashcard_sets')
            .select('id, title, user_id, is_public, created_at')
            .order('created_at', { ascending: false })
            .limit(10);
            
        if (setsError) {
            console.log('❌ DEBUG: Error fetching sets:', setsError.message);
        } else {
            console.log('✅ DEBUG: Found', allSets?.length || 0, 'flashcard sets:');
            allSets?.forEach(set => {
                console.log('   - ID:', set.id);
                console.log('   - Title:', set.title);
                console.log('   - User ID:', set.user_id);
                console.log('   - Is Public:', set.is_public);
                console.log('   - Is Target Set:', set.id === TARGET_SET_ID);
                console.log('   ---');
            });
        }
        
        // Step 4: Find sets by title containing 'konyha'
        console.log('🔍 DEBUG: Step 4 - Searching for "konyha" sets...');
        const { data: konyhasets, error: konyhaError } = await supabase
            .from('flashcard_sets')
            .select('id, title, user_id, is_public, created_at')
            .ilike('title', '%konyha%');
            
        if (konyhaError) {
            console.log('❌ DEBUG: Konyha search error:', konyhaError.message);
        } else {
            console.log('✅ DEBUG: Found', konyhasets?.length || 0, 'sets with "konyha":');
            konyhasets?.forEach(set => {
                console.log('   - ID:', set.id);
                console.log('   - Title:', set.title);
                console.log('   - User ID:', set.user_id);
                console.log('   - Is Target Set:', set.id === TARGET_SET_ID);
                console.log('   ---');
            });
        }
        
        console.log('\n🎯 DEBUG: SUMMARY');
        console.log('=====================================');
        console.log('Target Set ID:', TARGET_SET_ID);
        console.log('Target User ID:', TARGET_USER_ID);
        
    } catch (error) {
        console.log('❌ DEBUG: Unexpected error:', error.message);
    }
}

checkUsersAndSets();