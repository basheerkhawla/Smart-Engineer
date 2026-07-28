// template_model.dart — نموذج القالب الهندسي
import 'package:cloud_firestore/cloud_firestore.dart';

class TemplatePlaceholder {
  final String key;
  final String label;
  final String type; // 'text' | 'date' | 'number' | 'textarea'
  String value; // القيمة المُعبَّأة

  TemplatePlaceholder({
    required this.key,
    required this.label,
    required this.type,
    this.value = '',
  });

  factory TemplatePlaceholder.fromMap(Map<String, dynamic> map) {
    return TemplatePlaceholder(
      key: map['key'] ?? '',
      label: map['label'] ?? '',
      type: map['type'] ?? 'text',
      value: map['value'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'key': key,
        'label': label,
        'type': type,
        'value': value,
      };
}

class TemplateModel {
  final String id;
  final String userId;
  final String name;
  final String type; // 'daily_report' | 'letter' | 'custom'
  final String fileUrl;
  final String fileName;
  final String fileExtension; // 'docx' | 'xlsx'
  final List<TemplatePlaceholder> placeholders;
  final DateTime createdAt;

  TemplateModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.fileUrl,
    required this.fileName,
    required this.fileExtension,
    required this.placeholders,
    required this.createdAt,
  });

  factory TemplateModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TemplateModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      type: data['type'] ?? 'custom',
      fileUrl: data['fileUrl'] ?? '',
      fileName: data['fileName'] ?? '',
      fileExtension: data['fileExtension'] ?? 'docx',
      placeholders: (data['placeholders'] as List<dynamic>? ?? [])
          .map((p) => TemplatePlaceholder.fromMap(p as Map<String, dynamic>))
          .toList(),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'name': name,
        'type': type,
        'fileUrl': fileUrl,
        'fileName': fileName,
        'fileExtension': fileExtension,
        'placeholders': placeholders.map((p) => p.toMap()).toList(),
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
