const { Client } = require('pg');

async function fixFlashcardSetsRLS() {
  const client = new Client({
    connectionString: 'postgresql://postgres.aeijlzokobuqcyznljvn:Palacs1nta@aws-0-eu-north-1.pooler.supabase.com:6543/postgres',
    ssl: { rejectUnauthorized: false }
  });

  try {
    await client.connect();
    console.log('🔗 Connected to supabase-new database');
    
    // First check current policies
    const policies = await client.query(`
      SELECT policyname, cmd, qual, with_check 
      FROM pg_policies 
      WHERE tablename = 'flashcard_sets' 
      AND schemaname = 'public'
      ORDER BY policyname;
    `);
    
    console.log('📋 Current policies:');
    policies.rows.forEach(policy => {
      console.log(`  - ${policy.policyname} (${policy.cmd})`);
    });
    
    // Drop conflicting policy
    console.log('🗑️ Removing conflicting policy...');
    await client.query(`
      DROP POLICY IF EXISTS "Users can manage their own flashcard sets" ON flashcard_sets;
    `);
    
    console.log('✅ Conflicting policy removed');
    
    // Verify remaining policies
    const remainingPolicies = await client.query(`
      SELECT policyname, cmd, qual, with_check 
      FROM pg_policies 
      WHERE tablename = 'flashcard_sets' 
      AND schemaname = 'public'
      ORDER BY policyname;
    `);
    
    console.log('📋 Remaining policies:');
    remainingPolicies.rows.forEach(policy => {
      console.log(`  - ${policy.policyname} (${policy.cmd})`);
    });
    
    console.log('🎉 RLS policy fix completed!');
    
  } catch (error) {
    console.error('💥 RLS fix failed:', error);
  } finally {
    await client.end();
  }
}

fixFlashcardSetsRLS();