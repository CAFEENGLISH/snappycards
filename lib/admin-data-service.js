/**
 * Admin Data Service Layer for SnappyCards
 * Centralized Supabase data operations for Admin Dashboard
 */

class AdminDataService {
    /**
     * School Operations
     */
    static async getSchool(schoolId) {
        const { data, error } = await supabase
            .from('schools')
            .select('id, name, address, phone')
            .eq('id', schoolId)
            .single();
        
        return { data, error };
    }

    static async createSchool(schoolData) {
        const { data, error } = await supabase
            .from('schools')
            .insert(schoolData)
            .select()
            .single();
        
        return { data, error };
    }

    static async updateSchool(schoolId, updates) {
        const { data, error } = await supabase
            .from('schools')
            .update(updates)
            .eq('id', schoolId)
            .select()
            .single();
        
        return { data, error };
    }

    /**
     * User Profile Operations
     */
    static async getUserProfile(userId) {
        const { data, error } = await supabase
            .from('user_profiles')
            .select('id, first_name, last_name, email, user_role, school_id, note, stored_password, created_at')
            .eq('id', userId)
            .single();
        
        return { data, error };
    }

    static async getSchoolUsers(schoolId, role = null) {
        let query = supabase
            .from('user_profiles')
            .select('id, first_name, last_name, email, user_role, school_id, note, stored_password, created_at')
            .eq('school_id', schoolId);
        
        if (role) {
            query = query.eq('user_role', role);
        }
        
        const { data, error } = await query;
        return { data, error };
    }

    static async getSchoolTeachers(schoolId) {
        return this.getSchoolUsers(schoolId, 'teacher');
    }

    static async getSchoolStudents(schoolId) {
        return this.getSchoolUsers(schoolId, 'student');
    }

    static async createUserProfile(userData) {
        const { data, error } = await supabase
            .from('user_profiles')
            .insert(userData)
            .select()
            .single();
        
        return { data, error };
    }

    static async updateUserProfile(userId, updates) {
        const { data, error } = await supabase
            .from('user_profiles')
            .update(updates)
            .eq('id', userId)
            .select()
            .single();
        
        return { data, error };
    }

    static async deleteUserProfile(userId) {
        const { error } = await supabase
            .from('user_profiles')
            .delete()
            .eq('id', userId);
        
        return { error };
    }

    /**
     * Classroom Operations
     */
    static async getSchoolClassrooms(schoolId) {
        const { data, error } = await supabase
            .from('classrooms')
            .select('id, name, description, created_at, teacher_id')
            .eq('school_id', schoolId);
        
        return { data, error };
    }

    static async createClassroom(classroomData) {
        const { data, error } = await supabase
            .from('classrooms')
            .insert(classroomData)
            .select()
            .single();
        
        return { data, error };
    }

    static async updateClassroom(classroomId, updates) {
        const { data, error } = await supabase
            .from('classrooms')
            .update(updates)
            .eq('id', classroomId)
            .select()
            .single();
        
        return { data, error };
    }

    static async deleteClassroom(classroomId) {
        const { error } = await supabase
            .from('classrooms')
            .delete()
            .eq('id', classroomId);
        
        return { error };
    }

    /**
     * Flashcard Sets Operations
     */
    static async getSchoolSets(schoolId) {
        // Get all users from the school first
        const { data: schoolUsers, error: usersError } = await this.getSchoolUsers(schoolId);
        
        if (usersError) return { data: null, error: usersError };
        
        const schoolUserIds = schoolUsers?.map(u => u.id) || [];
        
        if (schoolUserIds.length === 0) {
            return { data: [], error: null };
        }
        
        const { data, error } = await supabase
            .from('flashcard_sets')
            .select('*')
            .in('creator_id', schoolUserIds);
        
        return { data, error };
    }

    /**
     * Statistics Operations
     */
    static async getSchoolStatistics(schoolId) {
        try {
            // Get teachers count
            const { count: teachersCount, error: teachersError } = await supabase
                .from('user_profiles')
                .select('*', { count: 'exact', head: true })
                .eq('school_id', schoolId)
                .eq('user_role', 'teacher');

            if (teachersError) throw teachersError;

            // Get classrooms count  
            const { count: classroomsCount, error: classroomsError } = await supabase
                .from('classrooms')
                .select('*', { count: 'exact', head: true })
                .eq('school_id', schoolId);

            if (classroomsError) throw classroomsError;

            // Get students count
            const { count: studentsCount, error: studentsError } = await supabase
                .from('user_profiles')
                .select('*', { count: 'exact', head: true })
                .eq('school_id', schoolId)
                .eq('user_role', 'student');

            if (studentsError) throw studentsError;

            // Get sets count
            const { data: schoolUsers } = await this.getSchoolUsers(schoolId);
            const schoolUserIds = schoolUsers?.map(u => u.id) || [];
            
            const { count: setsCount, error: setsError } = await supabase
                .from('flashcard_sets')
                .select('*', { count: 'exact', head: true })
                .in('creator_id', schoolUserIds.length > 0 ? schoolUserIds : ['no-users']);

            if (setsError) throw setsError;

            return {
                data: {
                    teachers: teachersCount || 0,
                    classrooms: classroomsCount || 0,
                    students: studentsCount || 0,
                    sets: setsCount || 0
                },
                error: null
            };
        } catch (error) {
            return { data: null, error };
        }
    }
}

// Export for use in HTML files
window.AdminDataService = AdminDataService;