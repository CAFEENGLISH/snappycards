const express = require('express');
const router = express.Router();

const { supabaseAdmin } = require('../config/database');
const { verifyAdminAccess } = require('../middleware/auth');

// Admin endpoint: Update teacher profile (name and note)
router.post('/update-teacher', verifyAdminAccess, async (req, res) => {
    try {
        const { teacherId, firstName, lastName, note } = req.body;

        if (!teacherId || !firstName || !lastName) {
            return res.status(400).json({
                error: 'Missing required fields',
                required: ['teacherId', 'firstName', 'lastName']
            });
        }

        // Verify teacher belongs to admin's school
        const { data: teacher, error: teacherError } = await supabaseAdmin
            .from('user_profiles')
            .select('id, school_id, user_role, first_name, last_name')
            .eq('id', teacherId)
            .eq('school_id', req.adminSchoolId)
            .eq('user_role', 'teacher')
            .single();

        if (teacherError || !teacher) {
            return res.status(404).json({
                error: 'Teacher not found or access denied',
                details: teacherError?.message || 'Teacher not in your school'
            });
        }

        // Update teacher profile using service role key (bypasses RLS)
        const { data: updatedTeacher, error: updateError } = await supabaseAdmin
            .from('user_profiles')
            .update({
                first_name: firstName,
                last_name: lastName,
                note: note || ''
            })
            .eq('id', teacherId)
            .select()
            .single();

        if (updateError) {
            console.error('Teacher update error:', updateError);
            return res.status(500).json({
                error: 'Failed to update teacher profile',
                details: updateError.message
            });
        }

        res.json({
            success: true,
            message: 'Teacher profile updated successfully',
            data: {
                teacher: updatedTeacher,
                updatedFields: ['first_name', 'last_name', 'note']
            }
        });

    } catch (error) {
        console.error('Error in /admin/update-teacher:', error);
        res.status(500).json({
            error: 'Internal server error',
            details: error.message
        });
    }
});

// Admin endpoint: Update teacher email
router.post('/update-teacher-email', verifyAdminAccess, async (req, res) => {
    try {
        const { teacherId, newEmail } = req.body;

        if (!teacherId || !newEmail) {
            return res.status(400).json({
                error: 'Missing required fields',
                required: ['teacherId', 'newEmail']
            });
        }

        // Email validation
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!emailRegex.test(newEmail)) {
            return res.status(400).json({
                error: 'Invalid email format'
            });
        }

        // Verify teacher belongs to admin's school
        const { data: teacher, error: teacherError } = await supabaseAdmin
            .from('user_profiles')
            .select('id, school_id, user_role, is_mock')
            .eq('id', teacherId)
            .eq('school_id', req.adminSchoolId)
            .eq('user_role', 'teacher')
            .single();

        if (teacherError || !teacher) {
            return res.status(404).json({
                error: 'Teacher not found or access denied',
                details: teacherError?.message || 'Teacher not in your school'
            });
        }

        // Update email in user_profiles table for all users (mock and real)
        const { data: profileUpdate, error: profileUpdateError } = await supabaseAdmin
            .from('user_profiles')
            .update({ email: newEmail })
            .eq('id', teacherId)
            .select();

        if (profileUpdateError) {
            console.error('Profile email update error:', profileUpdateError);
            return res.status(500).json({
                error: 'Failed to update teacher email in profile',
                details: profileUpdateError.message
            });
        }

        // Handle mock users differently (simulate auth email update)
        if (teacher.is_mock) {
            // For mock users, just return success without calling Auth API
            return res.json({
                success: true,
                message: 'Teacher email updated successfully (demo mode)',
                data: {
                    teacherId,
                    newEmail,
                    isMock: true,
                    updatedAt: new Date().toISOString()
                }
            });
        }

        // Update email in Supabase Auth for real users
        try {
            const { data: authUser, error: emailUpdateError } = await supabaseAdmin.auth.admin.updateUserById(
                teacherId,
                { email: newEmail }
            );

            if (emailUpdateError) {
                console.error('Email update error:', emailUpdateError);
                return res.status(500).json({
                    error: 'Failed to update teacher email',
                    details: emailUpdateError.message
                });
            }

            res.json({
                success: true,
                message: 'Teacher email updated successfully',
                data: {
                    teacherId,
                    newEmail,
                    updatedAt: new Date().toISOString()
                }
            });

        } catch (authError) {
            console.error('Auth email update error:', authError);
            return res.status(500).json({
                error: 'Failed to update authentication email',
                details: authError.message
            });
        }

    } catch (error) {
        console.error('Error in /admin/update-teacher-email:', error);
        res.status(500).json({
            error: 'Internal server error',
            details: error.message
        });
    }
});

// Admin endpoint: Update teacher password
router.post('/update-teacher-password', verifyAdminAccess, async (req, res) => {
    try {
        const { teacherId, newPassword } = req.body;

        if (!teacherId || !newPassword) {
            return res.status(400).json({
                error: 'Missing required fields',
                required: ['teacherId', 'newPassword']
            });
        }

        if (newPassword.length < 6) {
            return res.status(400).json({
                error: 'Password too short',
                details: 'Password must be at least 6 characters long'
            });
        }

        // Verify teacher belongs to admin's school
        const { data: teacher, error: teacherError } = await supabaseAdmin
            .from('user_profiles')
            .select('id, school_id, user_role, is_mock')
            .eq('id', teacherId)
            .eq('school_id', req.adminSchoolId)
            .eq('user_role', 'teacher')
            .single();

        if (teacherError || !teacher) {
            return res.status(404).json({
                error: 'Teacher not found or access denied',
                details: teacherError?.message || 'Teacher not in your school'
            });
        }

        // Handle mock users differently (store password in database)
        if (teacher.is_mock) {
            // For mock users, store password in database instead of Auth
            const { data: passwordUpdate, error: passwordError } = await supabaseAdmin
                .from('user_profiles')
                .update({ stored_password: newPassword })
                .eq('id', teacherId)
                .select();
            
            if (passwordError) {
                console.error('Error storing mock user password:', passwordError);
                return res.status(500).json({
                    error: 'Failed to store password',
                    details: passwordError.message
                });
            }
            
            return res.json({
                success: true,
                message: 'Teacher password updated successfully (demo mode)',
                data: {
                    teacherId,
                    isMock: true,
                    updatedAt: new Date().toISOString(),
                    passwordStored: true
                }
            });
        }

        // Update user password using Supabase Auth Admin API (for real users)
        const { data: authUser, error: passwordUpdateError } = await supabaseAdmin.auth.admin.updateUserById(
            teacherId,
            { password: newPassword }
        );

        if (passwordUpdateError) {
            console.error('Password update error:', passwordUpdateError);
            return res.status(500).json({
                error: 'Failed to update teacher password',
                details: passwordUpdateError.message
            });
        }

        res.json({
            success: true,
            message: 'Teacher password updated successfully',
            data: {
                teacherId,
                updatedAt: new Date().toISOString()
            }
        });

    } catch (error) {
        console.error('Error in /admin/update-teacher-password:', error);
        res.status(500).json({
            error: 'Internal server error',
            details: error.message
        });
    }
});

module.exports = router;