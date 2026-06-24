import 'package:integrated_accounting_system/domain/entities/user.dart';
import 'package:integrated_accounting_system/domain/repositories/auth_repository.dart';

class SignInUseCase {
  final AuthRepository repository;

  SignInUseCase(this.repository);

  Future<User> execute(String email, String password) async {
    // التحقق من صحة البريد الإلكتروني
    if (email.isEmpty) {
      throw Exception('البريد الإلكتروني مطلوب');
    }
    
    // التحقق من صحة كلمة المرور
    if (password.isEmpty) {
      throw Exception('كلمة المرور مطلوبة');
    }
    
    if (password.length < 6) {
      throw Exception('كلمة المرور يجب أن تكون 6 أحرف على الأقل');
    }

    // تنفيذ عملية تسجيل الدخول
    return await repository.signIn(email, password);
  }
}