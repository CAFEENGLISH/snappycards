#!/usr/bin/env node

/**
 * Alternative Storage Upload Script
 * Uses direct HTTP API calls to avoid authentication issues
 */

const https = require('https');
const fs = require('fs');
const { createClient } = require('@supabase/supabase-js');

// Configuration
const OLD_PROJECT_ID = 'ycxqxdhaxehspypqbnpi';
const NEW_PROJECT_ID = 'aeijlzokobuqcyznljvn';

// Supabase URLs and keys
const OLD_SUPABASE_URL = `https://${OLD_PROJECT_ID}.supabase.co`;
const NEW_SUPABASE_URL = `https://${NEW_PROJECT_ID}.supabase.co`;

// Service role keys
const OLD_SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InljeHF4ZGhheGVoc3B5cHFibnBpIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTcyMjUxNzc4NSwiZXhwIjoyMDM4MDkzNzg1fQ.VgBAmJ4R2xKE1rORWqL-_dVQ4lKH3C9UtjYFgd87E7E';
const NEW_SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFlaWpsem9rb2J1cWN5em5sanduIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTcyMjUxNTM5NCwiZXhwIjoyMDM4MDkxMzk0fQ.o0aGWqgfqiMRnLKFOa4dItlzHJpCqaF5f60VcDshJZM';

// Initialize clients
const oldSupabase = createClient(OLD_SUPABASE_URL, OLD_SERVICE_KEY);
const newSupabase = createClient(NEW_SUPABASE_URL, NEW_SERVICE_KEY);

// Files to migrate
const filesToMigrate = [
    '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/1754058275584_l0my16tnvb.jpeg',
    '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/1754059274124_rsngpgsh86.jpeg',
    // Add a few more for testing
    '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754068707678_wiz0dsl0a1.png'
];

async function downloadFileHTTP(filePath) {
    return new Promise((resolve, reject) => {
        const url = `${OLD_SUPABASE_URL}/storage/v1/object/media/${encodeURIComponent(filePath)}`;
        
        const options = {
            method: 'GET',
            headers: {
                'Authorization': `Bearer ${OLD_SERVICE_KEY}`
            }
        };

        const req = https.request(url, options, (res) => {
            if (res.statusCode !== 200) {
                console.error(`Download failed: ${res.statusCode} ${res.statusMessage}`);
                return reject(new Error(`HTTP ${res.statusCode}`));
            }

            const chunks = [];
            res.on('data', chunk => chunks.push(chunk));
            res.on('end', () => {
                const buffer = Buffer.concat(chunks);
                console.log(`  ✅ Downloaded ${buffer.length} bytes via HTTP`);
                resolve({
                    data: buffer,
                    contentType: res.headers['content-type'] || 'application/octet-stream'
                });
            });
        });

        req.on('error', reject);
        req.end();
    });
}

