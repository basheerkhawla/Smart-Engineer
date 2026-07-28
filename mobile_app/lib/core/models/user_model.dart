// user_model.dart — نموذج بيانات المستخدم
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoURL;
  final String role; // 'user' | 'admin'
  final String plan; // 'free' | 'paid'
  final bool isBlocked;
  final bool isAdFree;
  final bool isEmailVerified;
  final int reportsUsed;
  final int maxReports;
  final bool privacyAccepted;
  final bool locationConsentAccepted;
  final bool aiConsentAccepted;
  final DateTime? subscriptionExpiry;
  final DateTime createdAt;
  final DateTime? lastLogin;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoURL,
    this.role = 'user',
    this.plan = 'free',
    this.isBlocked = false,
    this.isAdFree = false,
    this.isEmailVerified = false,
    this.reportsUsed = 0,
    this.maxReports = 5,
    this.privacyAccepted = false,
    this.locationConsentAccepted = false,
    this.aiConsentAccepted = false,
    this.subscriptionExpiry,
    required this.createdAt,
    this.lastLogin,
  });

  // هل المستخدم مشترك نشط؟
  bool get hasActivePaidSubscription {
    if (plan != 'paid') return false;
    if (subscriptionExpiry == null) return false;
    return subscriptionExpiry!.isAfter(DateTime.now());
  }

  // هل يجب إظهار الإعلانات؟
  bool get shouldShowAds {
    return !isAdFree && !hasActivePaidSubscription;
  }

  // هل يمكن إنشاء تقرير جديد؟
  bool get canCreateReport {
    if (hasActivePaidSubscription) return true;
    return reportsUsed < maxReports;
  }

  // نسبة استهلاك الخطة المجانية
  double get usagePercentage {
    if (maxReports == 0) return 0;
    return reportsUsed / maxReports;
  }

  // تحويل من Firestore
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      photoURL: data['photoURL'],
      role: data['role'] ?? 'user',
      plan: data['plan'] ?? 'free',
      isBlocked: data['isBlocked'] ?? false,
      isAdFree: data['isAdFree'] ?? false,
      isEmailVerified: data['isEmailVerified'] ?? false,
      reportsUsed: data['reportsUsed'] ?? 0,
      maxReports: data['maxReports'] ?? 5,
      privacyAccepted: data['privacyAccepted'] ?? false,
      locationConsentAccepted: data['locationConsentAccepted'] ?? false,
      aiConsentAccepted: data['aiConsentAccepted'] ?? false,
      subscriptionExpiry: data['subscriptionExpiry'] != null
          ? (data['subscriptionExpiry'] as Timestamp).toDate()
          : null,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      lastLogin: data['lastLogin'] != null
          ? (data['lastLogin'] as Timestamp).toDate()
          : null,
    );
  }

  // تحويل إلى Map لـ Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'role': role,
      'plan': plan,
      'isBlocked': isBlocked,
      'isAdFree': isAdFree,
      'isEmailVerified': isEmailVerified,
      'reportsUsed': reportsUsed,
      'maxReports': maxReports,
      'privacyAccepted': privacyAccepted,
      'locationConsentAccepted': locationConsentAccepted,
      'aiConsentAccepted': aiConsentAccepted,
      'subscriptionExpiry': subscriptionExpiry != null
          ? Timestamp.fromDate(subscriptionExpiry!)
          : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
    };
  }

  UserModel copyWith({
    String? displayName,
    String? photoURL,
    String? role,
    String? plan,
    bool? isBlocked,
    bool? isAdFree,
    bool? isEmailVerified,
    int? reportsUsed,
    int? maxReports,
    DateTime? subscriptionExpiry,
    DateTime? lastLogin,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      role: role ?? this.role,
      plan: plan ?? this.plan,
      isBlocked: isBlocked ?? this.isBlocked,
      isAdFree: isAdFree ?? this.isAdFree,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      reportsUsed: reportsUsed ?? this.reportsUsed,
      maxReports: maxReports ?? this.maxReports,
      privacyAccepted: privacyAccepted,
      locationConsentAccepted: locationConsentAccepted,
      aiConsentAccepted: aiConsentAccepted,
      subscriptionExpiry: subscriptionExpiry ?? this.subscriptionExpiry,
      createdAt: createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
}
