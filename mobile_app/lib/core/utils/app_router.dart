// app_router.dart — نظام التنقل المحدث (المرحلة الثانية)
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/email_verification_screen.dart';
import '../../features/auth/screens/privacy_policy_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/admin/screens/users_list_screen.dart';
import '../../features/subscription/subscription_screen.dart';
import '../../features/template/screens/template_list_screen.dart';
import '../../features/template/screens/template_upload_screen.dart';
import '../../features/voice_report/screens/voice_recorder_screen.dart';
import '../../features/voice_report/screens/report_preview_screen.dart';
import '../../features/stamped_camera/screens/stamped_camera_screen.dart';
import '../../features/calculator/screens/calculator_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../services/user_provider.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final user = FirebaseAuth.instance.currentUser;
      final isLoggedIn = user != null;
      final loc = state.matchedLocation;

      final isAuthRoute = loc == '/login' ||
          loc == '/register' ||
          loc == '/forgot-password' ||
          loc == '/privacy-policy';

      // غير مسجل → الدخول
      if (!isLoggedIn && !isAuthRoute) return '/login';

      // مسجل لكن إيميل غير مؤكد
      if (isLoggedIn &&
          !user.emailVerified &&
          loc != '/verify-email' &&
          loc != '/privacy-policy') {
        return '/verify-email';
      }

      // مسجل ومؤكد → لا ترسله لصفحات الدخول
      if (isLoggedIn && user.emailVerified && isAuthRoute) return '/home';

      return null;
    },
    routes: [
      // ===== Auth =====
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/forgot-password', builder: (_, __) => const ForgotPasswordScreen()),
      GoRoute(path: '/verify-email', builder: (_, __) => const EmailVerificationScreen()),
      GoRoute(path: '/privacy-policy', builder: (_, __) => const PrivacyPolicyScreen()),

      // ===== الشاشة الرئيسية =====
      GoRoute(
        path: '/home',
        builder: (_, __) => const HomeScreen(),
        routes: [
          GoRoute(path: 'templates', builder: (_, __) => const TemplateListScreen()),
          GoRoute(path: 'templates/upload', builder: (_, __) => const TemplateUploadScreen()),
          GoRoute(path: 'voice-report', builder: (_, __) => const VoiceRecorderScreen()),
          GoRoute(
            path: 'voice-report/preview',
            builder: (_, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return ReportPreviewScreen(
                processedText: extra?['processedText'] ?? '',
                voiceText: extra?['voiceText'] ?? '',
              );
            },
          ),
          GoRoute(path: 'camera', builder: (_, __) => const StampedCameraScreen()),
          GoRoute(path: 'calculator', builder: (_, __) => const CalculatorScreen()),
          GoRoute(path: 'subscription', builder: (_, __) => const SubscriptionScreen()),
          GoRoute(path: 'settings', builder: (_, __) => const SettingsScreen()),
        ],
      ),

      // ===== لوحة التحكم الإدارية =====
      GoRoute(
        path: '/admin',
        redirect: (context, state) {
          final userProvider = Provider.of<UserProvider>(context, listen: false);
          if (!userProvider.isAdmin) return '/home';
          return null;
        },
        builder: (_, __) => const AdminDashboardScreen(),
        routes: [
          GoRoute(
            path: 'users',
            builder: (_, __) => const UsersListScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text('الصفحة غير موجودة\n${state.uri}',
                textAlign: TextAlign.center),
          ],
        ),
      ),
    ),
  );
}
