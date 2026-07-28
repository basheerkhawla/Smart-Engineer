// server.js — نقطة البداية المحدثة
require('dotenv').config();
const express = require('express');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(cors());
app.use(express.json({ limit: '10mb' }));

// Routes
app.get('/', (req, res) => {
    res.json({ 
        message: 'مهندس ذكي API — Smart Engineer',
        version: '1.0.0',
        status: 'running'
    });
});

// AI Routes
app.use('/api/ai', require('./routes/ai_routes'));

// Admin Routes
app.use('/api/admin', require('./routes/admin_routes'));

// Notification Routes
app.use('/api/notifications', require('./routes/notification_routes'));

// Health Check
app.get('/health', (req, res) => {
    res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// 404 Handler
app.use((req, res) => {
    res.status(404).json({ error: 'المسار غير موجود' });
});

// Start Server
app.listen(PORT, () => {
    console.log(`🚀 Smart Engineer API يعمل على المنفذ ${PORT}`);
});
