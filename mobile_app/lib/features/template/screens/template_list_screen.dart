// template_list_screen.dart — قائمة القوالب الخاصة بالمهندس
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/template_model.dart';
import '../services/template_service.dart';

class TemplateListScreen extends StatefulWidget {
  const TemplateListScreen({super.key});

  @override
  State<TemplateListScreen> createState() => _TemplateListScreenState();
}

class _TemplateListScreenState extends State<TemplateListScreen> {
  final _templateService = TemplateService();

  Future<void> _deleteTemplate(TemplateModel template) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف القالب', style: TextStyle(fontFamily: 'Cairo')),
        content: Text('هل أنت متأكد من حذف قالب "${template.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف', style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _templateService.deleteTemplate(template);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('قوالبي الهندسية'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: StreamBuilder<List<TemplateModel>>(
        stream: _templateService.getUserTemplatesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ: ${snapshot.error}'));
          }

          final templates = snapshot.data ?? [];

          if (templates.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.description_outlined, size: 80, color: AppColors.textHint),
                  const SizedBox(height: 16),
                  const Text(
                    'لم تقم برفع أي قوالب بعد',
                    style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/home/templates/upload'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    icon: const Icon(Icons.upload_file_rounded),
                    label: const Text('رفع قالب جديد', style: TextStyle(fontFamily: 'Cairo')),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: templates.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final t = templates[index];
              return _TemplateCard(
                template: t,
                onDelete: () => _deleteTemplate(t),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/home/templates/upload'),
        backgroundColor: AppColors.accent,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final TemplateModel template;
  final VoidCallback onDelete;

  const _TemplateCard({required this.template, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMM yyyy', 'ar');
    final isWord = template.fileExtension == 'docx' || template.fileExtension == 'doc';
    final iconColor = isWord ? const Color(0xFF2B579A) : const Color(0xFF217346); // Word / Excel colors

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isWord ? Icons.description_rounded : Icons.table_chart_rounded,
            color: iconColor,
          ),
        ),
        title: Text(
          template.name,
          style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'نوع القالب: ${template.type == 'daily_report' ? 'تقرير يومي' : template.type == 'letter' ? 'خطاب' : 'مخصص'}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            Text(
              'أُضيف في: ${dateFormat.format(template.createdAt)} • ${template.placeholders.length} حقول متغيرة',
              style: const TextStyle(fontSize: 11, color: AppColors.textHint),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
          onPressed: onDelete,
        ),
      ),
    );
  }
}
