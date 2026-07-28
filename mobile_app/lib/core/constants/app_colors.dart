// app_colors.dart — نظام الألوان للتطبيق
import 'package:flutter/material.dart';

class AppColors {
  // الألوان الرئيسية — درجات الأزرق الهندسي العميق
  static const Color primary = Color(0xFF1A3A5C);         // أزرق داكن هندسي
  static const Color primaryLight = Color(0xFF2E5F8A);    // أزرق متوسط
  static const Color primarySurface = Color(0xFFE8F1FA);  // أزرق فاتح جداً

  // اللون الثانوي — ذهبي احترافي
  static const Color accent = Color(0xFFD4A843);          // ذهبي
  static const Color accentLight = Color(0xFFF0C860);     // ذهبي فاتح

  // ألوان الخلفية
  static const Color background = Color(0xFFF5F7FA);      // رمادي فاتح جداً
  static const Color surface = Color(0xFFFFFFFF);         // أبيض
  static const Color cardBackground = Color(0xFFFFFFFF);  // بطاقات

  // ألوان النصوص
  static const Color textPrimary = Color(0xFF1A2B3C);     // نص رئيسي داكن
  static const Color textSecondary = Color(0xFF5A7184);   // نص ثانوي
  static const Color textHint = Color(0xFF9BAEC2);        // نص تلميح

  // ألوان الحالة
  static const Color success = Color(0xFF27AE60);
  static const Color warning = Color(0xFFF39C12);
  static const Color error = Color(0xFFE74C3C);
  static const Color info = Color(0xFF3498DB);

  // ألوان المخطط (Divider, Border)
  static const Color border = Color(0xFFDEE6F0);
  static const Color divider = Color(0xFFEAEFF5);

  // أزرار وخلفيات
  static const Color buttonPrimary = Color(0xFF1A3A5C);
  static const Color buttonSecondary = Color(0xFFE8F1FA);
  static const Color blocked = Color(0xFFFDECEC);

  // Gradient للهيدر
  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFF1A3A5C), Color(0xFF2E5F8A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFD4A843), Color(0xFFF0C860)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
