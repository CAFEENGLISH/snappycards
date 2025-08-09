-- Fix RLS policies for card_categories table
-- Allow authenticated users to insert/update/delete card categories

-- Create INSERT policy
CREATE POLICY "Authenticated users can insert card categories" ON public.card_categories
    FOR INSERT 
    TO authenticated 
    WITH CHECK (true);

-- Create UPDATE policy  
CREATE POLICY "Authenticated users can update card categories" ON public.card_categories
    FOR UPDATE 
    TO authenticated 
    USING (true) 
    WITH CHECK (true);

-- Create DELETE policy
CREATE POLICY "Authenticated users can delete card categories" ON public.card_categories
    FOR DELETE 
    TO authenticated 
    USING (true);