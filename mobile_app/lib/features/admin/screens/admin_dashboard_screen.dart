// admin_dashboard_screen.dart — لوحة التحكم الرئيسية
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/admin_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _adminService = AdminService();
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _adminService.getDashboardStats();
      if (mounted) setState(() => _stats = stats);
    } catch (e) {
      debugPrint('خطأ في تحميل الإحصائيات: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('لوحة التحكم الإدارية'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadStats,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ===== الإحصائيات =====
                    const Text(
                      'نظرة عامة',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildStatsGrid(),
                    const SizedBox(height: 24),

                    // ===== أزرار الإجراءات =====
                    const Text(
                      'الإجراءات',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildActionButtons(context),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatsGrid() {
    final stats = _stats ?? {};
    final items = [
      _StatItem('إجمالي المستخدمين', '${stats['totalUsers'] ?? 0}',
          Icons.people_rounded, AppColors.primary),
      _StatItem('مستخدمون نشطون', '${stats['activeUsers'] ?? 0}',
          Icons.person_rounded, AppColors.success),
      _StatItem('محظورون', '${stats['blockedUsers'] ?? 0}',
          Icons.block_rounded, AppColors.error),
      _StatItem('مشتركون مدفوعون', '${stats['paidUsers'] ?? 0}',
          Icons.workspace_premium_rounded, AppColors.accent),
      _StatItem('إجمالي التقارير', '${stats['totalReports'] ?? 0}',
          Icons.description_rounded, AppColors.info),
      _StatItem('جدد هذا الشهر', '${stats['newUsersThisMonth'] ?? 0}',
          Icons.fiber_new_rounded, AppColors.primaryLight),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => _buildStatCard(items[i]),
    );
  }

  Widget _buildStatCard(_StatItem item) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: item.color.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(item.icon, color: item.color, size: 18),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: item.color,
                ),
              ),
              Text(
                item.label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        _ActionButton(
          icon: Icons.people_rounded,
          label: 'إدارة المستخدمين',
          subtitle: 'بحث، حظر، تعديل الخطط',
          color: AppColors.primary,
          onTap: () => context.push('/admin/users'),
        ),
        const SizedBox(height: 10),
        _ActionButton(
          icon: Icons.notifications_rounded,
          label: 'إرسال إشعار عام',
          subtitle: 'إشعار لكل المستخدمين',
          color: AppColors.info,
          onTap: () => _showSendNotificationDialog(context),
        ),
        const SizedBox(height: 10),
        _ActionButton(
          icon: Icons.bar_chart_rounded,
          label: 'تقرير الاستخدام',
          subtitle: 'إحصائيات تفصيلية',
          color: AppColors.success,
          onTap: () {},
        ),
      ],
    );
  }

  void _showSendNotificationDialog(BuildContext context) {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إرسال إشعار عام',
            style: TextStyle(fontFamily: 'Cairo')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              textDirection: TextDirection.rtl,
              decoration: const InputDecoration(
                labelText: 'عنوان الإشعار',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bodyController,
              textDirection: TextDirection.rtl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'نص الإشعار',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              if (titleController.text.isNotEmpty &&
                  bodyController.text.isNotEmpty) {
                await _adminService.sendGlobalNotification(
                  title: titleController.text,
                  body: bodyController.text,
                );
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم إرسال الإشعار بنجاح'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              }
            },
            child: const Text('إرسال',
                style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }
}

// ===== مساعد: بطاقة إحصاء =====
class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  _StatItem(this.label, this.value, this.icon, this.color);
}

// ===== مساعد: زر إجراء =====
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: AppColors.textPrimary)),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}

// ===== Placeholder Screens (يُستخدم من app_router) =====
class TemplateListScreen extends StatelessWidget {
  const TemplateListScreen({super.key});
  @override
  Widget build(BuildContext context) => _buildPlaceholder(context, 'قوالبي', Icons.description_outlined);
}
class TemplateUploadScreen extends StatelessWidget {
  const TemplateUploadScreen({super.key});
  @override
  Widget build(BuildContext context) => _buildPlaceholder(context, 'رفع قالب', Icons.upload_file);
}
class VoiceRecorderScreen extends StatelessWidget {
  const VoiceRecorderScreen({super.key});
  @override
  Widget build(BuildContext context) => _buildPlaceholder(context, 'التقرير الصوتي', Icons.mic_rounded);
}
class ReportPreviewScreen extends StatelessWidget {
  const ReportPreviewScreen({super.key});
  @override
  Widget build(BuildContext context) => _buildPlaceholder(context, 'معاينة التقرير', Icons.article_outlined);
}
class StampedCameraScreen extends StatelessWidget {
  const StampedCameraScreen({super.key});
  @override
  Widget build(BuildContext context) => _buildPlaceholder(context, 'كاميرا الموقع', Icons.camera_alt_rounded);
}
class CalculatorScreen extends StatelessWidget {
  const CalculatorScreen({super.key});
  @override
  Widget build(BuildContext context) => _buildPlaceholder(context, 'حاسبة الكميات', Icons.calculate_outlined);
}
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) => _buildPlaceholder(context, 'الإعدادات', Icons.settings_outlined);
}

Widget _buildPlaceholder(BuildContext context, String title, IconData icon) {
  return Scaffold(
    appBar: AppBar(
      title: Text(title),
      leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded), onPressed: () => Navigator.pop(context)),
    ),
    body: Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 72, color: AppColors.primaryLight),
        const SizedBox(height: 16),
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        const Text('قيد التطوير — المرحلة الثالثة', style: TextStyle(color: AppColors.textSecondary)),
      ]),
    ),
  );
}
