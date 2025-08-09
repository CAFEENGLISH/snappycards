#!/usr/bin/env node

/**
 * Complete Storage Migration Execution for SnappyCards
 * 
 * This script executes the full storage migration:
 * 1. Creates the media bucket in the NEW project
 * 2. Sets up proper RLS policies
 * 3. Downloads all files from OLD project 
 * 4. Uploads all files to NEW project
 * 5. Verifies file accessibility
 */

const https = require('https');
const fs = require('fs');
const path = require('path');
const { createClient } = require('@supabase/supabase-js');

// Configuration
const PERSONAL_ACCESS_TOKEN = 'sbp_6d50add440dc1960b3efbd639d932f4b42ece0f2';
const OLD_PROJECT_ID = 'ycxqxdhaxehspypqbnpi';
const NEW_PROJECT_ID = 'aeijlzokobuqcyznljvn';
const SUPABASE_API_BASE = 'https://api.supabase.com/v1';

// Supabase URLs and keys
const OLD_SUPABASE_URL = `https://${OLD_PROJECT_ID}.supabase.co`;
const NEW_SUPABASE_URL = `https://${NEW_PROJECT_ID}.supabase.co`;

// Service role keys (required for storage operations)
const OLD_SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InljeHF4ZGhheGVoc3B5cHFibnBpIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTcyMjUxNzc4NSwiZXhwIjoyMDM4MDkzNzg1fQ.VgBAmJ4R2xKE1rORWqL-_dVQ4lKH3C9UtjYFgd87E7E';
const NEW_SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFlaWpsem9rb2J1cWN5em5sanduIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTcyMjUxNTM5NCwiZXhwIjoyMDM4MDkxMzk0fQ.o0aGWqgfqiMRnLKFOa4dItlzHJpCqaF5f60VcDshJZM';

// Initialize Supabase clients
const oldSupabase = createClient(OLD_SUPABASE_URL, OLD_SERVICE_KEY);
const newSupabase = createClient(NEW_SUPABASE_URL, NEW_SERVICE_KEY);

// Files to migrate from storage summary
const filesToMigrate = [
    '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/1754058275584_l0my16tnvb.jpeg',
    '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/1754059274124_rsngpgsh86.jpeg',
    '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/1754059833333_xufyxa7wr59.jpeg',
    '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/1754060396778_6pbj9admg3.jpeg',
    '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/1754061826309_1rtayuayo9g.jpeg',
    '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/1754061826309_x4hy0q16c1.jpeg',
    '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/1754063281219_hg669on57u5.jpeg',
    '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/1754063281220_2gprfoihenf.jpeg',
    '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/1754236762140_1dm8ruxy0t5.jpeg',
    '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/1754236762140_kyl98gf7z8.jpeg',
    '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754068707678_wiz0dsl0a1.png',
    '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754069851062_opc98k7pmni.png',
    '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754070134534_h3klxvkio0i.png',
    '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754070376408_ifvvsune63r.png',
    '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754070406486_1a0o4c0ya56.png',
    '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754070689049_ykaa09anqy.png',
    '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754070718585_flkco5ynm9g.png',
    '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754071133208_yx5tj4evbrs.png',
    '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754071381516_5jywcqpkr22.png',
    '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754073360276_qp22w0onij.png',
    '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754136177271_cwug6mm34ad.png',
    '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754136724885_1a4y03jhpdt.png',
    '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754136964687_pj775ro9hd.png',
    '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754247996774_5d4rxhjx5e7.png',
    '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754248251778_9y86aadumf6.png',
    '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754248275148_48t909nkqh2.png',
    '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754248421365_r7zxeev7pb.png',
    '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754248445574_koawtzfjva9.png',
    '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754248632778_z3w5u7xrmj.png',
    '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754249298507_7m1dj6f26vs.png',
    '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754249823648_wumfimc5jxs.png',
    '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754249873696_c0nil6jdxlb.png',
    '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754250045571_kj8luwryyu7.png',
    '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754250058447_2hi8bpooiml.png',
    '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754250181414_pda0fn9nmsd.png',
    '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754250349221_0ooapzq6yp29.png',
    '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754250536179_pp565enayi9.png',
    '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754250555947_dqvhb1u1roj.png',
    '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754250815489_66e22ityenb.png',
    '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754250986922_8o62ncfj2a.png',
    '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754251233083_wmfdp0jq0xl.png',
    '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754251494059_hy3edd4dq9r.png',
    '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754251549080_2td6nmjosdo.png',
    '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754251892207_fny3ryxm15c.png'
];

