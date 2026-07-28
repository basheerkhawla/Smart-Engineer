// admin_service.dart — خدمة لوحة التحكم الإدارية
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../constants/app_constants.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ===== إحصائيات عامة =====
  Future<Map<String, dynamic>> getDashboardStats() async {
    final usersSnap =
        await _firestore.collection(AppConstants.usersCollection).get();

    final users = usersSnap.docs.map(UserModel.fromFirestore).toList();

    final totalUsers = users.length;
    final activeUsers = users.where((u) => !u.isBlocked).length;
    final blockedUsers = users.where((u) => u.isBlocked).length;
    final paidUsers =
        users.where((u) => u.hasActivePaidSubscription).length;
    final adFreeUsers = users.where((u) => u.isAdFree).length;

    // إجمالي التقارير
    int totalReports = 0;
    for (final user in users) {
      totalReports += user.reportsUsed;
    }

    // مستخدمون جدد هذا الشهر
    final thisMonth = DateTime.now();
    final newThisMonth = users.where((u) {
      return u.createdAt.year == thisMonth.year &&
          u.createdAt.month == thisMonth.month;
    }).length;

    return {
      'totalUsers': totalUsers,
      'activeUsers': activeUsers,
      'blockedUsers': blockedUsers,
      'paidUsers': paidUsers,
      'adFreeUsers': adFreeUsers,
      'totalReports': totalReports,
      'newUsersThisMonth': newThisMonth,
    };
  }

  // ===== قائمة المستخدمين =====
  Stream<List<UserModel>> getUsersStream({String? searchQuery}) {
    Query query = _firestore
        .collection(AppConstants.usersCollection)
        .orderBy('createdAt', descending: true)
        .limit(100);

    return query.snapshots().map((snap) {
      var users = snap.docs.map(UserModel.fromFirestore).toList();

      if (searchQuery != null && searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        users = users.where((u) {
          return u.displayName.toLowerCase().contains(q) ||
              u.email.toLowerCase().contains(q);
        }).toList();
      }

      return users;
    });
  }

  // ===== تحكم في المستخدم =====

  /// حظر / إلغاء حظر مستخدم
  Future<void> toggleBlockUser(String uid, bool block) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update({'isBlocked': block});
  }

  /// تفعيل / إلغاء وضع بدون إعلانات
  Future<void> toggleAdFree(String uid, bool adFree) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update({'isAdFree': adFree});
  }

  /// تعديل حد التقارير الشهرية
  Future<void> updateMaxReports(String uid, int maxReports) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update({'maxReports': maxReports});
  }

  /// تغيير خطة المستخدم
  Future<void> updatePlan(String uid, String plan) async {
    final updates = <String, dynamic>{'plan': plan};
    if (plan == 'free') {
      updates['isAdFree'] = false;
      updates['subscriptionExpiry'] = null;
    }
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update(updates);
  }

  /// حذف حساب مستخدم من Firestore (Firebase Auth يُحذف يدوياً أو عبر Cloud Function)
  Future<void> deleteUser(String uid) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .delete();
  }

  /// منح صلاحية الأدمن
  Future<void> makeAdmin(String uid) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update({'role': 'admin'});
  }

  /// إلغاء صلاحية الأدمن
  Future<void> revokeAdmin(String uid) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update({'role': 'user'});
  }

  // ===== الإشعارات العامة =====
  /// حفظ إشعار عام في Firestore (يقرأه كل المستخدمين)
  Future<void> sendGlobalNotification({
    required String title,
    required String body,
  }) async {
    await _firestore.collection(AppConstants.notificationsCollection).add({
      'title': title,
      'body': body,
      'sentAt': Timestamp.now(),
      'type': 'global',
    });
  }

  // ===== تفاصيل مستخدم واحد =====
  Future<UserModel?> getUserById(String uid) async {
    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }
}
