import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:integrated_accounting_system/core/enums/enums.dart';
import 'package:integrated_accounting_system/data/repositories/contact_repository_impl.dart';
import 'package:integrated_accounting_system/data/datasources/local_database.dart';
import 'package:integrated_accounting_system/domain/entities/contact.dart';
import 'package:integrated_accounting_system/domain/usecases/contacts/get_contacts.dart';
import 'package:integrated_accounting_system/domain/usecases/contacts/create_contact.dart';
import 'package:integrated_accounting_system/domain/usecases/contacts/update_contact.dart';
import 'package:integrated_accounting_system/domain/usecases/contacts/delete_contact.dart';

// مزود قاعدة البيانات المحلية
final localDatabaseProvider = Provider<LocalDatabase>((ref) {
  return LocalDatabase();
});

// مزود المستودع
final contactRepositoryProvider = Provider<ContactRepositoryImpl>((ref) {
  final localDatabase = ref.watch(localDatabaseProvider);
  return ContactRepositoryImpl(localDatabase);
});

// مزود حالات الاستخدام
final getContactsUseCaseProvider = Provider<GetContactsUseCase>((ref) {
  final repository = ref.watch(contactRepositoryProvider);
  return GetContactsUseCase(repository);
});

final createContactUseCaseProvider = Provider<CreateContactUseCase>((ref) {
  final repository = ref.watch(contactRepositoryProvider);
  return CreateContactUseCase(repository);
});

final updateContactUseCaseProvider = Provider<UpdateContactUseCase>((ref) {
  final repository = ref.watch(contactRepositoryProvider);
  return UpdateContactUseCase(repository);
});

final deleteContactUseCaseProvider = Provider<DeleteContactUseCase>((ref) {
  final repository = ref.watch(contactRepositoryProvider);
  return DeleteContactUseCase(repository);
});

// حالة جهات الاتصال
class ContactsState {
  final List<Contact> contacts;
  final bool isLoading;
  final String? error;
  final ContactType? selectedType;
  final String searchQuery;

  ContactsState({
    this.contacts = const [],
    this.isLoading = false,
    this.error,
    this.selectedType,
    this.searchQuery = '',
  });

  ContactsState copyWith({
    List<Contact>? contacts,
    bool? isLoading,
    String? error,
    ContactType? selectedType,
    String? searchQuery,
  }) {
    return ContactsState(
      contacts: contacts ?? this.contacts,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedType: selectedType ?? this.selectedType,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  // الحصول على العملاء فقط
  List<Contact> get customers => contacts.where((c) => c.type == ContactType.customer).toList();
  
  // الحصول على الموردين فقط
  List<Contact> get suppliers => contacts.where((c) => c.type == ContactType.supplier).toList();
}

// Notifier لجهات الاتصال
class ContactsNotifier extends StateNotifier<ContactsState> {
  final GetContactsUseCase _getContactsUseCase;
  final CreateContactUseCase _createContactUseCase;
  final UpdateContactUseCase _updateContactUseCase;
  final DeleteContactUseCase _deleteContactUseCase;

  ContactsNotifier(
    this._getContactsUseCase,
    this._createContactUseCase,
    this._updateContactUseCase,
    this._deleteContactUseCase,
  ) : super(ContactsState());

  // تحميل جهات الاتصال
  Future<void> loadContacts() async {
    state = state.copyWith(isLoading: true);
    try {
      final contacts = await _getContactsUseCase.execute(
        type: state.selectedType,
      );
      state = state.copyWith(
        contacts: contacts,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // إنشاء جهة اتصال جديدة
  Future<bool> createContact({
    required ContactType type,
    required String name,
    String? phone,
    String? whatsapp,
    String? email,
    String? address,
    String? imagePath,
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final contact = await _createContactUseCase.execute(
        type: type,
        name: name,
        phone: phone,
        whatsapp: whatsapp,
        email: email,
        address: address,
        imagePath: imagePath,
        notes: notes,
      );
      state = state.copyWith(
        contacts: [...state.contacts, contact],
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  // تحديث جهة اتصال
  Future<bool> updateContact(Contact contact) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updated = await _updateContactUseCase.execute(contact);
      final index = state.contacts.indexWhere((c) => c.id == contact.id);
      if (index != -1) {
        final newList = List<Contact>.from(state.contacts);
        newList[index] = updated;
        state = state.copyWith(contacts: newList, isLoading: false);
      }
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  // حذف جهة اتصال
  Future<bool> deleteContact(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _deleteContactUseCase.execute(id);
      state = state.copyWith(
        contacts: state.contacts.where((c) => c.id != id).toList(),
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  // تصفية حسب النوع
  void filterByType(ContactType? type) {
    state = state.copyWith(selectedType: type);
    loadContacts();
  }

  // البحث
  void searchContacts(String query) {
    state = state.copyWith(searchQuery: query);
    if (query.isEmpty) {
      loadContacts();
    } else {
      final filtered = state.contacts.where((c) {
        final name = c.name.toLowerCase();
        final phone = c.phone?.toLowerCase() ?? '';
        return name.contains(query.toLowerCase()) || phone.contains(query.toLowerCase());
      }).toList();
      state = state.copyWith(contacts: filtered);
    }
  }

  // مسح الخطأ
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// مزود حالة جهات الاتصال
final contactsProvider = StateNotifierProvider<ContactsNotifier, ContactsState>((ref) {
  final get = ref.watch(getContactsUseCaseProvider);
  final create = ref.watch(createContactUseCaseProvider);
  final update = ref.watch(updateContactUseCaseProvider);
  final delete = ref.watch(deleteContactUseCaseProvider);
  
  return ContactsNotifier(get, create, update, delete);
});