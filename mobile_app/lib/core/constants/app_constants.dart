// app_constants.dart — ثوابت التطبيق
class AppConstants {
  // معلومات التطبيق
  static const String appName = 'مهندس ذكي';
  static const String appNameEn = 'Smart Engineer';
  static const String packageName = 'com.bas.SmartEngineer';
  static const String privacyPolicyUrl =
      'https://smart-engineer-f7c0e.web.app/privacy-policy';
  static const String termsOfServiceUrl =
      'https://smart-engineer-f7c0e.web.app/terms';

  // مسارات Firestore
  static const String usersCollection = 'users';
  static const String templatesCollection = 'templates';
  static const String projectsCollection = 'projects';
  static const String reportsCollection = 'reports';
  static const String appConfigDoc = 'app_config/settings';
  static const String logsCollection = 'logs';
  static const String notificationsCollection = 'notifications';

  // حدود الخطة المجانية
  static const int freeMonthlyReports = 5;
  static const int freeTemplates = 1;
  static const int freeProjects = 2;

  // الاشتراك
  static const String subscriptionProductId = 'smart_engineer_monthly_5usd';
  static const double subscriptionPrice = 5.0;
  static const String subscriptionCurrency = 'USD';

  // الإشعارات
  static const String notificationChannelId = 'smart_engineer_notifications';
  static const String notificationChannelName = 'إشعارات مهندس ذكي';

  // Hive Boxes (التخزين المحلي)
  static const String userBox = 'user_box';
  static const String reportsBox = 'reports_box';
  static const String pendingUploadsBox = 'pending_uploads_box';
  static const String settingsBox = 'settings_box';

  // مهل الشبكة
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // حدود الملفات
  static const int maxTemplateSizeMB = 10;
  static const int maxImageSizeMB = 5;
  static const List<String> allowedTemplateExtensions = ['docx', 'xlsx', 'doc', 'xls'];

  // إعدادات الختم على الصور
  static const double stampFontSize = 11.0;
  static const double stampPadding = 8.0;
  static const double stampOpacity = 0.85;
}
