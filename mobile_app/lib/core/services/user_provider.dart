// user_provider.dart — إدارة حالة المستخدم
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class UserProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  bool get isAdmin => _user?.role == 'admin';
  bool get shouldShowAds => _user?.shouldShowAds ?? true;
  bool get canCreateReport => _user?.canCreateReport ?? false;

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  // تحميل بيانات المستخدم من Firebase
  Future<void> loadUser(User firebaseUser) async {
    _setLoading(true);
    try {
      final userData = await _authService.getUserData(firebaseUser.uid);
      _user = userData;
      _error = null;

      // الاستماع للتغييرات في الوقت الفعلي (مهم للحظر والاشتراك)
      _authService.userDataStream(firebaseUser.uid).listen((updatedUser) {
        _user = updatedUser;
        notifyListeners();
      });
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  void clearUser() {
    _user = null;
    notifyListeners();
  }

  void updateUser(UserModel updated) {
    _user = updated;
    notifyListeners();
  }
}
