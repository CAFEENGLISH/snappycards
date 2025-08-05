const { supabaseAdmin } = require('../config/database');

// Helper function to create user profile and school
async function createUserProfileAndSchool(user) {
    try {
        const { id: userId, user_metadata } = user;
        const { first_name, user_role, school_name } = user_metadata || {};
        
        let schoolId = null;
        
        // If school_admin, create school first
        if (user_role === 'school_admin' && school_name) {
            const { data: schoolData, error: schoolError } = await supabaseAdmin
                .from('schools')
                .insert({
                    name: school_name,
                    description: `School managed by ${first_name}`,
                    contact_email: user.email,
                    is_active: true
                })
                .select()
                .single();
                
            if (schoolError) {
                console.error('❌ Failed to create school:', schoolError);
                throw schoolError;
            }
            
            schoolId = schoolData.id;
        }
        
        // Create user profile
        const { data: profileData, error: profileError } = await supabaseAdmin
            .from('user_profiles')
            .insert({
                id: userId,
                first_name: first_name || '',
                last_name: '', // Can be added later
                user_role: user_role || 'student',
                school_id: schoolId
            })
            .select()
            .single();
            
        if (profileError) {
            console.error('❌ Failed to create user profile:', profileError);
            throw profileError;
        }
        
        return { profile: profileData, schoolId };
        
    } catch (error) {
        console.error('❌ Error in createUserProfileAndSchool:', error);
        throw error;
    }
}

module.exports = {
    createUserProfileAndSchool
};