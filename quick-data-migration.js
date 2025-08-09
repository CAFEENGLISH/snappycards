const { Client } = require('pg');

async function quickDataMigration() {
  const client = new Client({
    connectionString: 'postgresql://postgres.aeijlzokobuqcyznljvn:Palacs1nta@aws-0-eu-north-1.pooler.supabase.com:6543/postgres',
    ssl: { rejectUnauthorized: false }
  });

  try {
    await client.connect();
    console.log('🔗 Connected to target database');

    // Insert user profiles
    const users = [
      {
        id: 'af117cb0-e7b8-4f56-8e44-d8822462d95d',
        first_name: 'Zsolt',
        last_name: 'Tasnadi', 
        user_role: 'school_admin',
        email: 'zsolt.tasnadi@gmail.com',
        school_id: '357d81d3-084e-4420-95cd-5556c98d902a',
        created_at: '2025-08-05 11:09:52.336411+00',
        updated_at: '2025-08-05 11:10:53.06969+00'
      },
      {
        id: '54de9310-332d-481d-9b7e-b6cfaf0aacfa',
        first_name: 'Brad',
        last_name: 'Pitt',
        user_role: 'teacher', 
        email: 'brad.pitt.budapest@gmail.com',
        created_at: '2025-08-05 11:09:52.336411+00',
        updated_at: '2025-08-05 11:10:53.06969+00'
      },
      {
        id: '9802312d-e7ce-4005-994b-ee9437fb5326',
        first_name: 'Vidam',
        last_name: 'Kós',
        user_role: 'student',
        email: 'vidamkos@gmail.com', 
        stored_password: 'Palacs1nta',
        created_at: '2025-08-05 11:09:52.336411+00',
        updated_at: '2025-08-07 10:13:27.120907+00'
      }
    ];

    console.log('👤 Inserting user profiles...');
    for (const user of users) {
      await client.query(
        `INSERT INTO user_profiles (id, first_name, last_name, user_role, email, school_id, stored_password, created_at, updated_at, is_mock)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, false)
         ON CONFLICT (id) DO UPDATE SET
           first_name = EXCLUDED.first_name,
           last_name = EXCLUDED.last_name,
           user_role = EXCLUDED.user_role,
           email = EXCLUDED.email,
           updated_at = EXCLUDED.updated_at`,
        [user.id, user.first_name, user.last_name, user.user_role, user.email, user.school_id, user.stored_password, user.created_at, user.updated_at]
      );
      console.log(`✅ Inserted user: ${user.first_name} ${user.last_name}`);
    }

    // Insert school
    console.log('🏫 Inserting school...');
    await client.query(
      `INSERT INTO schools (id, name, description, contact_email, is_active, created_at, updated_at, is_mock)
       VALUES ($1, $2, $3, $4, $5, $6, $7, false)
       ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name`,
      ['357d81d3-084e-4420-95cd-5556c98d902a', 'Test School', 'Test school for development', 'admin@testschool.com', true, new Date(), new Date()]
    );
    console.log('✅ Inserted school');

    // Insert waitlist entry  
    console.log('📋 Inserting waitlist entry...');
    await client.query(
      `INSERT INTO waitlist (id, email, confirmed, created_at, updated_at, is_mock)
       VALUES ($1, $2, $3, $4, $5, false)
       ON CONFLICT (email) DO UPDATE SET confirmed = EXCLUDED.confirmed`,
      ['12345678-1234-1234-1234-123456789012', 'test@example.com', false, new Date(), new Date()]
    );
    console.log('✅ Inserted waitlist entry');

    console.log('🎉 Quick data migration completed!');

    // Verify
    const userCount = await client.query('SELECT COUNT(*) as count FROM user_profiles');
    const schoolCount = await client.query('SELECT COUNT(*) as count FROM schools');
    const waitlistCount = await client.query('SELECT COUNT(*) as count FROM waitlist');
    
    console.log(`📊 Final verification:`);
    console.log(`   👤 Users: ${userCount.rows[0].count}`);
    console.log(`   🏫 Schools: ${schoolCount.rows[0].count}`); 
    console.log(`   📋 Waitlist: ${waitlistCount.rows[0].count}`);

  } catch (error) {
    console.error('💥 Quick migration failed:', error);
  } finally {
    await client.end();
  }
}

quickDataMigration();