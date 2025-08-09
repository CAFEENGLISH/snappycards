const { Client } = require('pg');

async function runMigrations() {
  const client = new Client({
    connectionString: 'postgresql://postgres.aeijlzokobuqcyznljvn:Palacs1nta@aws-0-eu-north-1.pooler.supabase.com:6543/postgres',
    ssl: { rejectUnauthorized: false }
  });

  const migrations = [
    {
      name: 'create_waitlist_table',
      sql: `-- Create waitlist table
CREATE TABLE IF NOT EXISTS waitlist (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT UNIQUE NOT NULL,
    name TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    confirmed BOOLEAN DEFAULT FALSE
);

-- Enable RLS
ALTER TABLE waitlist ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Allow public read on waitlist" ON waitlist FOR SELECT USING (true);
CREATE POLICY "Allow public insert on waitlist" ON waitlist FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow public update on waitlist" ON waitlist FOR UPDATE USING (true);

-- Grant permissions
GRANT SELECT, INSERT, UPDATE ON waitlist TO anon;
GRANT SELECT, INSERT, UPDATE ON waitlist TO authenticated;`
    },
    {
      name: 'create_snappy_cards_tables',
      sql: `-- Create core SnappyCards tables
CREATE TABLE IF NOT EXISTS user_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    full_name TEXT,
    role TEXT CHECK (role IN ('student', 'teacher', 'admin', 'school_admin')) DEFAULT 'student',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_mock BOOLEAN DEFAULT FALSE,
    school_id UUID,
    email TEXT,
    stored_password TEXT
);

CREATE TABLE IF NOT EXISTS schools (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    location TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_mock BOOLEAN DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_mock BOOLEAN DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS flashcard_sets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT,
    created_by UUID REFERENCES user_profiles(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    native_language TEXT DEFAULT 'hungarian',
    target_language TEXT DEFAULT 'english',
    classroom_id UUID,
    is_mock BOOLEAN DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS cards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    flashcard_set_id UUID REFERENCES flashcard_sets(id) ON DELETE CASCADE,
    front_text TEXT,
    back_text TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    front_image_url TEXT,
    back_image_url TEXT,
    is_mock BOOLEAN DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS user_card_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    card_id UUID REFERENCES cards(id) ON DELETE CASCADE,
    correct_count INTEGER DEFAULT 0,
    incorrect_count INTEGER DEFAULT 0,
    last_reviewed TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE schools ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE flashcard_sets ENABLE ROW LEVEL SECURITY;
ALTER TABLE cards ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_card_progress ENABLE ROW LEVEL SECURITY;`
    }
  ];

  try {
    await client.connect();
    console.log('Connected to database');
    
    for (const migration of migrations) {
      console.log(`Running migration: ${migration.name}`);
      await client.query(migration.sql);
      console.log(`✅ Migration ${migration.name} completed`);
    }
    
    console.log('All migrations completed successfully!');
  } catch (error) {
    console.error('Migration error:', error);
  } finally {
    await client.end();
  }
}

runMigrations();