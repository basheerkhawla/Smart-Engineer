// template_service.dart — خدمة إدارة القوالب الهندسية
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/api_keys.dart';
import '../../../core/models/template_model.dart';

class TemplateService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// تحليل القالب عبر Gemini AI (backend API)
  Future<List<TemplatePlaceholder>> analyzeTemplate(String textContent) async {
    final response = await http.post(
      Uri.parse('${ApiKeys.backendBaseUrl}/api/ai/analyze-template'),
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode({'templateContent': textContent}),
    ).timeout(AppConstants.connectionTimeout);

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data['success'] == true && data['fields'] != null) {
        final fields = data['fields'] as List;
        return fields.map((f) => TemplatePlaceholder.fromMap(f)).toList();
      }
      return [];
    } else {
      throw Exception('فشل في تحليل القالب');
    }
  }

  /// رفع القالب إلى Firebase Storage وحفظه في Firestore
  Future<void> uploadTemplate({
    required File file,
    required String name,
    required String type,
    required String textContent, // محتوى مبدئي للتحليل إن وجد
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('المستخدم غير مسجل');

    // 1. تحليل الحقول
    List<TemplatePlaceholder> placeholders = [];
    if (textContent.isNotEmpty) {
      placeholders = await analyzeTemplate(textContent);
    }

    // 2. رفع الملف للـ Storage
    final ext = file.path.split('.').last;
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';
    final ref = _storage.ref().child('templates/$uid/$fileName');
    
    final uploadTask = await ref.putFile(file);
    final fileUrl = await uploadTask.ref.getDownloadURL();

    // 3. حفظ المستند في Firestore
    final docRef = _firestore
        .collection('templates')
        .doc(uid)
        .collection('user_templates')
        .doc();

    final template = TemplateModel(
      id: docRef.id,
      userId: uid,
      name: name,
      type: type,
      fileUrl: fileUrl,
      fileName: fileName,
      fileExtension: ext,
      placeholders: placeholders,
      createdAt: DateTime.now(),
    );

    await docRef.set(template.toFirestore());
  }

  /// استدعاء قوالب المستخدم
  Stream<List<TemplateModel>> getUserTemplatesStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return _firestore
        .collection('templates')
        .doc(uid)
        .collection('user_templates')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(TemplateModel.fromFirestore).toList());
  }

  /// حذف قالب
  Future<void> deleteTemplate(TemplateModel template) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // حذف من Firestore
    await _firestore
        .collection('templates')
        .doc(uid)
        .collection('user_templates')
        .doc(template.id)
        .delete();

    // حذف من Storage
    try {
      final ref = _storage.refFromURL(template.fileUrl);
      await ref.delete();
    } catch (_) {}
  }
}
