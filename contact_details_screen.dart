import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:integrated_accounting_system/core/utils/currency_utils.dart';
import 'package:integrated_accounting_system/domain/entities/contact.dart';
import 'package:integrated_accounting_system/presentation/providers/contacts_provider.dart';
import 'package:integrated_accounting_system/presentation/providers/transactions_provider.dart';
import 'package:integrated_accounting_system/presentation/providers/debts_provider.dart';
import 'package:integrated_accounting_system/presentation/screens/contacts/add_contact_screen.dart';

class ContactDetailsScreen extends ConsumerStatefulWidget {
  final Contact contact;

  const ContactDetailsScreen({
    super.key,
    required this.contact,
  });

  @override
  ConsumerState<ContactDetailsScreen> createState() => _ContactDetailsScreenState();
}

class _ContactDetailsScreenState extends ConsumerState<ContactDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final contactId = widget.contact.id;
    ref.read(transactionsProvider.notifier).loadTransactions();
    ref.read(debtsProvider.notifier).loadDebts();
  }

  @override
  Widget build(BuildContext context) {
    final contact = widget.contact;
    final transactionsState = ref.watch(transactionsProvider);
    final debtsState = ref.watch(debtsProvider);
    final isRTL = Directionality.of(context) == TextDirection.rtl;

    // تصفية المعاملات والديون الخاصة بهذا العميل
    final contactTransactions = transactionsState.transactions
        .where((t) => t.contactId == contact.id)
        .toList();
    final contactDebts = debtsState.debts
        .where((d) => d.contactId == contact.id)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(contact.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _navigateToEdit(),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareContact,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // بطاقة المعلومات الشخصية
            _buildProfileCard(contact),
            const SizedBox(height: 16),

            // إحصائيات سريعة
            _buildQuickStats(contactTransactions, contactDebts),
            const SizedBox(height: 16),

            // أزرار الاتصال السريع
            _buildContactActions(contact),
            const SizedBox(height: 16),

            // آخر المعاملات
            _buildRecentTransactions(contactTransactions),
            const SizedBox(height: 16),

            // الديون
            _buildDebts(contactDebts),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(Contact contact) {
    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // الصورة والاسم
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: contact.type == ContactType.customer
                      ? Colors.blue.shade100
                      : Colors.orange.shade100,
                  backgroundImage: contact.imagePath != null
                      ? FileImage(File(contact.imagePath!))
                      : null,
                  child: contact.imagePath == null
                      ? Text(
                          contact.name[0],
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: contact.type == ContactType.customer
                                ? Colors.blue.shade700
                                : Colors.orange.shade700,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: contact.type == ContactType.customer
                              ? Colors.blue.shade100
                              : Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          contact.type == ContactType.customer ? 'عميل' : 'مورد',
                          style: TextStyle(
                            fontSize: 12,
                            color: contact.type == ContactType.customer
                                ? Colors.blue.shade700
                                : Colors.orange.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // تفاصيل الاتصال
            if (contact.phone != null)
              _buildDetailRow(Icons.phone, 'الهاتف', contact.phone!),
            if (contact.whatsapp != null)
              _buildDetailRow(Icons.whatsapp, 'واتساب', contact.whatsapp!),
            if (contact.email != null)
              _buildDetailRow(Icons.email, 'البريد الإلكتروني', contact.email!),
            if (contact.address != null)
              _buildDetailRow(Icons.location_on, 'العنوان', contact.address!),
            if (contact.notes != null)
              _buildDetailRow(Icons.note, 'ملاحظات', contact.notes!),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(List<Transaction> transactions, List<Debt> debts) {
    final totalReceipt = transactions
        .where((t) => t.type == TransactionType.receipt)
        .fold(0.0, (sum, t) => sum + t.amount);
    final totalPayment = transactions
        .where((t) => t.type == TransactionType.payment)
        .fold(0.0, (sum, t) => sum + t.amount);
    final totalDebts = debts.fold(0.0, (sum, d) => sum + d.remainingAmount);

    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('إجمالي القبض', totalReceipt, Colors.green),
            _buildStatItem('إجمالي الصرف', totalPayment, Colors.red),
            _buildStatItem('الديون المتبقية', totalDebts, Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, double value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          CurrencyUtils.formatAmount(value),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildContactActions(Contact contact) {
    return Row(
      children: [
        if (contact.phone != null) ...[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _makePhoneCall(contact.phone!),
              icon: const Icon(Icons.phone),
              label: const Text('اتصال'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _openWhatsApp(contact.phone!),
              icon: const Icon(Icons.whatsapp),
              label: const Text('واتساب'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                foregroundColor: Colors.green,
              ),
            ),
          ),
        ],
        if (contact.email != null) ...[
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _sendEmail(contact.email!),
              icon: const Icon(Icons.email),
              label: const Text('بريد'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                foregroundColor: Colors.blue,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRecentTransactions(List<Transaction> transactions) {
    final recent = transactions.take(5).toList();

    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'آخر المعاملات',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (transactions.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      // الانتقال إلى جميع المعاملات
                    },
                    child: const Text('عرض الكل'),
                  ),
              ],
            ),
            if (recent.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text('لا توجد معاملات'),
                ),
              )
            else
              ...recent.map((transaction) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: transaction.typeColor.withOpacity(0.2),
                    child: Icon(
                      transaction.typeIcon,
                      color: transaction.typeColor,
                      size: 18,
                    ),
                  ),
                  title: Text(
                    transaction.description ?? transaction.typeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${transaction.date.year}/${transaction.date.month}/${transaction.date.day}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Text(
                    CurrencyUtils.formatAmount(transaction.amount),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: transaction.typeColor,
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildDebts(List<Debt> debts) {
    if (debts.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'الديون',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...debts.map((debt) {
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: debt.statusColor.withOpacity(0.2),
                  child: Icon(
                    debt.statusIcon,
                    color: debt.statusColor,
                    size: 18,
                  ),
                ),
                title: Text(
                  '${CurrencyUtils.formatAmount(debt.totalAmount)}',
                ),
                subtitle: Text(
                  'المتبقي: ${CurrencyUtils.formatAmount(debt.remainingAmount)}',
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: debt.statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        debt.statusName,
                        style: TextStyle(
                          fontSize: 11,
                          color: debt.statusColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${debt.dueDate.year}/${debt.dueDate.month}/${debt.dueDate.day}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _makePhoneCall(String phoneNumber) async {
    final url = 'tel:$phoneNumber';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  void _openWhatsApp(String phoneNumber) async {
    final url = 'https://wa.me/$phoneNumber';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  void _sendEmail(String email) async {
    final url = 'mailto:$email';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  void _shareContact() async {
    final contact = widget.contact;
    final shareText = '''
جهة اتصال
الاسم: ${contact.name}
النوع: ${contact.typeName}
${contact.phone != null ? 'الهاتف: ${contact.phone}' : ''}
${contact.whatsapp != null ? 'واتساب: ${contact.whatsapp}' : ''}
${contact.email != null ? 'البريد الإلكتروني: ${contact.email}' : ''}
${contact.address != null ? 'العنوان: ${contact.address}' : ''}
    ''';

    await Share.share(shareText);
  }

  void _navigateToEdit() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddContactScreen(contact: widget.contact),
      ),
    ).then((result) {
      if (result == true) {
        ref.read(contactsProvider.notifier).loadContacts();
        setState(() {});
      }
    });
  }
}