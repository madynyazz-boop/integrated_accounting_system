import 'package:integrated_accounting_system/domain/entities/contact.dart';
import 'package:integrated_accounting_system/domain/repositories/contact_repository.dart';

class UpdateContactUseCase {
  final ContactRepository repository;

  UpdateContactUseCase(this.repository);

  Future<Contact> execute(Contact contact) async {
    // التحقق من صحة المعرف
    if (contact.id.isEmpty) {
      throw Exception('معرف جهة الاتصال مطلوب');
    }
    
    // التحقق من صحة الاسم
    if (contact.name.isEmpty) {
      throw Exception('الاسم مطلوب');
    }

    return await repository.updateContact(contact);
  }
}