import 'package:integrated_accounting_system/domain/entities/user.dart';

abstract class AuthRepository {
  // تسجيل الدخول
  Future<User> signIn(String email, String password);
  
  // إنشاء حساب جديد
  Future<User> signUp(String email, String password, String name, {String? phone});
  
  // تسجيل الخروج
  Future<void> signOut();
  
  // إعادة تعيين كلمة المرور
  Future<void> resetPassword(String email);
  
  // الحصول على المستخدم الحالي
  Future<User?> getCurrentUser();
  
  // تحديث الملف الشخصي
  Future<void> updateProfile(User user);
  
  // التحقق من حالة المصادقة
  Future<bool> isAuthenticated();
}