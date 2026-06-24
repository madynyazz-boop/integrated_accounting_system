import 'package:integrated_accounting_system/core/enums/enums.dart';
import 'package:integrated_accounting_system/domain/entities/contact.dart';

abstract class ContactRepository {
  // جلب جميع جهات الاتصال
  Future<List<Contact>> getContacts({ContactType? type});
  
  // إنشاء جهة اتصال جديدة
  Future<Contact> createContact(Contact contact);
  
  // تحديث جهة اتصال
  Future<Contact> updateContact(Contact contact);
  
  // حذف جهة اتصال
  Future<void> deleteContact(String id);
  
  // جلب جهة اتصال بواسطة المعرف
  Future<Contact?> getContactById(String id);
  
  // البحث عن جهات الاتصال
  Future<List<Contact>> searchContacts(String query);
  
  // عدد جهات الاتصال
  Future<int> getContactsCount({ContactType? type});
}