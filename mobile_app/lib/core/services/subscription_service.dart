// subscription_service.dart — خدمة الاشتراك الشهري ($5)
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/app_constants.dart';

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<ProductDetails> _products = [];
  List<ProductDetails> get products => _products;

  /// تهيئة خدمة الشراء داخل التطبيق
  Future<bool> initialize() async {
    final available = await _iap.isAvailable();
    if (!available) {
      debugPrint('In-App Purchase غير متاح');
      return false;
    }

    // تحميل منتجات الاشتراك
    const ids = {AppConstants.subscriptionProductId};
    final response = await _iap.queryProductDetails(ids);

    if (response.error != null) {
      debugPrint('خطأ في تحميل المنتجات: ${response.error}');
      return false;
    }

    _products = response.productDetails;
    return true;
  }

  /// بدء عملية الشراء
  Future<void> buySubscription() async {
    if (_products.isEmpty) {
      await initialize();
    }

    if (_products.isEmpty) {
      throw Exception('لم يتم العثور على المنتج في Google Play');
    }

    final product = _products.first;
    final purchaseParam = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  /// معالجة عملية شراء ناجحة
  Future<void> handleSuccessfulPurchase(PurchaseDetails purchase) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // تحديد تاريخ انتهاء الاشتراك (شهر من الآن)
    final expiryDate = DateTime.now().add(const Duration(days: 30));

    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update({
      'plan': 'paid',
      'isAdFree': true,
      'subscriptionExpiry': Timestamp.fromDate(expiryDate),
      'subscriptionPurchaseToken': purchase.purchaseID,
      'lastSubscriptionDate': Timestamp.now(),
    });

    // إكمال عملية الشراء مع Google Play
    if (purchase.pendingCompletePurchase) {
      await _iap.completePurchase(purchase);
    }
  }

  /// إلغاء اشتراك (من لوحة التحكم الإدارية)
  Future<void> cancelSubscription(String uid) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update({
      'plan': 'free',
      'isAdFree': false,
      'subscriptionExpiry': null,
    });
  }

  /// تمديد اشتراك يدوياً (من لوحة التحكم)
  Future<void> extendSubscription(String uid, int days) async {
    final userDoc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .get();

    DateTime? currentExpiry;
    if (userDoc.data()?['subscriptionExpiry'] != null) {
      currentExpiry =
          (userDoc.data()!['subscriptionExpiry'] as Timestamp).toDate();
    }

    final base = (currentExpiry != null && currentExpiry.isAfter(DateTime.now()))
        ? currentExpiry
        : DateTime.now();

    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update({
      'plan': 'paid',
      'isAdFree': true,
      'subscriptionExpiry': Timestamp.fromDate(base.add(Duration(days: days))),
    });
  }
}
