import { createClient } from '@supabase/supabase-js'

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || 'https://ycxqxdhaxehspypqbnpi.supabase.co'
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InljeHF4ZGhheGVoc3B5cHFibnBpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMyMDMwMzEsImV4cCI6MjA2ODc3OTAzMX0.7RGVld6WOhNgeTA6xQc_U_eDXfMGzIshUlKV6j2Ru6g'

export const supabase = createClient(supabaseUrl, supabaseAnonKey)

// Database types for TypeScript
export type Database = {
  public: {
    Tables: {
      study_sessions: {
        Row: {
          id: string
          created_at: string
          updated_at: string
          user_id?: string
          session_data: any
          total_time: number
          cards_studied: number
          correct_answers: number
          uncertain_answers: number
          need_to_learn: number
        }
        Insert: {
          id?: string
          created_at?: string
          updated_at?: string
          user_id?: string
          session_data: any
          total_time: number
          cards_studied: number
          correct_answers: number
          uncertain_answers: number
          need_to_learn: number
        }
        Update: {
          id?: string
          created_at?: string
          updated_at?: string
          user_id?: string
          session_data?: any
          total_time?: number
          cards_studied?: number
          correct_answers?: number
          uncertain_answers?: number
          need_to_learn?: number
        }
      }
      cards: {
        Row: {
          id: string
          created_at: string
          title: string
          english_title: string
          image_url: string
          image_alt: string
          category: string
          difficulty_level: number
        }
        Insert: {
          id?: string
          created_at?: string
          title: string
          english_title: string
          image_url: string
          image_alt: string
          category: string
          difficulty_level?: number
        }
        Update: {
          id?: string
          created_at?: string
          title?: string
          english_title?: string
          image_url?: string
          image_alt?: string
          category?: string
          difficulty_level?: number
        }
      }
    }
  }
}