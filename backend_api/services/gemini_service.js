// gemini_service.js — خدمة Gemini AI
const { GoogleGenerativeAI } = require('@google/generative-ai');

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

const ENGINEERING_SYSTEM_PROMPT = `أنت مساعد هندسي متخصص للمهندسين المدنيين الميدانيين في السوق الخليجي.
تلقيت ملاحظات خام من مهندس في الموقع.

مهمتك: تحويل هذه الملاحظات إلى تقرير هندسي منظم ومهني باللغة العربية.

يجب أن يحتوي التقرير على:
1. **ملخص نشاطات اليوم** — ما تم تنفيذه بشكل واضح
2. **المشاهدات الميدانية** — ما لاحظه المهندس في الموقع
3. **المواد والكميات** — إذا ذُكرت (حديد، خرسانة، مواد...)
4. **المشكلات والعقبات** — إن وجدت
5. **التوصيات والإجراءات المطلوبة** — ما يجب اتخاذه

القواعد:
- أسلوب مهني رسمي مناسب للتوثيق الهندسي
- لا تضف معلومات لم يذكرها المهندس
- إذا كانت الملاحظة مبهمة، استخدم ما يمكن فهمه فقط
- تنسيق واضح بعناوين وفقرات`;

async function generateReport(voiceText, projectName, engineerName) {
  const model = genAI.getGenerativeModel({ model: 'gemini-1.5-flash' });

  const prompt = `${ENGINEERING_SYSTEM_PROMPT}

**اسم المشروع:** ${projectName || 'غير محدد'}
**اسم المهندس:** ${engineerName || 'غير محدد'}
**التاريخ:** ${new Date().toLocaleDateString('ar-SA')}

**الملاحظات الميدانية الخام:**
${voiceText}

أنشئ التقرير الهندسي:`;

  const result = await model.generateContent(prompt);
  return result.response.text();
}

async function analyzeTemplate(templateContent) {
  const model = genAI.getGenerativeModel({ model: 'gemini-1.5-flash' });

  const prompt = `قمت باستخراج النص من قالب تقرير هندسي (Word/Excel).
حلّل هذا القالب واستخرج الحقول القابلة للتعبئة.

نص القالب:
${templateContent}

أعد قائمة JSON بالحقول المكتشفة بهذا الشكل:
{
  "fields": [
    {"key": "التاريخ", "type": "date", "label": "تاريخ التقرير"},
    {"key": "اسم_المشروع", "type": "text", "label": "اسم المشروع"},
    ...
  ]
}

أنواع الحقول المتاحة: text, date, number, textarea`;

  const result = await model.generateContent(prompt);
  const text = result.response.text();
  
  // استخراج JSON
  const jsonMatch = text.match(/\{[\s\S]*\}/);
  if (jsonMatch) {
    return JSON.parse(jsonMatch[0]);
  }
  return { fields: [] };
}

module.exports = { generateReport, analyzeTemplate };
