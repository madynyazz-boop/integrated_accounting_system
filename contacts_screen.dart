import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:integrated_accounting_system/core/enums/enums.dart';
import 'package:integrated_accounting_system/core/widgets/empty_state_widget.dart';
import 'package:integrated_accounting_system/core/widgets/loading_widget.dart';
import 'package:integrated_accounting_system/domain/entities/contact.dart';
import 'package:integrated_accounting_system/presentation/providers/contacts_provider.dart';
import 'package:integrated_accounting_system/presentation/screens/contacts/add_contact_screen.dart';
import 'package:integrated_accounting_system/presentation/screens/contacts/contact_details_screen.dart';
import 'package:integrated_accounting_system/presentation/widgets/common/error_widget.dart';

class ContactsScreen extends ConsumerStatefulWidget {
  const ContactsScreen({super.key});

  @override
  ConsumerState<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends ConsumerState<ContactsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(contactsProvider.notifier).loadContacts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contactsState = ref.watch(contactsProvider);
    final contacts = contactsState.contacts;
    final isLoading = contactsState.isLoading;
    final error = contactsState.error;

    return Scaffold(
      appBar: AppBar(
        title: const Text('جهات الاتصال'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _buildFilterChips(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddContact(),
        child: const Icon(Icons.add),
      ),
      body: _buildBody(contactsState),
    );
  }

  Widget _buildBody(ContactsState state) {
    if (state.isLoading) {
      return const LoadingWidget();
    }

    if (state.error != null) {
      return ErrorWidgetComponent(
        message: state.error!,
        onRetry: () => ref.read(contactsProvider.notifier).loadContacts(),
      );
    }

    if (state.contacts.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.people_outline,
        title: 'لا توجد جهات اتصال',
        subtitle: 'قم بإضافة أول عميل أو مورد',
        buttonText: 'إضافة جهة اتصال',
        onPressed: () => _navigateToAddContact(),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: state.contacts.length,
      itemBuilder: (context, index) {
        final contact = state.contacts[index];
        return _buildContactCard(contact);
      },
    );
  }

  Widget _buildFilterChips() {
    final selectedType = ref.watch(contactsProvider).selectedType;

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildChip('الكل', null, selectedType == null),
          _buildChip('العملاء', ContactType.customer, selectedType == ContactType.customer),
          _buildChip('الموردين', ContactType.supplier, selectedType == ContactType.supplier),
        ],
      ),
    );
  }

  Widget _buildChip(String label, ContactType? type, bool selected) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {
          ref.read(contactsProvider.notifier).filterByType(type);
        },
        backgroundColor: Colors.grey[200],
        selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
        checkmarkColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildContactCard(Contact contact) {
    return Slidable(
      key: ValueKey(contact.id),
      endActionPane: ActionPane(
        motion: const StretchMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => _editContact(contact),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: 'تعديل',
          ),
          SlidableAction(
            onPressed: (_) => _deleteContact(contact),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'حذف',
          ),
        ],
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: contact.type == ContactType.customer
                ? Colors.blue.shade100
                : Colors.orange.shade100,
            child: contact.imagePath != null
                ? ClipOval(
                    child: Image.network(
                      contact.imagePath!,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    ),
                  )
                : Text(
                    contact.name.isNotEmpty ? contact.name[0] : '?',
                    style: TextStyle(
                      color: contact.type == ContactType.customer
                          ? Colors.blue.shade700
                          : Colors.orange.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
          ),
          title: Text(
            contact.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (contact.phone != null)
                Text('📱 ${contact.phone}'),
              if (contact.email != null)
                Text('📧 ${contact.email}'),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: contact.type == ContactType.customer
                      ? Colors.blue.shade100
                      : Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  contact.type == ContactType.customer ? 'عميل' : 'مورد',
                  style: TextStyle(
                    fontSize: 11,
                    color: contact.type == ContactType.customer
                        ? Colors.blue.shade700
                        : Colors.orange.shade700,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Colors.grey[400],
              ),
            ],
          ),
          onTap: () => _navigateToDetails(contact),
        ),
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('بحث عن جهة اتصال'),
        content: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'ابحث بالاسم أو رقم الهاتف...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onChanged: (value) {
            ref.read(contactsProvider.notifier).searchContacts(value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              _searchController.clear();
              ref.read(contactsProvider.notifier).searchContacts('');
              Navigator.pop(context);
            },
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    final selectedType = ref.read(contactsProvider).selectedType;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تصفية جهات الاتصال'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('الكل'),
              leading: Radio<ContactType?>(
                value: null,
                groupValue: selectedType,
                onChanged: (value) {
                  ref.read(contactsProvider.notifier).filterByType(value);
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: const Text('العملاء'),
              leading: Radio<ContactType?>(
                value: ContactType.customer,
                groupValue: selectedType,
                onChanged: (value) {
                  ref.read(contactsProvider.notifier).filterByType(value);
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: const Text('الموردين'),
              leading: Radio<ContactType?>(
                value: ContactType.supplier,
                groupValue: selectedType,
                onChanged: (value) {
                  ref.read(contactsProvider.notifier).filterByType(value);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToAddContact() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddContactScreen(),
      ),
    ).then((result) {
      if (result == true) {
        ref.read(contactsProvider.notifier).loadContacts();
      }
    });
  }

  void _navigateToDetails(Contact contact) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContactDetailsScreen(contact: contact),
      ),
    );
  }

  void _editContact(Contact contact) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddContactScreen(contact: contact),
      ),
    ).then((result) {
      if (result == true) {
        ref.read(contactsProvider.notifier).loadContacts();
      }
    });
  }

  void _deleteContact(Contact contact) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف جهة اتصال'),
        content: Text('هل أنت متأكد من حذف "${contact.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref.read(contactsProvider.notifier)
                  .deleteContact(contact.id);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم حذف جهة الاتصال بنجاح'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}