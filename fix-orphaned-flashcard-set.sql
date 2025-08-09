-- Fix orphaned flashcard set by assigning it to existing user
-- Problem: The "konyha" set belongs to non-existent user ID 1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3
-- Solution: Assign it to vidamkos@gmail.com (password: Palacs1nta) (ID: 9802312d-e7ce-4005-994b-ee9437fb5326)

UPDATE flashcard_sets 
SET user_id = '9802312d-e7ce-4005-994b-ee9437fb5326'  -- vidamkos@gmail.com
WHERE title = 'konyha' 
AND user_id = '1e3ed673-9ed9-4c00-91c8-4bcf56afa3c3';  -- old non-existent user

-- Verify the change
SELECT id, title, user_id, created_at 
FROM flashcard_sets 
WHERE title = 'konyha';