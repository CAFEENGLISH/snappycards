#!/usr/bin/env node

/**
 * Migrate Storage Data from OLD to NEW Supabase Project
 * Based on audit findings:
 * - 1 storage bucket missing in NEW project
 * - 44 storage objects missing in NEW project
 */

const https = require('https');
const fs = require('fs').promises;

const PERSONAL_ACCESS_TOKEN = 'sbp_6d50add440dc1960b3efbd639d932f4b42ece0f2';
const OLD_PROJECT_ID = 'ycxqxdhaxehspypqbnpi';
const NEW_PROJECT_ID = 'aeijlzokobuqcyznljvn';
const SUPABASE_API_BASE = 'https://api.supabase.com/v1';

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

async function getStorageBuckets(projectId) {
    const sql = `
        SELECT 
            id,
            name,
            owner,
            public,
            avif_autodetection,
            file_size_limit,
            allowed_mime_types,
            created_at,
            updated_at
        FROM storage.buckets
        ORDER BY name;
    `;
    
    return await executeSQL(projectId, sql);
}

async function getStorageObjects(projectId) {
    const sql = `
        SELECT 
            id,
            bucket_id,
            name,
            owner,
            created_at,
            updated_at,
            last_accessed_at,
            metadata
        FROM storage.objects
        ORDER BY bucket_id, name;
    `;
    
    return await executeSQL(projectId, sql);
}

