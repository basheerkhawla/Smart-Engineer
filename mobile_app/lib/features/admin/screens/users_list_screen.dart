// users_list_screen.dart — قائمة المستخدمين مع بحث وفلتر
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/admin_service.dart';
import '../../../shared/widgets/app_snackbar.dart';

class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key});

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  final _adminService = AdminService();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterType = 'all'; // all, blocked, paid, free

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<UserModel> _applyFilter(List<UserModel> users) {
    switch (_filterType) {
      case 'blocked':
        return users.where((u) => u.isBlocked).toList();
      case 'paid':
        return users.where((u) => u.hasActivePaidSubscription).toList();
      case 'free':
        return users
            .where((u) => !u.hasActivePaidSubscription && !u.isBlocked)
            .toList();
      default:
        return users;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('إدارة المستخدمين'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // ===== شريط البحث =====
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              textDirection: TextDirection.rtl,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'ابحث بالاسم أو البريد الإلكتروني...',
                prefixIcon:
                    const Icon(Icons.search_rounded, color: AppColors.textHint),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),

          // ===== فلتر الفئات =====
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.only(bottom: 12, right: 16, left: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip('الكل', 'all'),
                  const SizedBox(width: 8),
                  _FilterChip('محظورون', 'blocked'),
                  const SizedBox(width: 8),
                  _FilterChip('مشتركون', 'paid'),
                  const SizedBox(width: 8),
                  _FilterChip('مجاني', 'free'),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          // ===== قائمة المستخدمين =====
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: _adminService.getUsersStream(
                searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: AppColors.primary));
                }

                if (snapshot.hasError) {
                  return Center(child: Text('خطأ: ${snapshot.error}'));
                }

                final allUsers = snapshot.data ?? [];
                final users = _applyFilter(allUsers);

                if (users.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline,
                            size: 60, color: AppColors.textHint),
                        SizedBox(height: 12),
                        Text('لا يوجد مستخدمون',
                            style: TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: users.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _UserCard(
                    user: users[i],
                    adminService: _adminService,
                    onAction: () => setState(() {}),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _FilterChip(String label, String value) {
    final selected = _filterType == value;
    return GestureDetector(
      onTap: () => setState(() => _filterType = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontFamily: 'Cairo',
            color: selected ? Colors.white : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ===== بطاقة مستخدم =====
class _UserCard extends StatelessWidget {
  final UserModel user;
  final AdminService adminService;
  final VoidCallback onAction;

  const _UserCard({
    required this.user,
    required this.adminService,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMM yyyy', 'ar');

    return Container(
      decoration: BoxDecoration(
        color: user.isBlocked
            ? const Color(0xFFFDECEC)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: user.isBlocked ? AppColors.error.withOpacity(0.3) : AppColors.border,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: AppColors.primarySurface,
          child: Text(
            user.displayName.isNotEmpty
                ? user.displayName[0].toUpperCase()
                : '؟',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                user.displayName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            // شارات الحالة
            if (user.isBlocked)
              _StatusBadge('محظور', AppColors.error),
            if (user.hasActivePaidSubscription)
              _StatusBadge('مشترك ⭐', AppColors.accent),
            if (user.isAdFree && !user.hasActivePaidSubscription)
              _StatusBadge('بلا إعلانات', AppColors.info),
            if (user.role == 'admin')
              _StatusBadge('أدمن', AppColors.primary),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            Text(
              'مسجل: ${dateFormat.format(user.createdAt)} • التقارير: ${user.reportsUsed}/${user.maxReports}',
              style: const TextStyle(fontSize: 11, color: AppColors.textHint),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
          onSelected: (action) => _handleAction(context, action),
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'toggle_block',
              child: Row(
                children: [
                  Icon(
                    user.isBlocked ? Icons.lock_open_rounded : Icons.block_rounded,
                    size: 18,
                    color: user.isBlocked ? AppColors.success : AppColors.error,
                  ),
                  const SizedBox(width: 8),
                  Text(user.isBlocked ? 'إلغاء الحظر' : 'حظر المستخدم',
                      style: const TextStyle(fontFamily: 'Cairo')),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'toggle_ad_free',
              child: Row(
                children: [
                  Icon(
                    user.isAdFree ? Icons.ads_click : Icons.block_rounded,
                    size: 18,
                    color: AppColors.info,
                  ),
                  const SizedBox(width: 8),
                  Text(user.isAdFree ? 'تفعيل الإعلانات' : 'إلغاء الإعلانات',
                      style: const TextStyle(fontFamily: 'Cairo')),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'edit_reports',
              child: Row(
                children: [
                  Icon(Icons.edit_rounded, size: 18, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text('تعديل حد التقارير', style: TextStyle(fontFamily: 'Cairo')),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'toggle_plan',
              child: Row(
                children: [
                  Icon(
                    user.hasActivePaidSubscription
                        ? Icons.arrow_downward_rounded
                        : Icons.workspace_premium_rounded,
                    size: 18,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    user.hasActivePaidSubscription ? 'تخفيض للمجاني' : 'ترقية للمدفوع',
                    style: const TextStyle(fontFamily: 'Cairo'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAction(BuildContext context, String action) async {
    switch (action) {
      case 'toggle_block':
        await adminService.toggleBlockUser(user.uid, !user.isBlocked);
        if (context.mounted) {
          AppSnackbar.showSuccess(
            context,
            user.isBlocked ? 'تم إلغاء الحظر' : 'تم حظر المستخدم',
          );
        }
        break;

      case 'toggle_ad_free':
        await adminService.toggleAdFree(user.uid, !user.isAdFree);
        if (context.mounted) {
          AppSnackbar.showSuccess(
            context,
            user.isAdFree ? 'تم تفعيل الإعلانات' : 'تم إلغاء الإعلانات لهذا المستخدم',
          );
        }
        break;

      case 'edit_reports':
        _showEditReportsDialog(context);
        break;

      case 'toggle_plan':
        final newPlan = user.hasActivePaidSubscription ? 'free' : 'paid';
        await adminService.updatePlan(user.uid, newPlan);
        if (context.mounted) {
          AppSnackbar.showSuccess(
            context,
            newPlan == 'paid' ? 'تمت الترقية للخطة المدفوعة' : 'تم التخفيض للخطة المجانية',
          );
        }
        break;
    }
    onAction();
  }

  void _showEditReportsDialog(BuildContext context) {
    final controller = TextEditingController(text: user.maxReports.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تعديل حد التقارير — ${user.displayName}',
            style: const TextStyle(fontFamily: 'Cairo', fontSize: 15)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          textDirection: TextDirection.rtl,
          decoration: const InputDecoration(
            labelText: 'الحد الشهري للتقارير',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              final val = int.tryParse(controller.text);
              if (val != null && val > 0) {
                await adminService.updateMaxReports(user.uid, val);
                if (context.mounted) {
                  Navigator.pop(ctx);
                  AppSnackbar.showSuccess(context, 'تم تحديث الحد إلى $val تقرير');
                }
              }
            },
            child: const Text('حفظ',
                style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }
}

Widget _StatusBadge(String label, Color color) {
  return Container(
    margin: const EdgeInsets.only(right: 4),
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 9,
        fontFamily: 'Cairo',
        color: color,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
