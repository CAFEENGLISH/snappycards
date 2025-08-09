# 🚀 Complete Migration Guide: Missing Tables Transfer

## ✅ COMPLETED STEPS

1. **✓ Connected to OLD project** (ycxqxdhaxehspypqbnpi.supabase.co)
2. **✓ Extracted favicon data** (1 row with SnappyCards favicon)  
3. **✓ Verified NEW project access** (aeijlzokobuqcyznljvn.supabase.co)
4. **✓ Confirmed missing tables**: `favicons`, `classroom_details`, `classroom_members` do NOT exist in NEW project
5. **✓ Created complete SQL script** with table structures and RLS policies

## 🎯 NEXT STEPS - Manual Execution Required

Since DDL operations (CREATE TABLE) cannot be executed via REST API, you need to run the SQL script manually in the Supabase Dashboard.

### **STEP 1: Access NEW Supabase Dashboard**
1. Go to: https://supabase.com/dashboard/project/aeijlzokobuqcyznljvn
2. Navigate to **SQL Editor** in the left sidebar

### **STEP 2: Execute SQL Script**
1. Open the file: `/Volumes/PASSPORT/TELJES/IT/CURSOR/SNAPPYCARDS/create-missing-tables.sql`
2. Copy the ENTIRE contents of this file
3. Paste into SQL Editor in Supabase Dashboard  
4. Click **RUN** to execute

### **STEP 3: Verify Success**
After running the script, you should see:
- ✅ 3 new tables created: `favicons`, `classroom_details`, `classroom_members`
- ✅ 1 favicon record inserted into `favicons` table
- ✅ RLS policies enabled and configured
- ✅ Indexes created for performance
- ✅ Proper foreign key relationships established

---

## 📋 WHAT THE SCRIPT CREATES

### **1. FAVICONS TABLE (6 columns)**
```sql
CREATE TABLE favicons (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    data_url TEXT NOT NULL, 
    mime_type TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN DEFAULT true
);
```
**✓ Includes the 1 row of data from OLD project:**
- SnappyCards Main Favicon (SVG format, base64 encoded)

### **2. CLASSROOM_DETAILS TABLE (11 columns)**
```sql  
CREATE TABLE classroom_details (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    classroom_id UUID NOT NULL REFERENCES classrooms(id) ON DELETE CASCADE,
    subject TEXT,
    grade_level TEXT, 
    academic_year TEXT,
    meeting_schedule TEXT,
    room_number TEXT,
    max_students INTEGER DEFAULT 30,
    description TEXT,
    settings JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### **3. CLASSROOM_MEMBERS TABLE (5 columns)**
```sql
CREATE TABLE classroom_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    classroom_id UUID NOT NULL REFERENCES classrooms(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'pending'))
);
```

---

## 🔐 RLS POLICIES INCLUDED

The script automatically sets up comprehensive Row Level Security policies:

### **FAVICONS**
- ✅ Read access for authenticated users
- ✅ Management permissions for admins

### **CLASSROOM_DETAILS**  
- ✅ Teachers can manage their own classroom details
- ✅ School admins can access their school's classroom details

### **CLASSROOM_MEMBERS**
- ✅ Students can read their own memberships
- ✅ Teachers can manage their classroom memberships  
- ✅ School admins can access their school's memberships

---

## 🚨 ALTERNATIVE APPROACH (If Manual Fails)

If you encounter any issues with the manual SQL execution, there's also a script available:

**File:** `/Volumes/PASSPORT/TELJES/IT/CURSOR/SNAPPYCARDS/create-tables-script.js`

However, this requires the Supabase service role key (not anon key) for DDL operations.

---

## ✅ VERIFICATION COMMANDS

After running the script, verify success with these queries in SQL Editor:

```sql
-- Check tables were created
SELECT table_name, 
       (SELECT COUNT(*) FROM information_schema.columns 
        WHERE table_name = t.table_name AND table_schema = 'public') as column_count
FROM information_schema.tables t  
WHERE table_schema = 'public'
AND table_name IN ('favicons', 'classroom_details', 'classroom_members');

-- Check favicon data was inserted
SELECT COUNT(*) as favicon_count FROM favicons;

-- View the inserted favicon
SELECT name, mime_type, is_active FROM favicons;
```

---

## 🎉 EXPECTED RESULTS

After successful execution:
- **3 missing tables** will be created in your NEW Supabase project
- **1 favicon record** will be migrated from the OLD project  
- **All RLS policies** will be properly configured
- **Foreign key relationships** will be established with existing tables
- **Performance indexes** will be created

---

## 📞 MIGRATION SUMMARY

| Task | Status |
|------|---------|
| Extract OLD project data | ✅ Completed |
| Create table structures | ✅ Completed |  
| Generate RLS policies | ✅ Completed |
| Prepare migration script | ✅ Completed |
| **Execute in NEW project** | ⏳ **Ready for you to run** |

**Total Tables to Migrate:** 3  
**Data Records to Migrate:** 1 (favicons)  
**Estimated Execution Time:** 30 seconds

---

## 🔧 FILES CREATED FOR THIS MIGRATION

1. **`create-missing-tables.sql`** - Complete SQL script (RECOMMENDED)
2. **`create-tables-script.js`** - Node.js alternative approach  
3. **`MIGRATION_COMPLETION_GUIDE.md`** - This guide

**Ready to execute!** Just copy/paste the SQL script into your Supabase Dashboard SQL Editor.