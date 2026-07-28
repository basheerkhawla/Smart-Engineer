// api_keys.dart — مفاتيح API (Backend فقط - لا ترسل المفاتيح من Flutter مباشرة)
class ApiKeys {
  // ===== Backend API URL =====
  // جميع استدعاءات AI تمر عبر Backend Node.js لحماية المفاتيح
  static const String backendBaseUrl =
      'http://10.0.2.2:5000'; // للمحاكي (Emulator)
  // static const String backendBaseUrl = 'http://192.168.1.x:5000'; // للجهاز الحقيقي

  // ===== Firebase =====
  // مفتاح Firebase موجود في google-services.json (لا يوضع هنا)
  static const String firebaseProjectId = 'smart-engineer-f7c0e';

  // ===== Backend Endpoints =====
  static const String generateReportEndpoint = '/api/ai/generate-report';
  static const String analyzeTemplateEndpoint = '/api/ai/analyze-template';
  static const String adminUsersEndpoint = '/api/admin/users';
  static const String sendNotificationEndpoint = '/api/notifications/send';

  // ===== ملاحظة أمنية =====
  // مفتاح Gemini AI محفوظ في ملف .env على Backend فقط
  // لا تضع مفاتيح API أبداً في كود Flutter (سيُرفع التطبيق على Play Store)
  // مفتاح Gemini: محفوظ في backend_api/.env
}
