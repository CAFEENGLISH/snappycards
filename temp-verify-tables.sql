-- Verify tables exist
SELECT table_name, 
       (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = t.table_name AND table_schema = 'public') as column_count
FROM information_schema.tables t
WHERE table_schema = 'public'
AND table_name IN ('favicons', 'classroom_details', 'classroom_members')
ORDER BY table_name;

-- Check favicon data
SELECT COUNT(*) as favicon_count FROM favicons;