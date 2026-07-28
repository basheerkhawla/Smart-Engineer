// report_preview_screen.dart — شاشة معاينة التقرير الصوتي
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/app_snackbar.dart';

class ReportPreviewScreen extends StatelessWidget {
  final String processedText;
  final String voiceText;

  const ReportPreviewScreen({
    super.key,
    required this.processedText,
    required this.voiceText,
  });

  Future<void> _copyToClipboard(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      AppSnackbar.showSuccess(context, 'تم نسخ النص بنجاح');
    }
  }

  Future<void> _shareText(String text) async {
    await Share.share(text, subject: 'تقرير هندسي - مهندس ذكي');
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('معاينة التقرير'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded),
            onPressed: () => context.pop(),
          ),
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'التقرير المعالج ✨'),
              Tab(text: 'النص الأصلي 🎤'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildTextView(context, processedText, true),
            _buildTextView(context, voiceText, false),
          ],
        ),
      ),
    );
  }

  Widget _buildTextView(BuildContext context, String text, bool isProcessed) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  text,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.8,
                    color: AppColors.textPrimary,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // ===== أزرار الإجراءات =====
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _copyToClipboard(context, text),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.primary,
                    minimumSize: const Size(0, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('نسخ', style: TextStyle(fontFamily: 'Cairo')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _shareText(text),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.share_rounded),
                  label: const Text('مشاركة', style: TextStyle(fontFamily: 'Cairo')),
                ),
              ),
            ],
          ),
          
          if (isProcessed) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  // TODO: إضافة تصدير كـ PDF لاحقاً
                  AppSnackbar.showInfo(context, 'ميزة التصدير لـ PDF قادمة قريباً');
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  minimumSize: const Size(0, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.picture_as_pdf_rounded),
                label: const Text('تصدير كـ PDF', style: TextStyle(fontFamily: 'Cairo')),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
