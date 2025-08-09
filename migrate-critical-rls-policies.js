const { Client } = require('pg');

async function migrateCriticalRLSPolicies() {
  const client = new Client({
    connectionString: 'postgresql://postgres.aeijlzokobuqcyznljvn:Palacs1nta@aws-0-eu-north-1.pooler.supabase.com:6543/postgres',
    ssl: { rejectUnauthorized: false }
  });

  const criticalPolicies = [
    // 1. CLASSROOM_MEMBERS kritikus policies
    {
      table: 'classroom_members',
      name: 'Students can join classrooms',
      sql: `
        CREATE POLICY "Students can join classrooms" 
        ON classroom_members FOR INSERT 
        WITH CHECK (
          (auth.uid() = user_id) AND 
          (EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE user_profiles.id = auth.uid() 
            AND user_profiles.user_role = 'student'
          ))
        );
      `
    },
    {
      table: 'classroom_members',
      name: 'Students can leave classrooms',
      sql: `
        CREATE POLICY "Students can leave classrooms" 
        ON classroom_members FOR UPDATE 
        USING (auth.uid() = user_id);
      `
    },
    {
      table: 'classroom_members',
      name: 'Teachers can view their classroom members',
      sql: `
        CREATE POLICY "Teachers can view their classroom members" 
        ON classroom_members FOR SELECT 
        USING (
          (auth.uid() IN (
            SELECT teacher_id FROM classrooms 
            WHERE classrooms.id = classroom_members.classroom_id
          )) OR 
          (auth.uid() = user_id)
        );
      `
    },

    // 2. CLASSROOM_SETS policies
    {
      table: 'classroom_sets',
      name: 'Classroom members can view classroom sets',
      sql: `
        CREATE POLICY "Classroom members can view classroom sets" 
        ON classroom_sets FOR SELECT 
        USING (
          (classroom_id IN (
            SELECT cm.classroom_id FROM classroom_members cm 
            WHERE cm.user_id = auth.uid()
          )) OR 
          (classroom_id IN (
            SELECT c.id FROM classrooms c 
            WHERE c.teacher_id = auth.uid()
          ))
        );
      `
    },
    {
      table: 'classroom_sets',
      name: 'Teachers can manage their classroom sets',
      sql: `
        CREATE POLICY "Teachers can manage their classroom sets" 
        ON classroom_sets FOR ALL 
        USING (
          classroom_id IN (
            SELECT c.id FROM classrooms c 
            WHERE c.teacher_id = auth.uid()
          )
        );
      `
    },

    // 3. FLASHCARD_SETS enhanced policies
    {
      table: 'flashcard_sets',
      name: 'Users can create their own flashcard sets',
      sql: `
        CREATE POLICY "Users can create their own flashcard sets" 
        ON flashcard_sets FOR INSERT 
        WITH CHECK (auth.uid() = user_id);
      `
    },
    {
      table: 'flashcard_sets',  
      name: 'Users can delete their own flashcard sets',
      sql: `
        CREATE POLICY "Users can delete their own flashcard sets" 
        ON flashcard_sets FOR DELETE 
        USING (auth.uid() = user_id);
      `
    },
    {
      table: 'flashcard_sets',
      name: 'Users can read their own flashcard sets',
      sql: `
        CREATE POLICY "Users can read their own flashcard sets" 
        ON flashcard_sets FOR SELECT 
        USING (
          (auth.uid() = user_id) OR 
          (is_public = true)
        );
      `
    },
    {
      table: 'flashcard_sets',
      name: 'Users can update their own flashcard sets',
      sql: `
        CREATE POLICY "Users can update their own flashcard sets" 
        ON flashcard_sets FOR UPDATE 
        USING (auth.uid() = user_id) 
        WITH CHECK (auth.uid() = user_id);
      `
    },

    // 4. FLASHCARD_SET_CARDS policies
    {
      table: 'flashcard_set_cards',
      name: 'Users can manage cards in their own sets',
      sql: `
        CREATE POLICY "Users can manage cards in their own sets" 
        ON flashcard_set_cards FOR ALL 
        USING (
          EXISTS (
            SELECT 1 FROM flashcard_sets 
            WHERE flashcard_sets.id = flashcard_set_cards.set_id 
            AND flashcard_sets.user_id = auth.uid()
          )
        ) 
        WITH CHECK (
          EXISTS (
            SELECT 1 FROM flashcard_sets 
            WHERE flashcard_sets.id = flashcard_set_cards.set_id 
            AND flashcard_sets.user_id = auth.uid()
          )
        );
      `
    },

    // 5. FLASHCARD_SET_CATEGORIES policies
    {
      table: 'flashcard_set_categories',
      name: 'Users can manage categories for their own sets',
      sql: `
        CREATE POLICY "Users can manage categories for their own sets" 
        ON flashcard_set_categories FOR ALL 
        USING (
          EXISTS (
            SELECT 1 FROM flashcard_sets 
            WHERE flashcard_sets.id = flashcard_set_categories.set_id 
            AND flashcard_sets.user_id = auth.uid()
          )
        );
      `
    },

    // 6. CATEGORIES enhanced policies
    {
      table: 'categories',
      name: 'Authenticated users can insert categories',
      sql: `
        CREATE POLICY "Authenticated users can insert categories" 
        ON categories FOR INSERT 
        WITH CHECK (auth.role() = 'authenticated');
      `
    },
    {
      table: 'categories',
      name: 'Everyone can view categories',
      sql: `
        CREATE POLICY "Everyone can view categories" 
        ON categories FOR SELECT 
        USING (true);
      `
    },

    // 7. SCHOOLS enhanced policies
    {
      table: 'schools',
      name: 'Enable insert for authenticated users',
      sql: `
        CREATE POLICY "Enable insert for authenticated users" 
        ON schools FOR INSERT 
        WITH CHECK (auth.role() = 'authenticated');
      `
    },
    {
      table: 'schools',
      name: 'Enable read access for authenticated users',
      sql: `
        CREATE POLICY "Enable read access for authenticated users" 
        ON schools FOR SELECT 
        USING (auth.role() = 'authenticated');
      `
    },
    {
      table: 'schools',
      name: 'Enable update for authenticated users',
      sql: `
        CREATE POLICY "Enable update for authenticated users" 
        ON schools FOR UPDATE 
        USING (auth.role() = 'authenticated');
      `
    },

    // 8. USER_PROFILES enhanced policies
    {
      table: 'user_profiles',
      name: 'Anyone can insert profile on signup',
      sql: `
        CREATE POLICY "Anyone can insert profile on signup" 
        ON user_profiles FOR INSERT 
        WITH CHECK (auth.uid() = id);
      `
    },
    {
      table: 'user_profiles',
      name: 'Enable read access for authenticated users',
      sql: `
        CREATE POLICY "Enable read access for authenticated users" 
        ON user_profiles FOR SELECT 
        USING (auth.role() = 'authenticated');
      `
    },

    // 9. CARDS enhanced policies  
    {
      table: 'cards',
      name: 'Anyone can create cards',
      sql: `
        CREATE POLICY "Anyone can create cards" 
        ON cards FOR INSERT 
        WITH CHECK (true);
      `
    },
    {
      table: 'cards',
      name: 'Anyone can delete cards',
      sql: `
        CREATE POLICY "Anyone can delete cards" 
        ON cards FOR DELETE 
        USING (true);
      `
    },
    {
      table: 'cards',
      name: 'Anyone can read cards',
      sql: `
        CREATE POLICY "Anyone can read cards" 
        ON cards FOR SELECT 
        USING (true);
      `
    },
    {
      table: 'cards',
      name: 'Anyone can update cards',
      sql: `
        CREATE POLICY "Anyone can update cards" 
        ON cards FOR UPDATE 
        USING (true) 
        WITH CHECK (true);
      `
    }
  ];

  try {
    await client.connect();
    console.log('🔗 Connected to supabase-new database');
    
    let successCount = 0;
    let skipCount = 0;
    let errorCount = 0;

    for (const policy of criticalPolicies) {
      try {
        console.log(`🔐 Creating policy: ${policy.name} on ${policy.table}`);
        
        // First drop the policy if it exists to avoid conflicts
        await client.query(`DROP POLICY IF EXISTS "${policy.name}" ON ${policy.table};`);
        
        // Create the policy
        await client.query(policy.sql);
        
        console.log(`✅ Policy created: ${policy.name}`);
        successCount++;
      } catch (error) {
        if (error.message.includes('already exists')) {
          console.log(`⏭️  Policy already exists: ${policy.name}`);
          skipCount++;
        } else {
          console.error(`❌ Failed to create policy ${policy.name}:`, error.message);
          errorCount++;
        }
      }
    }

    console.log('🎉 RLS Policies migration completed!');
    console.log(`📊 Results: ${successCount} created, ${skipCount} skipped, ${errorCount} failed`);

    // Verify policies were created
    const policyCount = await client.query(`
      SELECT COUNT(*) as count 
      FROM pg_policies 
      WHERE schemaname = 'public'
    `);
    console.log(`📋 Total policies in database: ${policyCount.rows[0].count}`);

  } catch (error) {
    console.error('💥 RLS migration failed:', error);
  } finally {
    await client.end();
  }
}

migrateCriticalRLSPolicies();