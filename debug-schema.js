const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = 'https://aeijlzokobuqcyznljvn.supabase.co';
const supabaseServiceKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFlaWpsem9rb2J1cWN5em5sanZuIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NDU2NjA1NiwiZXhwIjoyMDcwMTQyMDU2fQ.wwrrCv8xd3uECT24fBKasPk5MJPz3hlS_32jzJebbhs';
const supabase = createClient(supabaseUrl, supabaseServiceKey);

async function debugDatabaseSchema() {
    console.log('🔍 Debugging database schema and relationships...\n');

    try {
        // Check the structure of flashcard_set_cards
        console.log('1. 📋 Checking flashcard_set_cards structure:');
        const { data: cards, error: cardsError } = await supabase
            .from('flashcard_set_cards')
            .select('*')
            .limit(5);
        
        if (cardsError) {
            console.error('  ❌ Error:', cardsError.message);
        } else {
            console.log(`  Found ${cards.length} records. Sample structure:`);
            if (cards.length > 0) {
                console.log('  Columns:', Object.keys(cards[0]));
                cards.forEach((card, i) => {
                    console.log(`    Record ${i + 1}:`, card);
                });
            }
        }

        // Check for cards related to the konyha set
        console.log('\n2. 🎴 Checking cards for konyha set (438fcd77-e21a-45b3-9c0c-d370d54c3420):');
        const { data: konyhaCards, error: konyhaError } = await supabase
            .from('flashcard_set_cards')
            .select('*')
            .eq('set_id', '438fcd77-e21a-45b3-9c0c-d370d54c3420');
        
        if (konyhaError) {
            console.error('  ❌ Error:', konyhaError.message);
        } else {
            console.log(`  Found ${konyhaCards.length} cards for konyha set`);
            konyhaCards.forEach((card, i) => {
                console.log(`    Card ${i + 1}:`, card);
            });
        }

        // Test different relationship queries
        console.log('\n3. 🔗 Testing different relationship queries:');
        
        // Try the original failing query
        console.log('  a) Original failing query:');
        try {
            const { data, error } = await supabase
                .from('flashcard_sets')
                .select('id, title, flashcard_set_cards (card_id)')
                .eq('user_id', '1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3')
                .limit(1);
            
            if (error) {
                console.error('    ❌ Error:', error.message);
            } else {
                console.log('    ✅ Success:', data);
            }
        } catch (e) {
            console.error('    ❌ Exception:', e.message);
        }

        // Try alternative query with correct foreign key
        console.log('  b) Alternative query (using set_id):');
        try {
            const { data: sets } = await supabase
                .from('flashcard_sets')
                .select('id, title')
                .eq('user_id', '1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3');

            console.log('    Sets found:', sets);

            if (sets && sets.length > 0) {
                for (const set of sets) {
                    const { data: cards } = await supabase
                        .from('flashcard_set_cards')
                        .select('card_id')
                        .eq('set_id', set.id);
                    
                    console.log(`    Cards for ${set.title}:`, cards?.length || 0);
                }
            }
        } catch (e) {
            console.error('    ❌ Exception:', e.message);
        }

        // Check what the correct column name is in flashcard_set_cards
        console.log('\n4. 🔍 Checking actual column names in flashcard_set_cards:');
        try {
            // Get schema information by trying to select with an invalid filter
            const { error } = await supabase
                .from('flashcard_set_cards')
                .select('*')
                .eq('nonexistent_column', 'test');
            
            if (error && error.message) {
                console.log('  Error message for analysis:', error.message);
            }
        } catch (e) {
            // This might give us schema info
        }

        // Try a simple select to see actual structure
        const { data: sampleCards } = await supabase
            .from('flashcard_set_cards')
            .select('*')
            .limit(1);
        
        if (sampleCards && sampleCards.length > 0) {
            console.log('  Actual columns in flashcard_set_cards:', Object.keys(sampleCards[0]));
        }

        console.log('\n5. 🎯 Testing corrected relationship query:');
        // Based on our findings, let's try the corrected query
        try {
            const { data, error } = await supabase
                .from('flashcard_sets')
                .select(`
                    id, 
                    title, 
                    description, 
                    created_at, 
                    language_a, 
                    language_b, 
                    language_a_code, 
                    language_b_code
                `)
                .eq('user_id', '1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3');
            
            if (error) {
                console.error('  ❌ Error:', error.message);
            } else {
                console.log('  ✅ Basic query success:', data);
                
                // Now add card count manually
                for (const set of data) {
                    const { data: cards, count } = await supabase
                        .from('flashcard_set_cards')
                        .select('card_id', { count: 'exact' })
                        .eq('set_id', set.id);
                    
                    set.card_count = count;
                    console.log(`    Set "${set.title}" has ${count} cards`);
                }
            }
        } catch (e) {
            console.error('  ❌ Exception:', e.message);
        }

    } catch (error) {
        console.error('❌ Debug error:', error);
    }

    console.log('\n✅ Schema debug complete!\n');
}

debugDatabaseSchema().catch(console.error);