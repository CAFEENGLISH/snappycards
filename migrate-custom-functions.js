const { Client } = require('pg');

async function migrateCustomFunctions() {
  const client = new Client({
    connectionString: 'postgresql://postgres.aeijlzokobuqcyznljvn:Palacs1nta@aws-0-eu-north-1.pooler.supabase.com:6543/postgres',
    ssl: { rejectUnauthorized: false }
  });

  const functions = [
    {
      name: 'generate_invite_code',
      sql: `
        CREATE OR REPLACE FUNCTION generate_invite_code(length integer DEFAULT 6)
        RETURNS text AS $$
        DECLARE
          chars text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; -- Excluding confusing characters
          result text := '';
          i integer;
        BEGIN
          FOR i IN 1..length LOOP
            result := result || substr(chars, (random() * length(chars))::integer + 1, 1);
          END LOOP;
          RETURN result;
        END;
        $$ LANGUAGE plpgsql;
      `
    },
    {
      name: 'create_classroom',
      sql: `
        CREATE OR REPLACE FUNCTION create_classroom(
          classroom_name text,
          description text DEFAULT NULL
        )
        RETURNS TABLE(classroom_id uuid, invite_code text) AS $$
        DECLARE
          new_classroom_id uuid;
          new_invite_code text;
        BEGIN
          -- Generate unique invite code
          LOOP
            new_invite_code := generate_invite_code(6);
            EXIT WHEN NOT EXISTS (
              SELECT 1 FROM classrooms WHERE access_code = new_invite_code
            );
          END LOOP;
          
          -- Create the classroom
          INSERT INTO classrooms (name, description, teacher_id, access_code, is_active)
          VALUES (classroom_name, description, auth.uid(), new_invite_code, true)
          RETURNING id INTO new_classroom_id;
          
          -- Return the results
          RETURN QUERY SELECT new_classroom_id, new_invite_code;
        END;
        $$ LANGUAGE plpgsql SECURITY DEFINER;
      `
    },
    {
      name: 'join_classroom_with_code',
      sql: `
        CREATE OR REPLACE FUNCTION join_classroom_with_code(code text)
        RETURNS TABLE(success boolean, message text, classroom_name text) AS $$
        DECLARE
          classroom_record record;
          user_id_val uuid := auth.uid();
        BEGIN
          -- Check if user is authenticated
          IF user_id_val IS NULL THEN
            RETURN QUERY SELECT false, 'User not authenticated', null::text;
            RETURN;
          END IF;
          
          -- Find classroom by code
          SELECT id, name, is_active INTO classroom_record
          FROM classrooms 
          WHERE access_code = code;
          
          IF NOT FOUND THEN
            RETURN QUERY SELECT false, 'Invalid invite code', null::text;
            RETURN;
          END IF;
          
          IF NOT classroom_record.is_active THEN
            RETURN QUERY SELECT false, 'Classroom is not active', classroom_record.name;
            RETURN;
          END IF;
          
          -- Check if user is already a member
          IF EXISTS (
            SELECT 1 FROM classroom_members 
            WHERE classroom_id = classroom_record.id 
            AND user_id = user_id_val
          ) THEN
            RETURN QUERY SELECT false, 'Already a member of this classroom', classroom_record.name;
            RETURN;
          END IF;
          
          -- Add user to classroom
          INSERT INTO classroom_members (classroom_id, user_id, role, is_active)
          VALUES (classroom_record.id, user_id_val, 'student', true);
          
          RETURN QUERY SELECT true, 'Successfully joined classroom', classroom_record.name;
        END;
        $$ LANGUAGE plpgsql SECURITY DEFINER;
      `
    },
    {
      name: 'update_updated_at_column',
      sql: `
        CREATE OR REPLACE FUNCTION update_updated_at_column()
        RETURNS TRIGGER AS $$
        BEGIN
          NEW.updated_at = NOW();
          RETURN NEW;
        END;
        $$ LANGUAGE plpgsql;
      `
    }
  ];

  const triggers = [
    {
      name: 'update_classrooms_updated_at',
      table: 'classrooms',
      sql: `
        DROP TRIGGER IF EXISTS update_classrooms_updated_at ON classrooms;
        CREATE TRIGGER update_classrooms_updated_at
          BEFORE UPDATE ON classrooms
          FOR EACH ROW
          EXECUTE FUNCTION update_updated_at_column();
      `
    },
    {
      name: 'update_user_profiles_updated_at',
      table: 'user_profiles',
      sql: `
        DROP TRIGGER IF EXISTS update_user_profiles_updated_at ON user_profiles;
        CREATE TRIGGER update_user_profiles_updated_at
          BEFORE UPDATE ON user_profiles
          FOR EACH ROW
          EXECUTE FUNCTION update_updated_at_column();
      `
    },
    {
      name: 'update_schools_updated_at',
      table: 'schools',
      sql: `
        DROP TRIGGER IF EXISTS update_schools_updated_at ON schools;
        CREATE TRIGGER update_schools_updated_at
          BEFORE UPDATE ON schools
          FOR EACH ROW
          EXECUTE FUNCTION update_updated_at_column();
      `
    },
    {
      name: 'update_categories_updated_at',
      table: 'categories',
      sql: `
        DROP TRIGGER IF EXISTS update_categories_updated_at ON categories;
        CREATE TRIGGER update_categories_updated_at
          BEFORE UPDATE ON categories
          FOR EACH ROW
          EXECUTE FUNCTION update_updated_at_column();
      `
    },
    {
      name: 'update_flashcard_sets_updated_at',
      table: 'flashcard_sets',
      sql: `
        DROP TRIGGER IF EXISTS update_flashcard_sets_updated_at ON flashcard_sets;
        CREATE TRIGGER update_flashcard_sets_updated_at
          BEFORE UPDATE ON flashcard_sets
          FOR EACH ROW
          EXECUTE FUNCTION update_updated_at_column();
      `
    }
  ];

  try {
    await client.connect();
    console.log('🔗 Connected to supabase-new database');
    
    let functionSuccessCount = 0;
    let triggerSuccessCount = 0;

    // Create functions
    console.log('📝 Creating custom functions...');
    for (const func of functions) {
      try {
        console.log(`🔧 Creating function: ${func.name}`);
        await client.query(func.sql);
        console.log(`✅ Function created: ${func.name}`);
        functionSuccessCount++;
      } catch (error) {
        console.error(`❌ Failed to create function ${func.name}:`, error.message);
      }
    }

    // Create triggers
    console.log('⚡ Creating triggers...');
    for (const trigger of triggers) {
      try {
        console.log(`🔧 Creating trigger: ${trigger.name} on ${trigger.table}`);
        await client.query(trigger.sql);
        console.log(`✅ Trigger created: ${trigger.name}`);
        triggerSuccessCount++;
      } catch (error) {
        console.error(`❌ Failed to create trigger ${trigger.name}:`, error.message);
      }
    }

    console.log('🎉 Custom functions and triggers migration completed!');
    console.log(`📊 Results: ${functionSuccessCount} functions, ${triggerSuccessCount} triggers created`);

    // Test the functions
    console.log('🧪 Testing functions...');
    try {
      const testCode = await client.query('SELECT generate_invite_code(6) as code;');
      console.log(`✅ Generated test invite code: ${testCode.rows[0].code}`);
    } catch (error) {
      console.error('❌ Function test failed:', error.message);
    }

  } catch (error) {
    console.error('💥 Functions migration failed:', error);
  } finally {
    await client.end();
  }
}

migrateCustomFunctions();