async function migrateStorageData() {
    console.log('🗄️ Migrating Storage Data between Projects');
    console.log('==========================================');
    console.log(`📊 Source: ${OLD_PROJECT_ID}`);
    console.log(`📊 Target: ${NEW_PROJECT_ID}`);
    console.log('');
    
    try {
        // Get storage data from both projects
        console.log('🔍 Analyzing storage buckets...');
        const [oldBuckets, newBuckets] = await Promise.all([
            getStorageBuckets(OLD_PROJECT_ID),
            getStorageBuckets(NEW_PROJECT_ID)
        ]);
        
        if (oldBuckets.error || newBuckets.error) {
            throw new Error(`Failed to get buckets: OLD=${oldBuckets.error}, NEW=${newBuckets.error}`);
        }
        
        console.log(`   OLD project has ${oldBuckets.length} buckets`);
        console.log(`   NEW project has ${newBuckets.length} buckets`);
        
        // Get storage objects from both projects
        console.log('🔍 Analyzing storage objects...');
        const [oldObjects, newObjects] = await Promise.all([
            getStorageObjects(OLD_PROJECT_ID),
            getStorageObjects(NEW_PROJECT_ID)
        ]);
        
        if (oldObjects.error || newObjects.error) {
            throw new Error(`Failed to get objects: OLD=${oldObjects.error}, NEW=${newObjects.error}`);
        }
        
        console.log(`   OLD project has ${oldObjects.length} objects`);
        console.log(`   NEW project has ${newObjects.length} objects`);
        console.log('');
        
        // Generate migration script for buckets
        let migrationSQL = `-- STORAGE DATA MIGRATION SCRIPT
-- Generated: ${new Date().toISOString()}
-- Source: ${OLD_PROJECT_ID}
-- Target: ${NEW_PROJECT_ID}

-- =============================================
-- STORAGE BUCKETS MIGRATION
-- =============================================

`;

        // Create missing buckets
        const newBucketNames = newBuckets.map(b => b.name);
        const missingBuckets = oldBuckets.filter(bucket => !newBucketNames.includes(bucket.name));
        
        if (missingBuckets.length > 0) {
            console.log(`🔧 Found ${missingBuckets.length} missing buckets to create`);
            
            for (const bucket of missingBuckets) {
                console.log(`   📋 Creating bucket: ${bucket.name}`);
                
                migrationSQL += `-- Create bucket: ${bucket.name}\n`;
                migrationSQL += `INSERT INTO storage.buckets (\n`;
                migrationSQL += `  id, name, owner, public, avif_autodetection, file_size_limit, allowed_mime_types, created_at, updated_at\n`;
                migrationSQL += `) VALUES (\n`;
                migrationSQL += `  '${bucket.id}',\n`;
                migrationSQL += `  '${bucket.name}',\n`;
                migrationSQL += `  ${bucket.owner ? `'${bucket.owner}'` : 'NULL'},\n`;
                migrationSQL += `  ${bucket.public},\n`;
                migrationSQL += `  ${bucket.avif_autodetection || false},\n`;
                migrationSQL += `  ${bucket.file_size_limit || 'NULL'},\n`;
                migrationSQL += `  ${bucket.allowed_mime_types ? `'${JSON.stringify(bucket.allowed_mime_types)}'` : 'NULL'},\n`;
                migrationSQL += `  '${bucket.created_at}',\n`;
                migrationSQL += `  '${bucket.updated_at}'\n`;
                migrationSQL += `) ON CONFLICT (id) DO NOTHING;\n\n`;
            }
        } else {
            console.log('✅ All buckets already exist in NEW project');
        }
        
        // Analyze missing objects
        migrationSQL += `-- =============================================\n`;
        migrationSQL += `-- STORAGE OBJECTS MIGRATION\n`;
        migrationSQL += `-- =============================================\n\n`;
        
        const newObjectIds = newObjects.map(obj => obj.id);
        const missingObjects = oldObjects.filter(obj => !newObjectIds.includes(obj.id));
        
        if (missingObjects.length > 0) {
            console.log(`🔧 Found ${missingObjects.length} missing objects to migrate`);
            console.log('⚠️ NOTE: This script only creates object metadata entries.');
            console.log('⚠️ Actual file data must be copied separately using storage API or tools.');
            console.log('');
            
            // Group objects by bucket for better organization
            const objectsByBucket = {};
            missingObjects.forEach(obj => {
                if (!objectsByBucket[obj.bucket_id]) {
                    objectsByBucket[obj.bucket_id] = [];
                }
                objectsByBucket[obj.bucket_id].push(obj);
            });
            
            for (const [bucketId, bucketObjects] of Object.entries(objectsByBucket)) {
                const bucketName = oldBuckets.find(b => b.id === bucketId)?.name || bucketId;
                
                migrationSQL += `-- Objects for bucket: ${bucketName} (${bucketObjects.length} objects)\n`;
                
                for (const obj of bucketObjects) {
                    migrationSQL += `-- Object: ${obj.name}\n`;
                    migrationSQL += `INSERT INTO storage.objects (\n`;
                    migrationSQL += `  id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata\n`;
                    migrationSQL += `) VALUES (\n`;
                    migrationSQL += `  '${obj.id}',\n`;
                    migrationSQL += `  '${obj.bucket_id}',\n`;
                    migrationSQL += `  '${obj.name.replace(/'/g, "''")}',\n`;
                    migrationSQL += `  ${obj.owner ? `'${obj.owner}'` : 'NULL'},\n`;
                    migrationSQL += `  '${obj.created_at}',\n`;
                    migrationSQL += `  '${obj.updated_at}',\n`;
                    migrationSQL += `  ${obj.last_accessed_at ? `'${obj.last_accessed_at}'` : 'NULL'},\n`;
                    migrationSQL += `  ${obj.metadata ? `'${JSON.stringify(obj.metadata)}'::jsonb` : 'NULL'}\n`;
                    migrationSQL += `) ON CONFLICT (id) DO NOTHING;\n\n`;
                }
                
                migrationSQL += '\n';
            }
            
            // Add file copying instructions
            migrationSQL += `-- =============================================\n`;
            migrationSQL += `-- FILE DATA COPYING INSTRUCTIONS\n`;
            migrationSQL += `-- =============================================\n\n`;
            migrationSQL += `-- IMPORTANT: After running this SQL script, you need to copy the actual file data.\n`;
            migrationSQL += `-- This can be done using:\n`;
            migrationSQL += `-- 1. Supabase CLI storage commands\n`;
            migrationSQL += `-- 2. Storage API calls\n`;
            migrationSQL += `-- 3. Manual download/upload process\n\n`;
            
            migrationSQL += `-- Files to copy by bucket:\n`;
            for (const [bucketId, bucketObjects] of Object.entries(objectsByBucket)) {
                const bucketName = oldBuckets.find(b => b.id === bucketId)?.name || bucketId;
                migrationSQL += `-- Bucket '${bucketName}': ${bucketObjects.length} files\n`;
                bucketObjects.forEach(obj => {
                    migrationSQL += `--   - ${obj.name}\n`;
                });
                migrationSQL += '\n';
            }
            
        } else {
            console.log('✅ All objects already exist in NEW project');
        }
        
        // Add verification queries
        migrationSQL += `-- =============================================\n`;
        migrationSQL += `-- VERIFICATION QUERIES\n`;
        migrationSQL += `-- =============================================\n\n`;
        
        migrationSQL += `-- Check bucket count\n`;
        migrationSQL += `SELECT COUNT(*) as bucket_count FROM storage.buckets;\n\n`;
        
        migrationSQL += `-- Check objects count by bucket\n`;
        migrationSQL += `SELECT b.name as bucket_name, COUNT(o.id) as object_count\n`;
        migrationSQL += `FROM storage.buckets b\n`;
        migrationSQL += `LEFT JOIN storage.objects o ON b.id = o.bucket_id\n`;
        migrationSQL += `GROUP BY b.name\n`;
        migrationSQL += `ORDER BY b.name;\n\n`;
        
        // Save migration script
        await fs.writeFile(
            '/Volumes/PASSPORT/TELJES/IT/CURSOR/SNAPPYCARDS/migrate-storage-data.sql',
            migrationSQL
        );
        
        console.log('✅ Storage migration script generated');
        console.log('📝 Generated: migrate-storage-data.sql');
        
        // Generate storage migration summary
        let summary = `# STORAGE DATA MIGRATION SUMMARY\n\n`;
        summary += `Generated: ${new Date().toISOString()}\n\n`;
        
        summary += `## Buckets\n`;
        summary += `- OLD project: ${oldBuckets.length} buckets\n`;
        summary += `- NEW project: ${newBuckets.length} buckets\n`;
        summary += `- Missing: ${missingBuckets.length} buckets\n\n`;
        
        if (missingBuckets.length > 0) {
            summary += `### Missing Buckets:\n`;
            missingBuckets.forEach(bucket => {
                summary += `- **${bucket.name}** (${bucket.public ? 'public' : 'private'})\n`;
            });
            summary += '\n';
        }
        
        summary += `## Objects\n`;
        summary += `- OLD project: ${oldObjects.length} objects\n`;
        summary += `- NEW project: ${newObjects.length} objects\n`;
        summary += `- Missing: ${missingObjects.length} objects\n\n`;
        
        if (missingObjects.length > 0) {
            summary += `### Missing Objects by Bucket:\n`;
            const objectsByBucket = {};
            missingObjects.forEach(obj => {
                const bucketName = oldBuckets.find(b => b.id === obj.bucket_id)?.name || obj.bucket_id;
                if (!objectsByBucket[bucketName]) {
                    objectsByBucket[bucketName] = [];
                }
                objectsByBucket[bucketName].push(obj);
            });
            
            for (const [bucketName, objects] of Object.entries(objectsByBucket)) {
                summary += `#### ${bucketName} (${objects.length} objects)\n`;
                objects.forEach(obj => {
                    summary += `- ${obj.name}\n`;
                });
                summary += '\n';
            }
        }
        
        summary += `## Next Steps\n\n`;
        summary += `1. Run the SQL migration script to create missing buckets and object metadata\n`;
        summary += `2. Use Supabase storage tools to copy actual file data\n`;
        summary += `3. Verify file accessibility in the NEW project\n`;
        summary += `4. Update application storage references if needed\n`;
        
        await fs.writeFile(
            '/Volumes/PASSPORT/TELJES/IT/CURSOR/SNAPPYCARDS/STORAGE_MIGRATION_SUMMARY.md',
            summary
        );
        
        console.log('📋 Generated: STORAGE_MIGRATION_SUMMARY.md');
        console.log('');
        console.log('🎉 Storage data analysis complete!');
        console.log(`📊 Summary: ${missingBuckets.length} buckets + ${missingObjects.length} objects to migrate`);
        
    } catch (error) {
        console.error('💥 Storage migration analysis failed:', error.message);
        throw error;
    }
}

if (require.main === module) {
    migrateStorageData().then(() => {
        console.log('🏁 Storage migration analysis completed');
        process.exit(0);
    }).catch((error) => {
        console.error('💥 Storage migration script failed:', error.message);
        process.exit(1);
    });
}

module.exports = { migrateStorageData };