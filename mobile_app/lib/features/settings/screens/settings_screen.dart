// settings_screen.dart — شاشة الإعدادات
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/user_provider.dart';
import '../../../shared/widgets/loading_button.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('الإعدادات'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.primarySurface,
              child: Icon(Icons.person_rounded, size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              user?.displayName ?? 'مهندس',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            Text(
              user?.email ?? '',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),

            _buildSettingsTile(
              icon: Icons.workspace_premium_rounded,
              title: 'الاشتراك المميز',
              subtitle: user?.hasActivePaidSubscription == true ? 'اشتراكك نشط' : 'الترقية للنسخة المدفوعة',
              onTap: () => context.push('/home/subscription'),
            ),
            _buildSettingsTile(
              icon: Icons.shield_rounded,
              title: 'سياسة الخصوصية',
              onTap: () => context.push('/privacy-policy'),
            ),
            _buildSettingsTile(
              icon: Icons.contact_support_rounded,
              title: 'الدعم الفني',
              subtitle: 'support@smartengineer.app',
              onTap: () {},
            ),

            const SizedBox(height: 40),
            LoadingButton(
              label: 'تسجيل الخروج',
              isLoading: false,
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.error,
              onPressed: () async {
                await AuthService().signOut();
                if (context.mounted) context.go('/login');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primarySurface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)) : null,
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textHint),
    );
  }
}
