// notification_routes.js — مسارات الإشعارات عبر FCM
const express = require('express');
const router = express.Router();
const admin = require('firebase-admin');

const getAdmin = () => {
    if (!admin.apps.length) {
        admin.initializeApp({
            credential: admin.credential.applicationDefault(),
            projectId: 'smart-engineer-f7c0e',
        });
    }
    return admin;
};

// POST /api/notifications/send — إرسال إشعار عام لكل المستخدمين
router.post('/send', async (req, res) => {
    try {
        const { title, body, topic = 'all_users' } = req.body;

        if (!title || !body) {
            return res.status(400).json({ error: 'العنوان والنص مطلوبان' });
        }

        const fb = getAdmin();

        // إرسال عبر FCM Topic (كل المشتركين في topic)
        const message = {
            notification: { title, body },
            android: {
                notification: {
                    channelId: 'smart_engineer_notifications',
                    priority: 'high',
                },
            },
            topic,
        };

        const response = await fb.messaging().send(message);

        // حفظ في Firestore للسجل
        await fb.firestore().collection('notifications').add({
            title,
            body,
            topic,
            messageId: response,
            sentAt: admin.firestore.Timestamp.now(),
            type: 'global',
        });

        res.json({
            success: true,
            messageId: response,
            message: 'تم إرسال الإشعار بنجاح',
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

module.exports = router;
