-- Remove redundant creator_id column from flashcard_sets
-- This will clean up the database schema for better consistency

-- First update any remaining creator_id values to user_id (just in case)
UPDATE flashcard_sets 
SET user_id = creator_id 
WHERE user_id IS NULL AND creator_id IS NOT NULL;

-- Drop the redundant column
ALTER TABLE flashcard_sets DROP COLUMN IF EXISTS creator_id;

-- Verify the change
\d flashcard_sets;