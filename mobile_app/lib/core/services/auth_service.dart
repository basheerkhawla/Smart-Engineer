// auth_service.dart — خدمة المصادقة عبر Firebase
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../constants/app_constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // الحصول على المستخدم الحالي
  User? get currentUser => _auth.currentUser;

  // Stream للاستماع لتغييرات حالة المصادقة
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ===== تسجيل حساب جديد =====
  Future<UserModel> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
    required bool privacyAccepted,
    required bool locationConsentAccepted,
    required bool aiConsentAccepted,
  }) async {
    // التسجيل عبر Firebase Auth
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user!;

    // تحديث الاسم
    await user.updateDisplayName(displayName);

    // إرسال رسالة تحقق الإيميل
    await user.sendEmailVerification();

    // إنشاء سجل المستخدم في Firestore
    final userModel = UserModel(
      uid: user.uid,
      email: email,
      displayName: displayName,
      role: 'user',
      plan: 'free',
      isBlocked: false,
      isAdFree: false,
      isEmailVerified: false,
      reportsUsed: 0,
      maxReports: AppConstants.freeMonthlyReports,
      privacyAccepted: privacyAccepted,
      locationConsentAccepted: locationConsentAccepted,
      aiConsentAccepted: aiConsentAccepted,
      createdAt: DateTime.now(),
      lastLogin: DateTime.now(),
    );

    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .set(userModel.toFirestore());

    return userModel;
  }

  // ===== تسجيل الدخول =====
  Future<UserModel> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user!;

    // التحقق من أن الحساب غير محظور
    final userDoc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .get();

    if (!userDoc.exists) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'لم يتم العثور على بيانات المستخدم',
      );
    }

    final userModel = UserModel.fromFirestore(userDoc);

    if (userModel.isBlocked) {
      await _auth.signOut();
      throw FirebaseAuthException(
        code: 'user-disabled',
        message: 'تم تعليق حسابك. يرجى التواصل مع الدعم الفني.',
      );
    }

    // تحديث آخر تاريخ دخول
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .update({'lastLogin': Timestamp.now()});

    return userModel;
  }

  // ===== إعادة إرسال رسالة التحقق =====
  Future<void> resendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  // ===== التحقق من تأكيد الإيميل =====
  Future<bool> checkEmailVerified() async {
    await _auth.currentUser?.reload();
    final isVerified = _auth.currentUser?.emailVerified ?? false;

    if (isVerified) {
      // تحديث Firestore
      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(uid)
            .update({'isEmailVerified': true});
      }
    }

    return isVerified;
  }

  // ===== إعادة تعيين كلمة المرور =====
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // ===== تسجيل الخروج =====
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ===== الحصول على بيانات المستخدم من Firestore =====
  Future<UserModel?> getUserData(String uid) async {
    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .get();

    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  // Stream للاستماع لتغييرات بيانات المستخدم مباشرة
  Stream<UserModel?> userDataStream(String uid) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
  }
}
