# Missing Tables Extraction Guide

## Overview
You need to extract the exact table structures for 3 missing tables from your old Supabase project (`ycxqxdhaxehspypqbnpi.supabase.co`):

1. **classroom_details** (11 columns)
2. **classroom_members** (5 columns)  
3. **favicons** (6 columns) - **HAS 1 ROW OF DATA!**

## 🎯 Goal
Recreate these 3 missing tables in your new Supabase project (`aeijlzokobuqcyznljvn.supabase.co`) with:
- Exact same column structures
- Same data types and constraints
- The actual data from the favicons table

## 📋 Method 1: Direct SQL in Supabase (Recommended)

This is the **easiest and most reliable method**.

### Steps:
1. **Open your OLD Supabase project**: `ycxqxdhaxehspypqbnpi.supabase.co`
2. **Go to SQL Editor**
3. **Copy and paste the entire contents** of `extract-missing-tables.sql`
4. **Click "Run"**
5. **Copy ALL the results** - you'll get:
   - Complete column structures for all 3 tables
   - The data from the favicons table
   - CREATE TABLE statements
   - Primary keys and constraints
   - Indexes

### What you'll get:
```sql
-- Example output format:
📊 COLUMN STRUCTURES
table_name: classroom_details
column_name: id
data_type: uuid
is_nullable: NO
column_default: uuid_generate_v4()
...

🎨 FAVICONS DATA
id: 12345...
name: snappycards-favicon
data_url: data:image/x-icon;base64,AAABAAEAEBAAAAEAIAAoBAAA...
mime_type: image/x-icon
is_active: true
created_at: 2024-01-15T10:30:00.000Z

🏗️ CLASSROOM_DETAILS CREATE STATEMENT
CREATE TABLE IF NOT EXISTS classroom_details (
  id UUID NOT NULL DEFAULT uuid_generate_v4(),
  classroom_id UUID REFERENCES classrooms(id),
  ...
);
```

## 🔧 Method 2: Using MCP Server (Advanced)

If you have the proper credentials for the old project:

### Prerequisites:
```bash
# You need the service role key from your OLD project
export SUPABASE_URL="https://ycxqxdhaxehspypqbnpi.supabase.co"
export SUPABASE_KEY="your_old_project_service_role_key"
```

### Steps:
1. **Get your old project's service role key**:
   - Go to your old project settings
   - Navigate to API settings
   - Copy the "service_role" key (not the anon key)

2. **Run the extraction script**:
   ```bash
   ./extract-via-mcp.sh
   ```

## 🔍 Method 3: Node.js Script (if you prefer programmatic)

### Prerequisites:
```bash
npm install @supabase/supabase-js
```

### Steps:
1. **Edit `extract-missing-tables.js`**:
   - Replace `YOUR_OLD_PROJECT_ANON_KEY_HERE` with your old project's anon key
2. **Run the script**:
   ```bash
   node extract-missing-tables.js
   ```

## 📊 Expected Results

### Classroom Details (11 columns):
Based on typical SnappyCards architecture, this table likely contains:
- `id` (UUID, Primary Key)
- `classroom_id` (UUID, Foreign Key)
- Metadata fields for classroom configuration
- `created_at`, `updated_at` timestamps
- `is_mock` boolean flag

### Classroom Members (5 columns):
Junction table linking users to classrooms:
- `id` (UUID, Primary Key) 
- `classroom_id` (UUID, Foreign Key)
- `user_id` (UUID, Foreign Key)
- `role` or `status` field
- `created_at` timestamp

### Favicons (6 columns):
Contains favicon data for the application:
- `id` (UUID, Primary Key)
- `name` (TEXT)
- `data_url` (TEXT) - Base64 encoded favicon data
- `mime_type` (TEXT) - e.g., 'image/x-icon'
- `is_active` (BOOLEAN)
- `created_at` (TIMESTAMP)

## 🚀 After Extraction

Once you have the table structures and data:

1. **Create the tables in your NEW project** (`aeijlzokobuqcyznljvn.supabase.co`)
2. **Use the CREATE TABLE statements** from the extraction results
3. **Insert the favicons data** (copy the exact row from the old project)
4. **Add proper RLS policies** following the patterns in your existing tables
5. **Create necessary indexes** for performance

## 📝 Files Created

This guide includes these helper files:

- `extract-missing-tables.sql` - **Direct SQL approach (recommended)**
- `extract-via-mcp.sh` - MCP server approach
- `extract-missing-tables.js` - Node.js programmatic approach

## 🎯 Priority Order

1. **Use Method 1** (Direct SQL) - fastest and most reliable
2. **Use Method 2** if you have service role access to old project
3. **Use Method 3** if you prefer programmatic extraction

## ⚠️ Important Notes

- **Favicons table has 1 row of data** - make sure to copy this data exactly!
- **Preserve data types exactly** - UUID references must stay UUID
- **Copy constraints and indexes** for proper functionality
- **Add RLS policies** after creating tables in the new project

## 🔄 Next Steps After Extraction

1. Create the missing tables in your new project
2. Test the student login functionality 
3. Verify flashcard study sessions work properly
4. Check that classroom functionality is restored

The missing tables are likely causing authentication and classroom management issues in your application.