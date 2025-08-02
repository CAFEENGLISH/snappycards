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
          title_formatted?: string
          english_title_formatted?: string
          image_url: string
          image_alt: string
          media_type?: string
          media_url?: string
          category?: string
          category_id?: string
          difficulty_level: number
        }
        Insert: {
          id?: string
          created_at?: string
          title: string
          english_title: string
          title_formatted?: string
          english_title_formatted?: string
          image_url: string
          image_alt: string
          media_type?: string
          media_url?: string
          category?: string
          category_id?: string
          difficulty_level?: number
        }
        Update: {
          id?: string
          created_at?: string
          title?: string
          english_title?: string
          title_formatted?: string
          english_title_formatted?: string
          image_url?: string
          image_alt?: string
          media_type?: string
          media_url?: string
          category?: string
          category_id?: string
          difficulty_level?: number
        }
      }
      categories: {
        Row: {
          id: string
          name: string
          description?: string
          color?: string
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          name: string
          description?: string
          color?: string
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          name?: string
          description?: string
          color?: string
          created_at?: string
          updated_at?: string
        }
      }
      card_categories: {
        Row: {
          id: string
          card_id: string
          category_id: string
          created_at: string
        }
        Insert: {
          id?: string
          card_id: string
          category_id: string
          created_at?: string
        }
        Update: {
          id?: string
          card_id?: string
          category_id?: string
          created_at?: string
        }
      }
      flashcard_sets: {
        Row: {
          id: string
          title: string
          description: string
          language_a: string
          language_b: string
          created_at: string
          updated_at: string
          user_id?: string
        }
        Insert: {
          id?: string
          title: string
          description: string
          language_a: string
          language_b: string
          created_at?: string
          updated_at?: string
          user_id?: string
        }
        Update: {
          id?: string
          title?: string
          description?: string
          language_a?: string
          language_b?: string
          created_at?: string
          updated_at?: string
          user_id?: string
        }
      }
      flashcard_set_cards: {
        Row: {
          id: string
          set_id: string
          card_id: string
          position: number
          created_at: string
        }
        Insert: {
          id?: string
          set_id: string
          card_id: string
          position?: number
          created_at?: string
        }
        Update: {
          id?: string
          set_id?: string
          card_id?: string
          position?: number
          created_at?: string
        }
      }
      flashcard_set_categories: {
        Row: {
          id: string
          set_id: string
          category_id: string
          created_at: string
        }
        Insert: {
          id?: string
          set_id: string
          category_id: string
          created_at?: string
        }
        Update: {
          id?: string
          set_id?: string
          category_id?: string
          created_at?: string
        }
      }
    }
  }
}