// ai_controller.js — تحكم AI
const { generateReport, analyzeTemplate } = require('../services/gemini_service');

const generateReportController = async (req, res) => {
  try {
    const { voiceText, projectName, engineerName } = req.body;
    
    if (!voiceText || voiceText.trim().length < 10) {
      return res.status(400).json({ error: 'النص قصير جداً للمعالجة' });
    }

    const report = await generateReport(voiceText, projectName, engineerName);
    res.json({ success: true, report });
  } catch (error) {
    console.error('Gemini Error:', error);
    res.status(500).json({ error: 'خطأ في معالجة النص بالذكاء الاصطناعي' });
  }
};

const analyzeTemplateController = async (req, res) => {
  try {
    const { templateContent } = req.body;

    if (!templateContent) {
      return res.status(400).json({ error: 'محتوى القالب مطلوب' });
    }

    const analysis = await analyzeTemplate(templateContent);
    res.json({ success: true, ...analysis });
  } catch (error) {
    console.error('Template Analysis Error:', error);
    res.status(500).json({ error: 'خطأ في تحليل القالب' });
  }
};

module.exports = { generateReportController, analyzeTemplateController };
