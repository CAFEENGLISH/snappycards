const { supabaseAdmin } = require('../config/database');

// Middleware to verify admin permissions
async function verifyAdminAccess(req, res, next) {
    try {
        const authHeader = req.headers.authorization;
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return res.status(401).json({
                error: 'Missing or invalid authorization header',
                details: 'Provide Bearer token in Authorization header'
            });
        }

        const token = authHeader.split(' ')[1];
        
        // Verify the JWT token with Supabase
        const { data: { user }, error: authError } = await supabaseAdmin.auth.getUser(token);
        
        if (authError || !user) {
            return res.status(401).json({
                error: 'Invalid or expired token',
                details: authError?.message || 'Token verification failed'
            });
        }

        // Check if user has school_admin role
        const userRole = user.user_metadata?.user_role;
        if (userRole !== 'school_admin') {
            return res.status(403).json({
                error: 'Insufficient permissions',
                details: 'Only school administrators can perform this action',
                userRole
            });
        }

        // Get user's school info
        const { data: adminProfile, error: profileError } = await supabaseAdmin
            .from('user_profiles')
            .select('school_id')
            .eq('id', user.id)
            .single();

        if (profileError || !adminProfile?.school_id) {
            return res.status(403).json({
                error: 'Admin profile not found or no school assigned',
                details: profileError?.message || 'Invalid admin profile'
            });
        }

        // Add user and school info to request
        req.adminUser = user;
        req.adminSchoolId = adminProfile.school_id;
        next();
    } catch (error) {
        console.error('Admin verification error:', error);
        return res.status(500).json({
            error: 'Internal server error during authentication',
            details: error.message
        });
    }
}

module.exports = {
    verifyAdminAccess
};