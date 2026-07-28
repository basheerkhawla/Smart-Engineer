// template_upload_screen.dart — شاشة رفع قالب هندسي جديد
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/loading_button.dart';
import '../services/template_service.dart';

class TemplateUploadScreen extends StatefulWidget {
  const TemplateUploadScreen({super.key});

  @override
  State<TemplateUploadScreen> createState() => _TemplateUploadScreenState();
}

class _TemplateUploadScreenState extends State<TemplateUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _templateService = TemplateService();

  File? _selectedFile;
  String _selectedType = 'daily_report';
  bool _isUploading = false;

  final List<Map<String, String>> _templateTypes = [
    {'value': 'daily_report', 'label': 'تقرير يومي'},
    {'value': 'letter', 'label': 'خطاب رسمي'},
    {'value': 'custom', 'label': 'نموذج مخصص'},
  ];

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['doc', 'docx', 'xls', 'xlsx'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() => _selectedFile = File(result.files.single.path!));
      }
    } catch (e) {
      if (mounted) AppSnackbar.showError(context, 'خطأ في اختيار الملف');
    }
  }

  Future<void> _uploadTemplate() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFile == null) {
      AppSnackbar.showError(context, 'الرجاء اختيار ملف القالب');
      return;
    }

    setState(() => _isUploading = true);

    try {
      // قراءة محتوى نصي بسيط مبدئياً للتحليل (أو يمكن إرسال الملف للـ Backend مباشرة)
      // هنا سنعتمد على أن القالب يحتوي كلمات يمكن استخراجها لاحقاً
      
      await _templateService.uploadTemplate(
        file: _selectedFile!,
        name: _nameController.text.trim(),
        type: _selectedType,
        textContent: 'قالب هندسي للتجربة', // في نظام حقيقي، يُفضّل إرسال الملف للـ Backend ليستخرج النص
      );

      if (mounted) {
        AppSnackbar.showSuccess(context, 'تم رفع القالب بنجاح وتحليله');
        context.pop();
      }
    } catch (e) {
      if (mounted) AppSnackbar.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('رفع قالب جديد'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== التعليمات =====
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text('كيف يعمل القالب؟', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary)),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'ارفع ملف Word أو Excel يحتوي على تصميمك. سيقوم الذكاء الاصطناعي بتحليله لمعرفة الحقول المتغيرة (مثل التاريخ، اسم المشروع، الكميات) ليتم تعبئتها تلقائياً لاحقاً بناءً على تسجيلك الصوتي.',
                      style: TextStyle(color: AppColors.textSecondary, height: 1.5, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ===== بيانات القالب =====
              CustomTextField(
                controller: _nameController,
                label: 'اسم القالب',
                hint: 'مثال: تقرير الموقع اليومي',
                prefixIcon: Icons.title_rounded,
                validator: (v) => (v == null || v.isEmpty) ? 'أدخل اسم القالب' : null,
              ),
              const SizedBox(height: 16),

              const Text('نوع القالب', style: TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedType,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
                    items: _templateTypes.map((t) => DropdownMenuItem(
                      value: t['value'],
                      child: Text(t['label']!, style: const TextStyle(fontFamily: 'Cairo')),
                    )).toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedType = v);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ===== اختيار الملف =====
              GestureDetector(
                onTap: _isUploading ? null : _pickFile,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _selectedFile != null ? AppColors.success : AppColors.border,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _selectedFile != null ? Icons.check_circle_outline_rounded : Icons.upload_file_rounded,
                        size: 48,
                        color: _selectedFile != null ? AppColors.success : AppColors.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _selectedFile != null ? 'تم اختيار الملف بنجاح' : 'اضغط لاختيار ملف (Word/Excel)',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _selectedFile != null ? AppColors.success : AppColors.textPrimary,
                        ),
                      ),
                      if (_selectedFile != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _selectedFile!.path.split('/').last.split('\\').last, // لدعم Windows/Android
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ]
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ===== زر الرفع =====
              LoadingButton(
                label: 'رفع وتحليل القالب',
                isLoading: _isUploading,
                onPressed: _uploadTemplate,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