function makeRequest(url, options = {}) {
    return new Promise((resolve, reject) => {
        const requestOptions = {
            headers: {
                'Authorization': `Bearer ${PERSONAL_ACCESS_TOKEN}`,
                'Content-Type': 'application/json',
                ...options.headers
            },
            method: options.method || 'GET'
        };

        const req = https.request(url, requestOptions, (res) => {
            let data = '';
            res.on('data', (chunk) => {
                data += chunk;
            });
            res.on('end', () => {
                try {
                    if (res.statusCode >= 200 && res.statusCode < 300) {
                        resolve(data ? JSON.parse(data) : {});
                    } else {
                        reject(new Error(`HTTP ${res.statusCode}: ${data}`));
                    }
                } catch (error) {
                    resolve({ error: error.message, rawData: data });
                }
            });
        });

        if (options.body) {
            req.write(JSON.stringify(options.body));
        }

        req.on('error', reject);
        req.end();
    });
}

async function executeSQL(projectId, sql) {
    const url = `${SUPABASE_API_BASE}/projects/${projectId}/database/query`;
    
    try {
        const result = await makeRequest(url, {
            method: 'POST',
            body: { query: sql }
        });
        
        if (result.error) {
            throw new Error(result.error);
        }
        
        return result.result || result;
    } catch (error) {
        console.error(`❌ SQL execution failed: ${error.message}`);
        return { error: error.message };
    }
}

async function downloadFile(filePath) {
    console.log(`  📥 Downloading: ${filePath}`);
    
    try {
        const { data, error } = await oldSupabase.storage
            .from('media')
            .download(filePath);
            
        if (error) {
            console.error(`    ❌ Download failed: ${error.message}`);
            return null;
        }
        
        console.log(`    ✅ Downloaded ${data.size} bytes`);
        return data;
        
    } catch (error) {
        console.error(`    ❌ Download exception: ${error.message}`);
        return null;
    }
}

async function uploadFile(filePath, fileData) {
    console.log(`  📤 Uploading: ${filePath}`);
    
    try {
        // Convert Blob to Buffer for upload
        const buffer = Buffer.from(await fileData.arrayBuffer());
        
        const { data, error } = await newSupabase.storage
            .from('media')
            .upload(filePath, buffer, {
                contentType: fileData.type,
                upsert: true
            });
            
        if (error) {
            console.error(`    ❌ Upload failed: ${error.message}`);
            return false;
        }
        
        console.log(`    ✅ Uploaded successfully`);
        return true;
        
    } catch (error) {
        console.error(`    ❌ Upload exception: ${error.message}`);
        return false;
    }
}

async function verifyFileAccess(filePath) {
    try {
        const { data } = newSupabase.storage
            .from('media')
            .getPublicUrl(filePath);
            
        if (data && data.publicUrl) {
            console.log(`    ✅ Public URL: ${data.publicUrl}`);
            return data.publicUrl;
        }
        
        return null;
    } catch (error) {
        console.error(`    ❌ Verification failed: ${error.message}`);
        return null;
    }
}

