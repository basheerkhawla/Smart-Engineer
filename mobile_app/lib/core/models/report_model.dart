// report_model.dart — نموذج التقرير الهندسي
import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  final String id;
  final String userId;
  final String? templateId;
  final String? projectId;
  final String? projectName;
  final String voiceText; // النص الخام من التسجيل الصوتي
  final String processedText; // النص بعد معالجة Gemini
  final String? fileUrl; // رابط التقرير المُصدَّر
  final String status; // 'draft' | 'processed' | 'exported'
  final bool isSynced; // هل تزامن مع السحابة؟
  final DateTime createdAt;

  ReportModel({
    required this.id,
    required this.userId,
    this.templateId,
    this.projectId,
    this.projectName,
    required this.voiceText,
    required this.processedText,
    this.fileUrl,
    this.status = 'draft',
    this.isSynced = false,
    required this.createdAt,
  });

  factory ReportModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReportModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      templateId: data['templateId'],
      projectId: data['projectId'],
      projectName: data['projectName'],
      voiceText: data['voiceText'] ?? '',
      processedText: data['processedText'] ?? '',
      fileUrl: data['fileUrl'],
      status: data['status'] ?? 'draft',
      isSynced: data['isSynced'] ?? true,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'templateId': templateId,
        'projectId': projectId,
        'projectName': projectName,
        'voiceText': voiceText,
        'processedText': processedText,
        'fileUrl': fileUrl,
        'status': status,
        'isSynced': isSynced,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  // نسخة محلية (Hive / local JSON)
  Map<String, dynamic> toLocalMap() => {
        'id': id,
        'userId': userId,
        'templateId': templateId,
        'projectId': projectId,
        'projectName': projectName,
        'voiceText': voiceText,
        'processedText': processedText,
        'status': status,
        'isSynced': false,
        'createdAt': createdAt.toIso8601String(),
      };
}
