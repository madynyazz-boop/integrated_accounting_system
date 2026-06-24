import 'package:integrated_accounting_system/domain/entities/user.dart';
import 'package:integrated_accounting_system/domain/repositories/auth_repository.dart';

class SignUpUseCase {
  final AuthRepository repository;

  SignUpUseCase(this.repository);

  Future<User> execute({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
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
    
    // التحقق من صحة الاسم
    if (name.isEmpty) {
      throw Exception('الاسم مطلوب');
    }
    
    if (name.length < 3) {
      throw Exception('الاسم يجب أن يكون 3 أحرف على الأقل');
    }

    // تنفيذ عملية إنشاء الحساب
    return await repository.signUp(email, password, name, phone: phone);
  }
}