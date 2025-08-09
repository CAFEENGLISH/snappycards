/**
 * DEBUG SCRIPT: Student Dashboard Flashcard Set Loading Issue
 * This script simulates the debugging process to understand why the "konyha" 
 * flashcard set is not appearing on the student dashboard.
 */

const { createClient } = require('@supabase/supabase-js');

// Configuration from supabase.js
const SUPABASE_URL = 'https://aeijlzokobuqcyznljvn.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFlaWpsem9rb2J1cWN5em5sanZuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ1NjYwNTYsImV4cCI6MjA3MDE0MjA1Nn0.Kva8czOdONqJp2512w_94dcRq8ZPkYOnLT9oRsldmJM';

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// Target flashcard set details
const TARGET_SET_ID = '438fcd77-e21a-45b3-9c0c-d370d54c3420';
const TARGET_USER_ID = '1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3';
const TARGET_SET_TITLE = 'konyha';

async function debugDashboardIssue() {
    console.log('🔍 DEBUG: Starting dashboard debugging...');
    console.log('🔍 DEBUG: Target set ID:', TARGET_SET_ID);
    console.log('🔍 DEBUG: Target user ID:', TARGET_USER_ID);
    
    try {
        // Step 1: Check authentication status
        console.log('🔍 DEBUG: Step 1 - Checking authentication...');
        const { data: { user }, error: authError } = await supabase.auth.getUser();
        
        if (authError) {
            console.log('❌ DEBUG: Auth error:', authError.message);
            return;
        }
        
        if (!user) {
            console.log('❌ DEBUG: No authenticated user found');
            return;
        }
        
        console.log('✅ DEBUG: Current authenticated user:', user.id);
        console.log('🔍 DEBUG: User email:', user.email);
        
        // Step 2: Check if the target set exists in the database
        console.log('🔍 DEBUG: Step 2 - Checking if target set exists...');
        const { data: targetSet, error: targetSetError } = await supabase
            .from('flashcard_sets')
            .select('*')
            .eq('id', TARGET_SET_ID)
            .single();
            
        if (targetSetError) {
            console.log('❌ DEBUG: Target set query error:', targetSetError.message);
            return;
        }
        
        if (!targetSet) {
            console.log('❌ DEBUG: Target set not found in database');
            return;
        }
        
        console.log('✅ DEBUG: Target set found:', targetSet);
        console.log('🔍 DEBUG: Set user_id:', targetSet.user_id);
        console.log('🔍 DEBUG: Set title:', targetSet.title);
        console.log('🔍 DEBUG: Set is_public:', targetSet.is_public);
        
        // Step 3: Simulate the exact query from student dashboard (own sets)
        console.log('🔍 DEBUG: Step 3 - Simulating dashboard own sets query...');
        const { data: ownSetsResponse, error: ownSetsError } = await supabase
            .from('flashcard_sets')
            .select('id, title, description, created_at, language_a, language_b, language_a_code, language_b_code, flashcard_set_cards (card_id), flashcard_set_categories (category_id, categories!flashcard_set_categories_category_id_fkey (id, name))')
            .eq('user_id', user.id);
            
        if (ownSetsError) {
            console.log('❌ DEBUG: Own sets query error:', ownSetsError.message);
        } else {
            console.log('🔍 DEBUG - Own sets response:', ownSetsResponse);
            const targetSetInOwn = ownSetsResponse?.find(set => set.id === TARGET_SET_ID);
            if (targetSetInOwn) {
                console.log('✅ DEBUG: Target set FOUND in own sets!');
                console.log('🔍 DEBUG SZETT: target set details:', targetSetInOwn);
            } else {
                console.log('❌ DEBUG: Target set NOT FOUND in own sets');
                console.log('🔍 DEBUG: Current user ID vs target user ID:', user.id, 'vs', TARGET_USER_ID);
                console.log('🔍 DEBUG: User IDs match:', user.id === TARGET_USER_ID);
            }
        }
        
        // Step 4: Check if target set appears in public sets query
        console.log('🔍 DEBUG: Step 4 - Checking public sets query...');
        const { data: publicSetsResponse, error: publicSetsError } = await supabase
            .from('flashcard_sets')
            .select('id, title, description, created_at, language_a, language_b, language_a_code, language_b_code, flashcard_set_cards (card_id), flashcard_set_categories (category_id, categories!flashcard_set_categories_category_id_fkey (id, name))')
            .eq('is_public', true)
            .neq('user_id', user.id);
            
        if (publicSetsError) {
            console.log('❌ DEBUG: Public sets query error:', publicSetsError.message);
        } else {
            const targetSetInPublic = publicSetsResponse?.find(set => set.id === TARGET_SET_ID);
            if (targetSetInPublic) {
                console.log('✅ DEBUG: Target set FOUND in public sets');
            } else {
                console.log('❌ DEBUG: Target set NOT FOUND in public sets');
            }
        }
        
        // Step 5: Check the user's authentication specifically for the target user
        console.log('🔍 DEBUG: Step 5 - Authentication analysis...');
        console.log('🔍 DEBUG: Expected user ID (target):', TARGET_USER_ID);
        console.log('🔍 DEBUG: Actual user ID (current):', user.id);
        
        if (user.id !== TARGET_USER_ID) {
            console.log('❌ DEBUG: AUTHENTICATION MISMATCH!');
            console.log('❌ DEBUG: User is not logged in as the owner of the "konyha" set');
            console.log('❌ DEBUG: Need to login as:', TARGET_USER_ID);
            console.log('❌ DEBUG: Currently logged in as:', user.id);
        } else {
            console.log('✅ DEBUG: Authentication is correct for target user');
        }
        
        // Step 6: Check all flashcard sets for debugging
        console.log('🔍 DEBUG: Step 6 - Listing all sets for current user...');
        const { data: allUserSets, error: allUserSetsError } = await supabase
            .from('flashcard_sets')
            .select('id, title, user_id, is_public, created_at')
            .eq('user_id', user.id);
            
        if (allUserSetsError) {
            console.log('❌ DEBUG: All user sets query error:', allUserSetsError.message);
        } else {
            console.log('🔍 DEBUG: All sets for current user:', allUserSets);
        }

    } catch (error) {
        console.log('❌ DEBUG: Unexpected error:', error.message);
    }
}

// Export for use
if (typeof module !== 'undefined') {
    module.exports = { debugDashboardIssue };
} else {
    // Browser environment
    window.debugDashboardIssue = debugDashboardIssue;
}

// Auto-run if in Node.js
if (typeof window === 'undefined') {
    debugDashboardIssue();
}