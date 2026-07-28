// privacy_policy_screen.dart — شاشة سياسة الخصوصية (Google Play Compliant)
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('سياسة الخصوصية'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: _PrivacyContent(),
      ),
    );
  }
}

class _PrivacyContent extends StatelessWidget {
  const _PrivacyContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitle('سياسة الخصوصية — مهندس ذكي'),
        _buildText('آخر تحديث: يوليو 2026'),
        const SizedBox(height: 20),

        _buildSection('1. البيانات التي نجمعها', [
          'الاسم والبريد الإلكتروني: للتعريف بك وإدارة حسابك',
          'بيانات الموقع الجغرافي (GPS): لختم الصور وتوثيق موقع الموقع الهندسي',
          'الملاحظات الصوتية والنصية: لإنشاء التقارير الهندسية بالذكاء الاصطناعي',
          'القوالب المرفوعة (Word/Excel): لتعبئة التقارير الهندسية',
          'صور الموقع: للتوثيق الميداني مع الختم',
        ]),

        _buildSection('2. الغرض من جمع البيانات', [
          'تشغيل خدمات التطبيق (التقارير، الختم على الصور، الحاسبات) فقط',
          'لا تُستخدم بياناتك للإعلانات المستهدفة أو البيع لأطراف ثالثة',
        ]),

        _buildSection('3. مشاركة البيانات مع أطراف ثالثة', [
          'Google Firebase: لتخزين البيانات والمصادقة (نخدمك عبر سحابة Google)',
          'Google Gemini AI: الملاحظات الصوتية/النصوص تُرسل لخدمة Gemini AI لمعالجتها وتوليد التقارير — لا تُحفظ هذه البيانات من قِبل Google بشكل دائم وفق سياستهم',
          'Google AdMob: للإعلانات (للمستخدمين غير المشتركين) وفق سياسة Google',
          'لا تُباع بياناتك أو تُشارك مع أي جهة تجارية أخرى',
        ]),

        _buildSection('4. حقوقك', [
          'حق طلب حذف حسابك وجميع بياناتك نهائياً',
          'حق تعديل معلوماتك الشخصية',
          'حق سحب الموافقة على الموقع الجغرافي من إعدادات جهازك',
          'لممارسة حقوقك، تواصل معنا عبر: support@smartengineer.app',
        ]),

        _buildSection('5. أمان البيانات', [
          'جميع الاتصالات مشفرة بـ HTTPS/TLS',
          'كلمات المرور مشفرة ولا تُخزَّن بشكل واضح',
          'قاعدة البيانات محمية بـ Firebase Security Rules',
        ]),

        _buildSection('6. أذونات الجهاز وسبب استخدامها', [
          'الكاميرا: التقاط صور الموقع بالختم التوثيقي',
          'الموقع الجغرافي: إضافة إحداثيات GPS على صور الموقع',
          'الميكروفون: تسجيل الملاحظات الصوتية الميدانية',
          'التخزين: حفظ الصور والتقارير على الجهاز',
        ]),

        _buildSection('7. وضع عدم الاتصال', [
          'التقارير والصور تُحفظ محلياً على جهازك عند انعدام الإنترنت',
          'تُرفع ومعالجتها تلقائياً عند عودة الاتصال',
        ]),

        _buildSection('8. الاحتفاظ بالبيانات', [
          'نحتفظ ببياناتك طالما حسابك نشط',
          'عند طلب حذف الحساب، تُحذف البيانات خلال 30 يوم',
        ]),

        const SizedBox(height: 20),
        _buildText(
          'إذا كان لديك أي سؤال حول سياسة الخصوصية، تواصل معنا:\nsupport@smartengineer.app',
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildSection(String title, List<String> points) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        ...points.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ',
                      style: TextStyle(color: AppColors.accent, fontSize: 16)),
                  Expanded(
                    child: Text(
                      p,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildText(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        color: AppColors.textHint,
        height: 1.6,
      ),
    );
  }
}
