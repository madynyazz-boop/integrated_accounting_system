import 'package:integrated_accounting_system/domain/repositories/contact_repository.dart';

class DeleteContactUseCase {
  final ContactRepository repository;

  DeleteContactUseCase(this.repository);

  Future<void> execute(String id) async {
    // التحقق من صحة المعرف
    if (id.isEmpty) {
      throw Exception('معرف جهة الاتصال مطلوب');
    }
    
    await repository.deleteContact(id);
  }
}