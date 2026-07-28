// project_model.dart — نموذج بيانات المشروع الهندسي
import 'package:cloud_firestore/cloud_firestore.dart';

class ProjectModel {
  final String id;
  final String userId;
  final String name;
  final String? location;
  final String? companyName;
  final String? companyLogoUrl;
  final String? engineerName;
  final bool isActive;
  final DateTime createdAt;

  ProjectModel({
    required this.id,
    required this.userId,
    required this.name,
    this.location,
    this.companyName,
    this.companyLogoUrl,
    this.engineerName,
    this.isActive = true,
    required this.createdAt,
  });

  factory ProjectModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProjectModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      location: data['location'],
      companyName: data['companyName'],
      companyLogoUrl: data['companyLogoUrl'],
      engineerName: data['engineerName'],
      isActive: data['isActive'] ?? true,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'location': location,
      'companyName': companyName,
      'companyLogoUrl': companyLogoUrl,
      'engineerName': engineerName,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
