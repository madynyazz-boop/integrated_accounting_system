import 'package:integrated_accounting_system/core/enums/enums.dart';
import 'package:integrated_accounting_system/domain/entities/contact.dart';
import 'package:integrated_accounting_system/domain/repositories/contact_repository.dart';

class CreateContactUseCase {
  final ContactRepository repository;

  CreateContactUseCase(this.repository);

  Future<Contact> execute({
    required ContactType type,
    required String name,
    String? phone,
    String? whatsapp,
    String? email,
    String? address,
    String? imagePath,
    String? notes,
  }) async {
    // التحقق من صحة الاسم
    if (name.isEmpty) {
      throw Exception('الاسم مطلوب');
    }
    
    if (name.length < 2) {
      throw Exception('الاسم يجب أن يكون حرفين على الأقل');
    }

    // إنشاء كائن Contact
    final contact = Contact(
      id: '', // سيتم إنشاؤه في المستودع
      type: type,
      name: name,
      phone: phone,
      whatsapp: whatsapp,
      email: email,
      address: address,
      imagePath: imagePath,
      notes: notes,
      createdAt: DateTime.now(),
    );

    return await repository.createContact(contact);
  }
}