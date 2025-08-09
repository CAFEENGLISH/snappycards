const { Client } = require('pg');

async function migrateCriticalData() {
  const sourceClient = new Client({
    connectionString: 'postgresql://postgres.ycxqxdhaxehspypqbnpi:Palacs1nta@aws-0-eu-north-1.pooler.supabase.com:6543/postgres',
    ssl: { rejectUnauthorized: false }
  });

  const targetClient = new Client({
    connectionString: 'postgresql://postgres.aeijlzokobuqcyznljvn:Palacs1nta@aws-0-eu-north-1.pooler.supabase.com:6543/postgres',
    ssl: { rejectUnauthorized: false }
  });

  try {
    await sourceClient.connect();
    await targetClient.connect();
    console.log('🔗 Connected to both databases');

    // 1. Migrate user_profiles (3 live records)
    console.log('👤 Migrating user_profiles...');
    const users = await sourceClient.query('SELECT * FROM user_profiles WHERE id NOT IN (SELECT id FROM user_profiles WHERE id IS NULL)');
    console.log(`Found ${users.rows.length} user profiles to migrate`);
    
    for (const user of users.rows) {
      try {
        await targetClient.query(
          `INSERT INTO user_profiles (id, first_name, last_name, email, user_role, school_id, phone, note, created_at, updated_at, stored_password, is_mock)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, COALESCE($12, false))
           ON CONFLICT (id) DO UPDATE SET
             first_name = EXCLUDED.first_name,
             last_name = EXCLUDED.last_name,
             email = EXCLUDED.email,
             user_role = EXCLUDED.user_role,
             school_id = EXCLUDED.school_id,
             phone = EXCLUDED.phone,
             note = EXCLUDED.note,
             updated_at = EXCLUDED.updated_at,
             stored_password = EXCLUDED.stored_password`,
          [user.id, user.first_name, user.last_name, user.email, user.user_role, user.school_id, user.phone, user.note, user.created_at, user.updated_at, user.stored_password, user.is_mock]
        );
        console.log(`✅ Migrated user: ${user.first_name} ${user.last_name}`);
      } catch (error) {
        console.error(`❌ Failed to migrate user ${user.id}:`, error.message);
      }
    }

    // 2. Migrate schools (1 live record)
    console.log('🏫 Migrating schools...');
    const schools = await sourceClient.query('SELECT * FROM schools WHERE id IS NOT NULL');
    console.log(`Found ${schools.rows.length} schools to migrate`);
    
    for (const school of schools.rows) {
      try {
        await targetClient.query(
          `INSERT INTO schools (id, name, description, contact_email, is_active, created_at, updated_at, address, phone, is_mock)
           VALUES ($1, $2, $3, $4, COALESCE($5, true), $6, $7, $8, $9, COALESCE($10, false))
           ON CONFLICT (id) DO UPDATE SET
             name = EXCLUDED.name,
             description = EXCLUDED.description,
             contact_email = EXCLUDED.contact_email,
             is_active = EXCLUDED.is_active,
             updated_at = EXCLUDED.updated_at,
             address = EXCLUDED.address,
             phone = EXCLUDED.phone`,
          [school.id, school.name, school.description, school.contact_email, school.is_active, school.created_at, school.updated_at, school.address, school.phone, school.is_mock]
        );
        console.log(`✅ Migrated school: ${school.name}`);
      } catch (error) {
        console.error(`❌ Failed to migrate school ${school.id}:`, error.message);
      }
    }

    // 3. Migrate waitlist (1 live record)
    console.log('📋 Migrating waitlist...');
    const waitlistEntries = await sourceClient.query('SELECT * FROM waitlist WHERE email IS NOT NULL');
    console.log(`Found ${waitlistEntries.rows.length} waitlist entries to migrate`);
    
    for (const entry of waitlistEntries.rows) {
      try {
        await targetClient.query(
          `INSERT INTO waitlist (id, email, created_at, confirmed, confirmation_token, confirmed_at, is_mock)
           VALUES ($1, $2, $3, COALESCE($4, false), $5, $6, COALESCE($7, false))
           ON CONFLICT (email) DO UPDATE SET
             confirmed = EXCLUDED.confirmed,
             confirmation_token = EXCLUDED.confirmation_token,
             confirmed_at = EXCLUDED.confirmed_at,
             updated_at = NOW()`,
          [entry.id, entry.email, entry.created_at, entry.confirmed, entry.confirmation_token, entry.confirmed_at, entry.is_mock || false]
        );
        console.log(`✅ Migrated waitlist entry: ${entry.email}`);
      } catch (error) {
        console.error(`❌ Failed to migrate waitlist entry ${entry.email}:`, error.message);
      }
    }

    // 4. Migrate favicons (1 record)
    console.log('🎨 Migrating favicons...');
    const favicons = await sourceClient.query('SELECT * FROM favicons WHERE id IS NOT NULL');
    console.log(`Found ${favicons.rows.length} favicons to migrate`);
    
    for (const favicon of favicons.rows) {
      try {
        await targetClient.query(
          `INSERT INTO favicons (id, domain, favicon_url, last_updated, is_active, fetch_attempts, last_fetch_attempt, created_at)
           VALUES ($1, $2, $3, $4, COALESCE($5, true), COALESCE($6, 0), $7, $8)
           ON CONFLICT (id) DO UPDATE SET
             domain = EXCLUDED.domain,
             favicon_url = EXCLUDED.favicon_url,
             last_updated = EXCLUDED.last_updated,
             is_active = EXCLUDED.is_active`,
          [favicon.id, favicon.name, favicon.data_url, favicon.created_at, favicon.is_active, 0, favicon.created_at, favicon.created_at]
        );
        console.log(`✅ Migrated favicon: ${favicon.name || 'unnamed'}`);
      } catch (error) {
        console.error(`❌ Failed to migrate favicon ${favicon.id}:`, error.message);
      }
    }

    console.log('🎉 Critical data migration completed!');
    
    // Final verification
    const targetUserCount = await targetClient.query('SELECT COUNT(*) as count FROM user_profiles');
    const targetSchoolCount = await targetClient.query('SELECT COUNT(*) as count FROM schools');
    const targetWaitlistCount = await targetClient.query('SELECT COUNT(*) as count FROM waitlist');
    
    console.log(`📊 Final counts in target database:`);
    console.log(`   👤 Users: ${targetUserCount.rows[0].count}`);
    console.log(`   🏫 Schools: ${targetSchoolCount.rows[0].count}`);
    console.log(`   📋 Waitlist: ${targetWaitlistCount.rows[0].count}`);

  } catch (error) {
    console.error('💥 Data migration failed:', error);
  } finally {
    await sourceClient.end();
    await targetClient.end();
  }
}

migrateCriticalData();