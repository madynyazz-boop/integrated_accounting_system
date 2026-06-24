import 'package:integrated_accounting_system/data/datasources/firebase_datasource.dart';
import 'package:integrated_accounting_system/data/models/user_model.dart';
import 'package:integrated_accounting_system/domain/entities/user.dart';
import 'package:integrated_accounting_system/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseDataSource _firebaseDataSource;

  AuthRepositoryImpl(this._firebaseDataSource);

  @override
  Future<User> signIn(String email, String password) async {
    try {
      final credential = await _firebaseDataSource.signInWithEmail(email, password);
      final user = credential.user!;
      
      // جلب بيانات المستخدم من Firestore
      final userData = await _firebaseDataSource.getUserData();
      final data = userData.data() as Map<String, dynamic>;
      
      return UserModel(
        id: user.uid,
        email: user.email ?? '',
        name: user.displayName ?? data['name'] ?? '',
        phone: data['phone'],
        imagePath: user.photoURL ?? data['imagePath'],
        createdAt: DateTime.parse(data['createdAt'] ?? DateTime.now().toIso8601String()),
      );
    } catch (e) {
      throw Exception('فشل تسجيل الدخول: $e');
    }
  }

  @override
  Future<User> signUp(String email, String password, String name, {String? phone}) async {
    try {
      final credential = await _firebaseDataSource.signUpWithEmail(email, password);
      final user = credential.user!;
      
      // تحديث الملف الشخصي
      await _firebaseDataSource.updateProfile(displayName: name);
      
      // حفظ بيانات المستخدم
      final userData = {
        'name': name,
        'email': email,
        'phone': phone,
        'createdAt': DateTime.now().toIso8601String(),
      };
      await _firebaseDataSource.saveUserData(userData);
      
      return UserModel(
        id: user.uid,
        email: email,
        name: name,
        phone: phone,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      throw Exception('فشل إنشاء الحساب: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _firebaseDataSource.signOut();
    } catch (e) {
      throw Exception('فشل تسجيل الخروج: $e');
    }
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await _firebaseDataSource.resetPassword(email);
    } catch (e) {
      throw Exception('فشل إعادة تعيين كلمة المرور: $e');
    }
  }

  @override
  Future<User?> getCurrentUser() async {
    try {
      final firebaseUser = _firebaseDataSource.currentUser;
      if (firebaseUser == null) return null;
      
      final userData = await _firebaseDataSource.getUserData();
      final data = userData.data() as Map<String, dynamic>;
      
      return UserModel(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        name: firebaseUser.displayName ?? data['name'] ?? '',
        phone: data['phone'],
        imagePath: firebaseUser.photoURL ?? data['imagePath'],
        createdAt: DateTime.parse(data['createdAt'] ?? DateTime.now().toIso8601String()),
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> updateProfile(User user) async {
    try {
      await _firebaseDataSource.updateProfile(
        displayName: user.name,
      );
      
      await _firebaseDataSource.saveUserData({
        'name': user.name,
        'phone': user.phone,
        'imagePath': user.imagePath,
      });
    } catch (e) {
      throw Exception('فشل تحديث الملف الشخصي: $e');
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    return _firebaseDataSource.currentUser != null;
  }
}