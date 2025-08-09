/**
 * DEBUG SCRIPT: Student Dashboard with Login Simulation
 * This script tests the authentication and flashcard set loading
 */

const { createClient } = require('@supabase/supabase-js');

const SUPABASE_URL = 'https://aeijlzokobuqcyznljvn.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFlaWpsem9rb2J1cWN5em5sanZuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ1NjYwNTYsImV4cCI6MjA3MDE0MjA1Nn0.Kva8czOdONqJp2512w_94dcRq8ZPkYOnLT9oRsldmJM';

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

const TARGET_SET_ID = '438fcd77-e21a-45b3-9c0c-d370d54c3420';
const TARGET_USER_ID = '1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3';
const LOGIN_EMAIL = 'vidamkos@gmail.com';
const LOGIN_PASSWORD = 'Teaching123';

async function debugWithLogin() {
    console.log('🔍 DEBUG: Starting comprehensive dashboard debugging with login...');
    
    try {
        // Step 1: Try to login with provided credentials
        console.log('🔍 DEBUG: Step 1 - Attempting login...');
        console.log('🔍 DEBUG: Email:', LOGIN_EMAIL);
        
        const { data: loginData, error: loginError } = await supabase.auth.signInWithPassword({
            email: LOGIN_EMAIL,
            password: LOGIN_PASSWORD
        });
        
        if (loginError) {
            console.log('❌ DEBUG: Login error:', loginError.message);
            
            // Check if user exists but wrong password
            if (loginError.message.includes('Invalid login credentials')) {
                console.log('🔍 DEBUG: Checking if user exists in auth.users...');
                
                // Let's try to get more info about the authentication issue
                console.log('🔍 DEBUG: Login failed - checking user registration status...');
                
                // Try to check database for user profile
                const { data: profiles, error: profileError } = await supabase
                    .from('user_profiles')
                    .select('*')
                    .eq('email', LOGIN_EMAIL);
                    
                if (profileError) {
                    console.log('❌ DEBUG: Profile check error:', profileError.message);
                } else if (profiles && profiles.length > 0) {
                    console.log('✅ DEBUG: User profile found:', profiles[0]);
                    console.log('🔍 DEBUG: Profile user_id:', profiles[0].id);
                } else {
                    console.log('❌ DEBUG: No user profile found for email:', LOGIN_EMAIL);
                }
            }
            
            return;
        }
        
        console.log('✅ DEBUG: Login successful!');
        console.log('🔍 DEBUG: Logged in user:', loginData.user.id);
        console.log('🔍 DEBUG: User email:', loginData.user.email);
        
        // Step 2: Compare with target user
        console.log('🔍 DEBUG: Step 2 - User ID comparison...');
        console.log('🔍 DEBUG: Current user ID:', loginData.user.id);
        console.log('🔍 DEBUG: Target user ID:', TARGET_USER_ID);
        console.log('🔍 DEBUG: IDs match:', loginData.user.id === TARGET_USER_ID);
        
        if (loginData.user.id !== TARGET_USER_ID) {
            console.log('❌ DEBUG: USER ID MISMATCH! This explains why the set is not showing up.');
            console.log('❌ DEBUG: The logged in user is different from the owner of the "konyha" set');
        }
        
        // Step 3: Check the target flashcard set
        console.log('🔍 DEBUG: Step 3 - Checking target flashcard set...');
        const { data: targetSet, error: targetSetError } = await supabase
            .from('flashcard_sets')
            .select('*')
            .eq('id', TARGET_SET_ID)
            .single();
            
        if (targetSetError) {
            console.log('❌ DEBUG: Target set error:', targetSetError.message);
        } else if (targetSet) {
            console.log('✅ DEBUG: Target set found:', {
                id: targetSet.id,
                title: targetSet.title,
                user_id: targetSet.user_id,
                is_public: targetSet.is_public,
                created_at: targetSet.created_at
            });
        } else {
            console.log('❌ DEBUG: Target set not found');
        }
        
        // Step 4: Simulate the dashboard query for own sets
        console.log('🔍 DEBUG: Step 4 - Simulating dashboard own sets query...');
        const { data: ownSets, error: ownSetsError } = await supabase
            .from('flashcard_sets')
            .select('id, title, description, created_at, language_a, language_b, language_a_code, language_b_code, flashcard_set_cards (card_id), flashcard_set_categories (category_id, categories!flashcard_set_categories_category_id_fkey (id, name))')
            .eq('user_id', loginData.user.id);
        
        if (ownSetsError) {
            console.log('❌ DEBUG: Own sets query error:', ownSetsError.message);
        } else {
            console.log('🔍 DEBUG - Own sets response:', ownSets?.length, 'sets found');
            
            if (ownSets && ownSets.length > 0) {
                console.log('🔍 DEBUG - Own sets titles:', ownSets.map(set => set.title));
                
                const targetSetFound = ownSets.find(set => set.id === TARGET_SET_ID);
                if (targetSetFound) {
                    console.log('✅ DEBUG: Target set FOUND in own sets!');
                    console.log('🔍 DEBUG SZETT:', targetSetFound.title);
                } else {
                    console.log('❌ DEBUG: Target set NOT found in own sets');
                }
            } else {
                console.log('❌ DEBUG: No own sets found for current user');
            }
        }
        
        // Step 5: Check all flashcard sets that include the target set title
        console.log('🔍 DEBUG: Step 5 - Searching for sets with "konyha" title...');
        const { data: konyhaSets, error: konyhaSetsError } = await supabase
            .from('flashcard_sets')
            .select('id, title, user_id, is_public, created_at')
            .ilike('title', '%konyha%');
            
        if (konyhaSetsError) {
            console.log('❌ DEBUG: Konyha sets search error:', konyhaSetsError.message);
        } else {
            console.log('🔍 DEBUG: Found sets with "konyha" in title:', konyhasets?.length || 0);
            if (konyhasets && konyhasets.length > 0) {
                konyhasets.forEach(set => {
                    console.log('🔍 DEBUG: Konyha set:', {
                        id: set.id,
                        title: set.title,
                        user_id: set.user_id,
                        is_public: set.is_public,
                        is_target: set.id === TARGET_SET_ID
                    });
                });
            }
        }
        
        // Step 6: Check user profile information
        console.log('🔍 DEBUG: Step 6 - User profile information...');
        const { data: userProfile, error: userProfileError } = await supabase
            .from('user_profiles')
            .select('*')
            .eq('id', loginData.user.id)
            .single();
            
        if (userProfileError) {
            console.log('❌ DEBUG: User profile error:', userProfileError.message);
        } else if (userProfile) {
            console.log('✅ DEBUG: User profile found:', {
                id: userProfile.id,
                email: userProfile.email,
                role: userProfile.role,
                first_name: userProfile.first_name,
                last_name: userProfile.last_name
            });
        }
        
        console.log('\n🎯 DEBUG: ANALYSIS COMPLETE');
        console.log('=====================================');
        
    } catch (error) {
        console.log('❌ DEBUG: Unexpected error:', error.message);
    }
}

debugWithLogin();