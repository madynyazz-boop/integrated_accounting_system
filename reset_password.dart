import 'package:integrated_accounting_system/domain/repositories/auth_repository.dart';

class ResetPasswordUseCase {
  final AuthRepository repository;

  ResetPasswordUseCase(this.repository);

  Future<void> execute(String email) async {
    // التحقق من صحة البريد الإلكتروني
    if (email.isEmpty) {
      throw Exception('البريد الإلكتروني مطلوب');
    }
    
    // تنفيذ عملية إعادة تعيين كلمة المرور
    await repository.resetPassword(email);
  }
}