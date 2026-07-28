// admin_routes.js — مسارات API الإدارية
const express = require('express');
const router = express.Router();
const admin = require('firebase-admin');

// تهيئة Firebase Admin (إذا لم يكن مهيأً)
const initAdmin = () => {
    if (!admin.apps.length) {
        admin.initializeApp({
            credential: admin.credential.applicationDefault(),
            projectId: 'smart-engineer-f7c0e',
        });
    }
    return admin.firestore();
};

// GET /api/admin/users — قائمة المستخدمين
router.get('/users', async (req, res) => {
    try {
        const db = initAdmin();
        const snap = await db.collection('users')
            .orderBy('createdAt', 'desc')
            .limit(200)
            .get();

        const users = snap.docs.map(doc => ({
            uid: doc.id,
            ...doc.data()
        }));

        res.json({ success: true, users });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// GET /api/admin/stats — إحصائيات عامة
router.get('/stats', async (req, res) => {
    try {
        const db = initAdmin();
        const snap = await db.collection('users').get();
        const users = snap.docs.map(d => d.data());

        const now = new Date();
        const thisMonth = now.getMonth();
        const thisYear = now.getFullYear();

        const stats = {
            totalUsers: users.length,
            activeUsers: users.filter(u => !u.isBlocked).length,
            blockedUsers: users.filter(u => u.isBlocked).length,
            paidUsers: users.filter(u => u.plan === 'paid').length,
            totalReports: users.reduce((sum, u) => sum + (u.reportsUsed || 0), 0),
            newThisMonth: users.filter(u => {
                if (!u.createdAt) return false;
                const d = u.createdAt.toDate ? u.createdAt.toDate() : new Date(u.createdAt);
                return d.getMonth() === thisMonth && d.getFullYear() === thisYear;
            }).length,
        };

        res.json({ success: true, stats });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// PATCH /api/admin/users/:uid — تعديل مستخدم
router.patch('/users/:uid', async (req, res) => {
    try {
        const { uid } = req.params;
        const updates = req.body;
        const db = initAdmin();

        await db.collection('users').doc(uid).update(updates);
        res.json({ success: true, message: 'تم تحديث المستخدم' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// DELETE /api/admin/users/:uid — حذف مستخدم
router.delete('/users/:uid', async (req, res) => {
    try {
        const { uid } = req.params;
        const db = initAdmin();

        // حذف من Firestore
        await db.collection('users').doc(uid).delete();

        // حذف من Firebase Auth
        try {
            await admin.auth().deleteUser(uid);
        } catch (_) {
            // قد لا يوجد في Auth
        }

        res.json({ success: true, message: 'تم حذف المستخدم' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

module.exports = router;
