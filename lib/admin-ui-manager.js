/**
 * Admin UI Manager for SnappyCards
 * Centralized UI state management using existing utilities
 */

class AdminUIManager {
    /**
     * Loading States
     */
    static showLoading(containerId, message = 'Betöltés...') {
        const container = document.getElementById(containerId);
        if (!container) return;
        
        container.innerHTML = `
            <div style="padding: 40px; text-align: center; color: #64748b;">
                <div style="display: inline-block; width: 20px; height: 20px; border: 2px solid #ddd; border-top: 2px solid #6366f1; border-radius: 50%; animation: spin 1s linear infinite;"></div>
                <p style="margin-top: 16px;">${message}</p>
            </div>
        `;
    }

    static showError(containerId, message) {
        const container = document.getElementById(containerId);
        if (!container) return;
        
        container.innerHTML = `
            <div style="padding: 40px; text-align: center; color: #ef4444;">
                <i data-lucide="alert-circle" style="width: 48px; height: 48px; margin-bottom: 16px; opacity: 0.5;"></i>
                <p>${message}</p>
            </div>
        `;
        
        // Recreate icons for the new content
        setTimeout(() => {
            if (window.lucide) lucide.createIcons();
        }, 100);
    }

    static showEmpty(containerId, message, iconName = 'inbox') {
        const container = document.getElementById(containerId);
        if (!container) return;
        
        container.innerHTML = `
            <div style="padding: 40px; text-align: center; color: #64748b;">
                <i data-lucide="${iconName}" style="width: 48px; height: 48px; margin-bottom: 16px; opacity: 0.5;"></i>
                <p>${message}</p>
            </div>
        `;
        
        // Recreate icons for the new content
        setTimeout(() => {
            if (window.lucide) lucide.createIcons();
        }, 100);
    }

    /**
     * Modal Management
     */
    static openModal(modalId) {
        const modal = document.getElementById(modalId);
        if (modal) {
            modal.style.display = 'flex';
            setTimeout(() => {
                if (window.lucide) lucide.createIcons();
            }, 100);
        }
    }

    static closeModal(modalId) {
        const modal = document.getElementById(modalId);
        if (modal) {
            modal.style.display = 'none';
        }
    }

    /**
     * Form Management
     */
    static resetForm(formId) {
        const form = document.getElementById(formId);
        if (form) {
            form.reset();
        }
    }

    static getFormData(formId) {
        const form = document.getElementById(formId);
        if (!form) return {};
        
        const formData = new FormData(form);
        const data = {};
        for (let [key, value] of formData.entries()) {
            data[key] = value.trim();
        }
        return data;
    }

    static validateEmail(email) {
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        return emailRegex.test(email);
    }

    /**
     * Filter Button Management
     */
    static updateFilterButtons(containerId, activeFilter) {
        const container = document.getElementById(containerId) || document.querySelector(`#${containerId}`);
        if (!container) return;
        
        const filterBtns = container.querySelectorAll('.filter-btn');
        filterBtns.forEach(btn => {
            btn.classList.remove('active');
            if (btn.dataset.filter === activeFilter) {
                btn.classList.add('active');
            }
        });
    }

    /**
     * Content Rendering with Lucide Icons
     */
    static renderContent(containerId, html) {
        const container = document.getElementById(containerId);
        if (!container) return;
        
        container.innerHTML = html;
        
        // Recreate icons for the new content
        setTimeout(() => {
            if (window.lucide) lucide.createIcons();
        }, 100);
    }

    /**
     * Teacher Card Rendering
     */
    static renderTeacherCard(teacher) {
        return `
            <div class="teacher-card">
                <div class="teacher-info">
                    <div class="teacher-name">${teacher.name}</div>
                    <div class="teacher-email">${teacher.email}</div>
                    ${teacher.note ? `<div class="teacher-note">${teacher.note}</div>` : ''}
                </div>
                <div class="teacher-status">
                    <span class="status-badge ${teacher.status === 'active' ? 'status-active' : 'status-archived'}">
                        ${teacher.status === 'active' ? 'Aktív' : 'Archivált'}
                    </span>
                </div>
                <div class="teacher-actions">
                    <button class="action-btn edit" onclick="editTeacher('${teacher.id}')" title="Szerkesztés">
                        <i data-lucide="edit-3" style="width: 12px; height: 12px;"></i>
                    </button>
                    ${teacher.status === 'active' ? 
                        `<button class="action-btn archive" onclick="archiveTeacher('${teacher.id}')" title="Archiválás">
                            <i data-lucide="archive" style="width: 12px; height: 12px;"></i>
                        </button>` :
                        `<button class="action-btn activate" onclick="activateTeacher('${teacher.id}')" title="Aktiválás">
                            <i data-lucide="user-check" style="width: 12px; height: 12px;"></i>
                        </button>`
                    }
                    <button class="action-btn delete" onclick="deleteTeacher('${teacher.id}')" title="Törlés">
                        <i data-lucide="trash-2" style="width: 12px; height: 12px;"></i>
                    </button>
                </div>
            </div>
        `;
    }

    /**
     * Classroom Card Rendering
     */
    static renderClassroomCard(classroom) {
        return `
            <div class="teacher-card">
                <div class="teacher-info">
                    <div class="teacher-name">${classroom.name}</div>
                    <div class="teacher-email">Csoport • Létrehozva: ${new Date(classroom.createdAt).toLocaleDateString('hu-HU')}</div>
                    ${classroom.description ? `<div class="teacher-note">${classroom.description}</div>` : ''}
                </div>
                <div class="teacher-status">
                    <span class="status-badge status-active">
                        Aktív
                    </span>
                </div>
                <div class="teacher-actions">
                    <button class="action-btn edit" onclick="manageClassroomTeachers('${classroom.id}')" title="Tanárok Kezelése" style="background: #6366f1; color: white;">
                        <i data-lucide="users" style="width: 12px; height: 12px;"></i>
                    </button>
                    <button class="action-btn edit" onclick="editClassroom('${classroom.id}')" title="Szerkesztés">
                        <i data-lucide="edit-3" style="width: 12px; height: 12px;"></i>
                    </button>
                    <button class="action-btn delete" onclick="deleteClassroom('${classroom.id}')" title="Törlés">
                        <i data-lucide="trash-2" style="width: 12px; height: 12px;"></i>
                    </button>
                </div>
            </div>
        `;
    }

    /**
     * Statistics Update
     */
    static updateStatistics(stats) {
        const elements = {
            teachers: document.querySelector('.stats .stat-card:nth-child(1) .stat-number'),
            classrooms: document.querySelector('.stats .stat-card:nth-child(2) .stat-number'),
            students: document.querySelector('.stats .stat-card:nth-child(3) .stat-number'),
            sets: document.querySelector('.stats .stat-card:nth-child(4) .stat-number')
        };

        Object.keys(elements).forEach(key => {
            if (elements[key] && stats[key] !== undefined) {
                elements[key].textContent = stats[key];
            }
        });
    }
}

// Export for use in HTML files
window.AdminUIManager = AdminUIManager;