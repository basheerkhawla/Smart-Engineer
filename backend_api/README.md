# Smart Eng API (المهندس الذكي)

هذا المجلد يحتوي على الواجهة الخلفية (Backend API) لتطبيق المهندس الذكي.

## التقنيات المستخدمة
- Node.js
- Express
- CORS
- Dotenv

## هيكلية المجلدات
- `/controllers`: يحتوي على منطق التحكم (Business Logic).
- `/models`: يحتوي على نماذج قواعد البيانات.
- `/routes`: يحتوي على مسارات الـ API.
- `/services`: خدمات إضافية مثل التواصل مع خدمات الذكاء الاصطناعي (OpenAI Vision, RAG).

## التشغيل محلياً
1. تأكد من تثبيت الحزم عبر `npm install`
2. تشغيل الخادم عبر `node server.js`
