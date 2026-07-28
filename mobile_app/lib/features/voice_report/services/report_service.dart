// report_service.dart — خدمة التقارير الهندسية (Gemini AI + Firestore)
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/api_keys.dart';
import '../../../core/models/report_model.dart';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _pendingReportsKey = 'pending_reports';

  /// ===== إرسال النص لـ Gemini عبر Backend API =====
  Future<String> processWithGemini({
    required String voiceText,
    String? projectName,
    String? engineerName,
  }) async {
    // فحص الاتصال
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) {
      throw Exception('لا يوجد اتصال بالإنترنت — سيتم المعالجة لاحقاً');
    }

    final response = await http.post(
      Uri.parse('${ApiKeys.backendBaseUrl}${ApiKeys.generateReportEndpoint}'),
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode({
        'voiceText': voiceText,
        'projectName': projectName ?? '',
        'engineerName': engineerName ?? '',
      }),
    ).timeout(AppConstants.connectionTimeout);

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['report'] as String;
    } else {
      final err = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(err['error'] ?? 'خطأ في معالجة النص');
    }
  }

  /// ===== حفظ التقرير في Firestore =====
  Future<String> saveReport({
    required String voiceText,
    required String processedText,
    String? projectId,
    String? projectName,
    String? templateId,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('المستخدم غير مسجل');

    final docRef = _firestore
        .collection(AppConstants.reportsCollection)
        .doc(uid)
        .collection('user_reports')
        .doc();

    final report = ReportModel(
      id: docRef.id,
      userId: uid,
      templateId: templateId,
      projectId: projectId,
      projectName: projectName,
      voiceText: voiceText,
      processedText: processedText,
      status: 'processed',
      isSynced: true,
      createdAt: DateTime.now(),
    );

    await docRef.set(report.toFirestore());

    // زيادة عداد التقارير
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update({'reportsUsed': FieldValue.increment(1)});

    return docRef.id;
  }

  /// ===== حفظ محلي عند انعدام الإنترنت =====
  Future<void> saveReportLocally({
    required String voiceText,
    String? projectName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getStringList(_pendingReportsKey) ?? [];

    final localReport = {
      'id': _generateLocalId(),
      'voiceText': voiceText,
      'projectName': projectName,
      'createdAt': DateTime.now().toIso8601String(),
      'isSynced': false,
    };

    pending.add(jsonEncode(localReport));
    await prefs.setStringList(_pendingReportsKey, pending);
  }

  /// ===== مزامنة التقارير المعلقة عند عودة الإنترنت =====
  Future<int> syncPendingReports() async {
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getStringList(_pendingReportsKey) ?? [];
    if (pending.isEmpty) return 0;

    int synced = 0;
    final remaining = <String>[];

    for (final item in pending) {
      try {
        final data = jsonDecode(item) as Map<String, dynamic>;
        final processedText = await processWithGemini(
          voiceText: data['voiceText'],
          projectName: data['projectName'],
        );

        await saveReport(
          voiceText: data['voiceText'],
          processedText: processedText,
          projectName: data['projectName'],
        );
        synced++;
      } catch (_) {
        remaining.add(item); // أبقِه للمحاولة لاحقاً
      }
    }

    await prefs.setStringList(_pendingReportsKey, remaining);
    return synced;
  }

  /// ===== قائمة تقارير المستخدم =====
  Stream<List<ReportModel>> getReportsStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return _firestore
        .collection(AppConstants.reportsCollection)
        .doc(uid)
        .collection('user_reports')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) =>
            snap.docs.map(ReportModel.fromFirestore).toList());
  }

  /// ===== فحص عدد التقارير المعلقة =====
  Future<int> getPendingCount() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_pendingReportsKey) ?? []).length;
  }

  String _generateLocalId() =>
      'local_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';
}
