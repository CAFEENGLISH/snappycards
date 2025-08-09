const { Client } = require('pg');

async function checkAndFixRLS() {
  const client = new Client({
    connectionString: 'postgresql://postgres.aeijlzokobuqcyznljvn:Palacs1nta@aws-0-eu-north-1.pooler.supabase.com:6543/postgres',
    ssl: { rejectUnauthorized: false }
  });

  try {
    await client.connect();
    console.log('🔗 Connected to supabase-new database');
    
    // Check if RLS is enabled
    const rlsCheck = await client.query(`
      SELECT schemaname, tablename, rowsecurity 
      FROM pg_tables 
      WHERE tablename = 'flashcard_sets' AND schemaname = 'public';
    `);
    
    console.log('📋 RLS Status:', rlsCheck.rows);
    
    // Check current policies
    const policies = await client.query(`
      SELECT policyname, cmd, qual, with_check, roles
      FROM pg_policies 
      WHERE tablename = 'flashcard_sets' 
      AND schemaname = 'public'
      ORDER BY policyname;
    `);
    
    console.log('📋 Current policies on flashcard_sets:');
    if (policies.rows.length === 0) {
      console.log('  ❌ No policies found!');
    } else {
      policies.rows.forEach(policy => {
        console.log(`  - ${policy.policyname} (${policy.cmd})`);
        console.log(`    Roles: ${policy.roles}`);
        console.log(`    Using: ${policy.qual}`);
        console.log(`    With Check: ${policy.with_check}`);
        console.log('');
      });
    }
    
    // Check if table has RLS enabled
    if (!rlsCheck.rows[0]?.rowsecurity) {
      console.log('🔧 Enabling RLS on flashcard_sets...');
      await client.query('ALTER TABLE public.flashcard_sets ENABLE ROW LEVEL SECURITY;');
      console.log('✅ RLS enabled');
    } else {
      console.log('✅ RLS already enabled');
    }
    
    // Check for required policies and create if missing
    const requiredPolicies = [
      {
        name: "Users can create their own flashcard sets",
        sql: `CREATE POLICY "Users can create their own flashcard sets" ON public.flashcard_sets FOR INSERT TO public WITH CHECK ((auth.uid() = user_id));`
      },
      {
        name: "Users can read their own flashcard sets",
        sql: `CREATE POLICY "Users can read their own flashcard sets" ON public.flashcard_sets FOR SELECT TO public USING (((auth.uid() = user_id) OR (is_public = true)));`
      },
      {
        name: "Users can update their own flashcard sets",
        sql: `CREATE POLICY "Users can update their own flashcard sets" ON public.flashcard_sets FOR UPDATE TO public USING ((auth.uid() = user_id));`
      },
      {
        name: "Users can delete their own flashcard sets",
        sql: `CREATE POLICY "Users can delete their own flashcard sets" ON public.flashcard_sets FOR DELETE TO public USING ((auth.uid() = user_id));`
      }
    ];
    
    const existingPolicyNames = policies.rows.map(p => p.policyname);
    
    for (const policy of requiredPolicies) {
      if (!existingPolicyNames.includes(policy.name)) {
        console.log(`🔧 Creating missing policy: ${policy.name}`);
        try {
          await client.query(policy.sql);
          console.log(`✅ Policy created: ${policy.name}`);
        } catch (error) {
          console.error(`❌ Failed to create policy ${policy.name}:`, error.message);
        }
      } else {
        console.log(`✅ Policy exists: ${policy.name}`);
      }
    }
    
    // Final verification
    console.log('\n🔍 Final verification...');
    const finalPolicies = await client.query(`
      SELECT policyname, cmd 
      FROM pg_policies 
      WHERE tablename = 'flashcard_sets' 
      AND schemaname = 'public'
      ORDER BY policyname;
    `);
    
    console.log('📋 Final policy count:', finalPolicies.rows.length);
    finalPolicies.rows.forEach(policy => {
      console.log(`  ✅ ${policy.policyname} (${policy.cmd})`);
    });
    
    console.log('\n🎉 RLS check and fix completed!');
    
  } catch (error) {
    console.error('💥 RLS check failed:', error);
  } finally {
    await client.end();
  }
}

checkAndFixRLS();