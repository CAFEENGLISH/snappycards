const { Client } = require('pg');

async function migrateConstraintsAndIndexes() {
  const client = new Client({
    connectionString: 'postgresql://postgres.aeijlzokobuqcyznljvn:Palacs1nta@aws-0-eu-north-1.pooler.supabase.com:6543/postgres',
    ssl: { rejectUnauthorized: false }
  });

  const constraints = [
    // Foreign key constraints (excluding auth.users references)
    {
      name: 'card_categories_card_id_fkey',
      sql: `
        ALTER TABLE card_categories 
        ADD CONSTRAINT card_categories_card_id_fkey 
        FOREIGN KEY (card_id) REFERENCES cards(id) ON DELETE CASCADE;
      `
    },
    {
      name: 'card_categories_category_id_fkey',
      sql: `
        ALTER TABLE card_categories 
        ADD CONSTRAINT card_categories_category_id_fkey 
        FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE;
      `
    },
    {
      name: 'flashcard_set_cards_card_id_fkey',
      sql: `
        ALTER TABLE flashcard_set_cards 
        ADD CONSTRAINT flashcard_set_cards_card_id_fkey 
        FOREIGN KEY (card_id) REFERENCES cards(id) ON DELETE CASCADE;
      `
    },
    {
      name: 'flashcard_set_cards_set_id_fkey',
      sql: `
        ALTER TABLE flashcard_set_cards 
        ADD CONSTRAINT flashcard_set_cards_set_id_fkey 
        FOREIGN KEY (set_id) REFERENCES flashcard_sets(id) ON DELETE CASCADE;
      `
    },
    {
      name: 'flashcard_set_categories_category_id_fkey',
      sql: `
        ALTER TABLE flashcard_set_categories 
        ADD CONSTRAINT flashcard_set_categories_category_id_fkey 
        FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE;
      `
    },
    {
      name: 'flashcard_set_categories_set_id_fkey',
      sql: `
        ALTER TABLE flashcard_set_categories 
        ADD CONSTRAINT flashcard_set_categories_set_id_fkey 
        FOREIGN KEY (set_id) REFERENCES flashcard_sets(id) ON DELETE CASCADE;
      `
    },
    {
      name: 'classroom_details_classroom_id_fkey',
      sql: `
        ALTER TABLE classroom_details 
        ADD CONSTRAINT classroom_details_classroom_id_fkey 
        FOREIGN KEY (classroom_id) REFERENCES classrooms(id) ON DELETE CASCADE;
      `
    },

    // Check constraints
    {
      name: 'study_sessions_direction_check',
      sql: `
        ALTER TABLE study_sessions 
        ADD CONSTRAINT study_sessions_direction_check 
        CHECK (direction = ANY (ARRAY['hu-en'::text, 'en-hu'::text, 'AtoB'::text, 'BtoA'::text]));
      `
    },
    {
      name: 'study_logs_feedback_type_enhanced_check',
      sql: `
        ALTER TABLE study_logs 
        DROP CONSTRAINT IF EXISTS study_logs_feedback_type_check;
        
        ALTER TABLE study_logs 
        ADD CONSTRAINT study_logs_feedback_type_enhanced_check 
        CHECK (feedback_type = ANY (ARRAY[
          'tudom'::text, 'bizonytalan'::text, 'tanulandó'::text,
          'easy'::text, 'medium'::text, 'hard'::text
        ]));
      `
    },
    {
      name: 'card_interactions_feedback_type_check',
      sql: `
        ALTER TABLE card_interactions 
        ADD CONSTRAINT card_interactions_feedback_type_check 
        CHECK (feedback_type = ANY (ARRAY[
          'tudom'::text, 'bizonytalan'::text, 'tanulandó'::text
        ]));
      `
    },
    {
      name: 'user_card_progress_mastery_level_enhanced_check',
      sql: `
        ALTER TABLE user_card_progress 
        DROP CONSTRAINT IF EXISTS user_card_progress_mastery_level_check;
        
        ALTER TABLE user_card_progress 
        ADD CONSTRAINT user_card_progress_mastery_level_enhanced_check 
        CHECK (mastery_level >= 0 AND mastery_level <= 3);
      `
    }
  ];

  const indexes = [
    // Performance indexes
    {
      name: 'idx_card_categories_card_id',
      sql: 'CREATE INDEX IF NOT EXISTS idx_card_categories_card_id ON card_categories (card_id);'
    },
    {
      name: 'idx_card_categories_category_id', 
      sql: 'CREATE INDEX IF NOT EXISTS idx_card_categories_category_id ON card_categories (category_id);'
    },
    {
      name: 'idx_cards_category',
      sql: 'CREATE INDEX IF NOT EXISTS idx_cards_category ON cards (category);'
    },
    {
      name: 'idx_cards_difficulty_level',
      sql: 'CREATE INDEX IF NOT EXISTS idx_cards_difficulty_level ON cards (difficulty_level);'
    },
    {
      name: 'idx_categories_name',
      sql: 'CREATE INDEX IF NOT EXISTS idx_categories_name ON categories (name);'
    },
    {
      name: 'idx_flashcard_sets_user_id',
      sql: 'CREATE INDEX IF NOT EXISTS idx_flashcard_sets_user_id ON flashcard_sets (user_id);'
    },
    {
      name: 'idx_flashcard_sets_is_public',
      sql: 'CREATE INDEX IF NOT EXISTS idx_flashcard_sets_is_public ON flashcard_sets (is_public);'
    },
    {
      name: 'idx_study_logs_user_card',
      sql: 'CREATE INDEX IF NOT EXISTS idx_study_logs_user_card ON study_logs (user_id, card_id);'
    },
    {
      name: 'idx_study_logs_user_set',
      sql: 'CREATE INDEX IF NOT EXISTS idx_study_logs_user_set ON study_logs (user_id, set_id);'
    },
    {
      name: 'idx_study_logs_created_at',
      sql: 'CREATE INDEX IF NOT EXISTS idx_study_logs_created_at ON study_logs (created_at);'
    },
    {
      name: 'idx_study_sessions_user_set_direction',
      sql: 'CREATE INDEX IF NOT EXISTS idx_study_sessions_user_set_direction ON study_sessions (user_id, set_id, direction);'
    },
    {
      name: 'idx_user_card_progress_direction',
      sql: 'CREATE INDEX IF NOT EXISTS idx_user_card_progress_direction ON user_card_progress (user_id, direction);'
    },
    {
      name: 'idx_user_card_progress_mastery',
      sql: 'CREATE INDEX IF NOT EXISTS idx_user_card_progress_mastery ON user_card_progress (mastery_level);'
    },
    {
      name: 'idx_classroom_members_classroom_user',
      sql: 'CREATE INDEX IF NOT EXISTS idx_classroom_members_classroom_user ON classroom_members (classroom_id, user_id);'
    },
    {
      name: 'idx_classrooms_teacher_id',
      sql: 'CREATE INDEX IF NOT EXISTS idx_classrooms_teacher_id ON classrooms (teacher_id);'
    },
    {
      name: 'idx_classrooms_school_id',
      sql: 'CREATE INDEX IF NOT EXISTS idx_classrooms_school_id ON classrooms (school_id);'
    }
  ];

  try {
    await client.connect();
    console.log('🔗 Connected to supabase-new database');
    
    let constraintSuccessCount = 0;
    let constraintSkipCount = 0;
    let indexSuccessCount = 0;
    let indexSkipCount = 0;

    // Add constraints
    console.log('🔒 Adding constraints...');
    for (const constraint of constraints) {
      try {
        console.log(`🔧 Adding constraint: ${constraint.name}`);
        await client.query(constraint.sql);
        console.log(`✅ Constraint added: ${constraint.name}`);
        constraintSuccessCount++;
      } catch (error) {
        if (error.message.includes('already exists') || error.message.includes('duplicate key')) {
          console.log(`⏭️  Constraint already exists: ${constraint.name}`);
          constraintSkipCount++;
        } else {
          console.error(`❌ Failed to add constraint ${constraint.name}:`, error.message);
        }
      }
    }

    // Add indexes
    console.log('📈 Adding performance indexes...');
    for (const index of indexes) {
      try {
        console.log(`🔧 Adding index: ${index.name}`);
        await client.query(index.sql);
        console.log(`✅ Index added: ${index.name}`);
        indexSuccessCount++;
      } catch (error) {
        if (error.message.includes('already exists')) {
          console.log(`⏭️  Index already exists: ${index.name}`);
          indexSkipCount++;
        } else {
          console.error(`❌ Failed to add index ${index.name}:`, error.message);
        }
      }
    }

    console.log('🎉 Constraints and indexes migration completed!');
    console.log(`📊 Results: ${constraintSuccessCount} constraints added (${constraintSkipCount} skipped), ${indexSuccessCount} indexes added (${indexSkipCount} skipped)`);

    // Get final counts
    const constraintCount = await client.query(`
      SELECT COUNT(*) as count 
      FROM information_schema.table_constraints 
      WHERE table_schema = 'public' 
      AND constraint_type IN ('FOREIGN KEY', 'CHECK', 'UNIQUE')
    `);
    
    const indexCount = await client.query(`
      SELECT COUNT(*) as count 
      FROM pg_indexes 
      WHERE schemaname = 'public'
    `);
    
    console.log(`📋 Total constraints in database: ${constraintCount.rows[0].count}`);
    console.log(`📋 Total indexes in database: ${indexCount.rows[0].count}`);

  } catch (error) {
    console.error('💥 Constraints and indexes migration failed:', error);
  } finally {
    await client.end();
  }
}

migrateConstraintsAndIndexes();