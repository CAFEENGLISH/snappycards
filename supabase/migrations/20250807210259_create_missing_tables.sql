-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. FAVICONS TABLE 
CREATE TABLE IF NOT EXISTS favicons (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    data_url TEXT NOT NULL,
    mime_type TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN DEFAULT true
);

-- Insert the favicon data
INSERT INTO favicons (id, name, data_url, mime_type, created_at, is_active) 
VALUES (
    '410ad964-fdee-4a87-8d72-1e359aa209c9',
    'SnappyCards Main Favicon',
    'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMzIiIGhlaWdodD0iMzIiIHZpZXdCb3g9IjAgMCAzMiAzMiIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KPCEtLSBCYWNrZ3JvdW5kIC0tPgo8cmVjdCB3aWR0aD0iMzIiIGhlaWdodD0iMzIiIHJ4PSI0IiBmaWxsPSIjNjM2NmYxIi8+CjwhLS0gQ2FyZCBTaGFwZSAtLT4KPHJlY3QgeD0iNCIgeT0iNiIgd2lkdGg9IjI0IiBoZWlnaHQ9IjE2IiByeD0iMyIgZmlsbD0iI2ZmZmZmZiIgc3Ryb2tlPSIjZGRkZGRkIiBzdHJva2Utd2lkdGg9IjAuNSIvPgo8IS0tIFRleHQgUyAtLT4KPHRleHQgeD0iMTYiIHk9IjE4IiBmb250LWZhbWlseT0iQXJpYWwsIHNhbnMtc2VyaWYiIGZvbnQtc2l6ZT0iMTQiIGZvbnQtd2VpZ2h0PSJib2xkIiBmaWxsPSIjNjM2NmYxIiB0ZXh0LWFuY2hvcj0ibWlkZGxlIiBkb21pbmFudC1iYXNlbGluZT0iY2VudHJhbCI+UzwvdGV4dD4KPCEtLSBTbWFsbCBkb3RzIGZvciBmbGFzaGNhcmQgZWZmZWN0IC0tPgo8Y2lyY2xlIGN4PSI4IiBjeT0iMTAiIHI9IjEiIGZpbGw9IiM2MzY2ZjEiLz4KPGNpcmNsZSBjeD0iMjQiIGN5PSIxOCIgcj0iMSIgZmlsbD0iIzYzNjZmMSIvPgo8L3N2Zz4K',
    'image/svg+xml',
    '2025-08-04T22:18:16.773773+00:00',
    true
) ON CONFLICT (id) DO NOTHING;

-- 2. CLASSROOM_DETAILS TABLE
CREATE TABLE IF NOT EXISTS classroom_details (
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
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(classroom_id)
);

-- 3. CLASSROOM_MEMBERS TABLE
CREATE TABLE IF NOT EXISTS classroom_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    classroom_id UUID NOT NULL REFERENCES classrooms(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'pending')),
    UNIQUE(classroom_id, user_id)
);