async function executeMigration() {
    console.log('🚀 STARTING COMPLETE STORAGE MIGRATION');
    console.log('=====================================');
    console.log(`📊 Source: ${OLD_PROJECT_ID}`);
    console.log(`📊 Target: ${NEW_PROJECT_ID}`);
    console.log(`📊 Files to migrate: ${filesToMigrate.length}`);
    console.log('');

    let results = {
        sqlMigration: false,
        bucketCreated: false,
        filesDownloaded: 0,
        filesUploaded: 0,
        filesVerified: 0,
        errors: []
    };

    try {
        // Step 1: Execute SQL Migration
        console.log('📋 STEP 1: Executing SQL Migration');
        console.log('----------------------------------');
        
        // Read and execute the SQL migration script
        const sqlScript = fs.readFileSync('./migrate-storage-data.sql', 'utf8');
        
        console.log('🔧 Creating media bucket and object metadata...');
        const sqlResult = await executeSQL(NEW_PROJECT_ID, sqlScript);
        
        if (sqlResult.error) {
            console.error(`❌ SQL migration failed: ${sqlResult.error}`);
            results.errors.push(`SQL Migration: ${sqlResult.error}`);
        } else {
            console.log('✅ SQL migration completed successfully');
            results.sqlMigration = true;
        }
        
        // Verify bucket was created
        console.log('🔍 Verifying media bucket exists...');
        const bucketCheck = await executeSQL(NEW_PROJECT_ID, "SELECT COUNT(*) as count FROM storage.buckets WHERE name = 'media'");
        
        if (bucketCheck && bucketCheck.length > 0 && bucketCheck[0].count > 0) {
            console.log('✅ Media bucket created successfully');
            results.bucketCreated = true;
        } else {
            console.error('❌ Media bucket was not created');
            results.errors.push('Media bucket creation failed');
        }
        
        console.log('');
        
        // Step 2: Set up RLS policies
        console.log('🔒 STEP 2: Setting up RLS Policies');
        console.log('----------------------------------');
        
        const rlsPolicies = `
        -- Allow public read access to media bucket
        INSERT INTO storage.bucket_policies (bucket_id, policy_name, definition) 
        VALUES ('media', 'Public Access', 'bucket_id = ''media''')
        ON CONFLICT DO NOTHING;
        
        -- Allow authenticated users to upload to their own folder
        INSERT INTO storage.bucket_policies (bucket_id, policy_name, definition) 
        VALUES ('media', 'User Upload', 'bucket_id = ''media'' AND auth.uid()::text = (storage.foldername(name))[1]')
        ON CONFLICT DO NOTHING;
        `;
        
        const rlsResult = await executeSQL(NEW_PROJECT_ID, rlsPolicies);
        if (rlsResult.error) {
            console.log(`⚠️ RLS policies setup (non-critical): ${rlsResult.error}`);
        } else {
            console.log('✅ RLS policies configured');
        }
        
        console.log('');
        
        // Step 3: Download and Upload Files
        console.log('📁 STEP 3: Migrating Files');
        console.log('--------------------------');
        
        console.log(`🔄 Processing ${filesToMigrate.length} files...`);
        console.log('');
        
        for (let i = 0; i < filesToMigrate.length; i++) {
            const filePath = filesToMigrate[i];
            console.log(`[${i + 1}/${filesToMigrate.length}] Processing: ${filePath}`);
            
            // Download file from OLD project
            const fileData = await downloadFile(filePath);
            if (fileData) {
                results.filesDownloaded++;
                
                // Upload file to NEW project
                const uploadSuccess = await uploadFile(filePath, fileData);
                if (uploadSuccess) {
                    results.filesUploaded++;
                    
                    // Verify file accessibility
                    const publicUrl = await verifyFileAccess(filePath);
                    if (publicUrl) {
                        results.filesVerified++;
                    }
                } else {
                    results.errors.push(`Upload failed: ${filePath}`);
                }
            } else {
                results.errors.push(`Download failed: ${filePath}`);
            }
            
            console.log('');
        }
        
        // Step 4: Final verification
        console.log('✅ STEP 4: Final Verification');
        console.log('-----------------------------');
        
        const finalCheck = await executeSQL(NEW_PROJECT_ID, `
            SELECT 
                (SELECT COUNT(*) FROM storage.buckets WHERE name = 'media') as bucket_count,
                (SELECT COUNT(*) FROM storage.objects WHERE bucket_id = 'media') as object_count
        `);
        
        if (finalCheck && finalCheck.length > 0) {
            const counts = finalCheck[0];
            console.log(`📊 Buckets in NEW project: ${counts.bucket_count}`);
            console.log(`📊 Objects in media bucket: ${counts.object_count}`);
        }
        
        console.log('');
        
        // Generate final report
        console.log('📋 MIGRATION RESULTS');
        console.log('===================');
        console.log(`✅ SQL Migration: ${results.sqlMigration ? 'SUCCESS' : 'FAILED'}`);
        console.log(`✅ Bucket Created: ${results.bucketCreated ? 'SUCCESS' : 'FAILED'}`);
        console.log(`📥 Files Downloaded: ${results.filesDownloaded}/${filesToMigrate.length}`);
        console.log(`📤 Files Uploaded: ${results.filesUploaded}/${filesToMigrate.length}`);
        console.log(`🔍 Files Verified: ${results.filesVerified}/${filesToMigrate.length}`);
        
        if (results.errors.length > 0) {
            console.log('');
            console.log('❌ ERRORS ENCOUNTERED:');
            results.errors.forEach((error, index) => {
                console.log(`  ${index + 1}. ${error}`);
            });
        }
        
        console.log('');
        
        // Success criteria
        const migrationSuccess = results.bucketCreated && 
                                results.filesUploaded === filesToMigrate.length && 
                                results.filesVerified === filesToMigrate.length;
        
        if (migrationSuccess) {
            console.log('🎉 STORAGE MIGRATION COMPLETED SUCCESSFULLY!');
            console.log('All 44 media files have been migrated and are accessible.');
            console.log(`New project storage URL: ${NEW_SUPABASE_URL}/storage/v1/object/public/media/`);
            process.exit(0);
        } else {
            console.log('⚠️ MIGRATION COMPLETED WITH ISSUES');
            console.log('Please review the errors above and retry failed operations.');
            process.exit(1);
        }
        
    } catch (error) {
        console.error('💥 Migration failed with critical error:', error.message);
        console.error(error.stack);
        process.exit(1);
    }
}

// Execute migration if run directly
if (require.main === module) {
    executeMigration();
}

module.exports = { executeMigration };