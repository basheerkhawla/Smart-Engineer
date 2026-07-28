// ai_routes.js — مسارات API للذكاء الاصطناعي
const express = require('express');
const router = express.Router();
const { generateReportController, analyzeTemplateController } = require('../controllers/ai_controller');

// POST /api/ai/generate-report
router.post('/generate-report', generateReportController);

// POST /api/ai/analyze-template
router.post('/analyze-template', analyzeTemplateController);

module.exports = router;