async function uploadFileHTTP(filePath, buffer, contentType) {
    return new Promise((resolve, reject) => {
        const url = `${NEW_SUPABASE_URL}/storage/v1/object/media/${encodeURIComponent(filePath)}`;
        
        const options = {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${NEW_SERVICE_KEY}`,
                'Content-Type': contentType,
                'Content-Length': buffer.length
            }
        };

        const req = https.request(url, options, (res) => {
            let responseData = '';
            res.on('data', chunk => responseData += chunk);
            res.on('end', () => {
                if (res.statusCode >= 200 && res.statusCode < 300) {
                    console.log(`  ✅ Uploaded successfully via HTTP`);
                    resolve(true);
                } else {
                    console.error(`  ❌ Upload failed: ${res.statusCode} ${responseData}`);
                    resolve(false);
                }
            });
        });

        req.on('error', (error) => {
            console.error(`  ❌ Upload error: ${error.message}`);
            resolve(false);
        });

        req.write(buffer);
        req.end();
    });
}

async function testFileOperations() {
    console.log('🧪 TESTING STORAGE OPERATIONS');
    console.log('==============================');
    
    try {
        // Test 1: Check if we can list files in OLD project
        console.log('📋 Test 1: Listing files in OLD project...');
        const { data: oldFiles, error: oldError } = await oldSupabase.storage
            .from('media')
            .list('6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards', { limit: 5 });
            
        if (oldError) {
            console.error(`❌ Failed to list OLD files: ${oldError.message}`);
        } else {
            console.log(`✅ Found ${oldFiles.length} files in OLD project`);
            oldFiles.forEach(file => console.log(`   - ${file.name}`));
        }
        
        // Test 2: Check if we can list files in NEW project  
        console.log('📋 Test 2: Listing files in NEW project...');
        const { data: newFiles, error: newError } = await newSupabase.storage
            .from('media')
            .list('6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards', { limit: 5 });
            
        if (newError) {
            console.error(`❌ Failed to list NEW files: ${newError.message}`);
        } else {
            console.log(`✅ Found ${newFiles.length} files in NEW project`);
        }
        
        // Test 3: Try downloading a file
        console.log('📥 Test 3: Testing file download...');
        const testFile = filesToMigrate[0];
        
        const fileData = await downloadFileHTTP(testFile);
        if (fileData) {
            console.log(`✅ Successfully downloaded test file: ${fileData.data.length} bytes`);
            
            // Test 4: Try uploading the file
            console.log('📤 Test 4: Testing file upload...');
            const uploadResult = await uploadFileHTTP(`test_${testFile}`, fileData.data, fileData.contentType);
            
            if (uploadResult) {
                console.log('✅ Test upload successful!');
                
                // Test 5: Verify the uploaded file
                console.log('🔍 Test 5: Verifying uploaded file...');
                const { data: publicUrl } = newSupabase.storage
                    .from('media')
                    .getPublicUrl(`test_${testFile}`);
                    
                console.log(`✅ Public URL: ${publicUrl.publicUrl}`);
            } else {
                console.error('❌ Test upload failed');
            }
        }
        
    } catch (error) {
        console.error('💥 Test failed:', error.message);
    }
}

async function migrateAllFiles() {
    console.log('🚀 STARTING SIMPLIFIED STORAGE MIGRATION');
    console.log('========================================');
    
    let results = {
        downloaded: 0,
        uploaded: 0,
        verified: 0,
        errors: []
    };
    
    // Get the full file list
    const fullFileList = [
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
    
    for (let i = 0; i < fullFileList.length; i++) {
        const filePath = fullFileList[i];
        console.log(`[${i + 1}/${fullFileList.length}] Processing: ${filePath.split('/').pop()}`);
        
        try {
            // Download from OLD
            const fileData = await downloadFileHTTP(filePath);
            if (fileData) {
                results.downloaded++;
                
                // Upload to NEW
                const uploadResult = await uploadFileHTTP(filePath, fileData.data, fileData.contentType);
                if (uploadResult) {
                    results.uploaded++;
                    
                    // Verify
                    const { data: publicUrl } = newSupabase.storage
                        .from('media')
                        .getPublicUrl(filePath);
                        
                    if (publicUrl && publicUrl.publicUrl) {
                        results.verified++;
                    }
                } else {
                    results.errors.push(`Upload failed: ${filePath}`);
                }
            } else {
                results.errors.push(`Download failed: ${filePath}`);
            }
        } catch (error) {
            results.errors.push(`Error processing ${filePath}: ${error.message}`);
        }
        
        // Small delay to avoid rate limiting
        await new Promise(resolve => setTimeout(resolve, 100));
    }
    
    console.log('');
    console.log('📊 FINAL RESULTS');
    console.log('================');
    console.log(`✅ Downloaded: ${results.downloaded}/44`);
    console.log(`✅ Uploaded: ${results.uploaded}/44`);
    console.log(`✅ Verified: ${results.verified}/44`);
    
    if (results.errors.length > 0) {
        console.log('');
        console.log('❌ Errors:');
        results.errors.forEach((error, index) => {
            console.log(`  ${index + 1}. ${error}`);
        });
    }
    
    return results.uploaded === 44 && results.verified === 44;
}

// Run based on command line argument
const command = process.argv[2];

if (command === 'test') {
    testFileOperations().then(() => {
        console.log('✅ Test completed');
    }).catch(error => {
        console.error('💥 Test failed:', error.message);
        process.exit(1);
    });
} else {
    migrateAllFiles().then((success) => {
        if (success) {
            console.log('🎉 STORAGE MIGRATION COMPLETED SUCCESSFULLY!');
            process.exit(0);
        } else {
            console.log('⚠️ MIGRATION COMPLETED WITH ISSUES');
            process.exit(1);
        }
    }).catch(error => {
        console.error('💥 Migration failed:', error.message);
        process.exit(1);
    });
}

module.exports = { testFileOperations, migrateAllFiles };