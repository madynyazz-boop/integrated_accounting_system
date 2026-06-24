import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:integrated_accounting_system/core/utils/currency_utils.dart';
import 'package:integrated_accounting_system/domain/entities/transaction.dart';
import 'package:integrated_accounting_system/presentation/providers/contacts_provider.dart';
import 'package:integrated_accounting_system/presentation/screens/transactions/add_transaction_screen.dart';

class TransactionDetailsScreen extends ConsumerStatefulWidget {
  final Transaction transaction;

  const TransactionDetailsScreen({
    super.key,
    required this.transaction,
  });

  @override
  ConsumerState<TransactionDetailsScreen> createState() => _TransactionDetailsScreenState();
}

class _TransactionDetailsScreenState extends ConsumerState<TransactionDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final transaction = widget.transaction;
    final contactsState = ref.watch(contactsProvider);
    final contact = contactsState.contacts.firstWhere(
      (c) => c.id == transaction.contactId,
      orElse: () => throw Exception('Contact not found'),
    );
    final isRTL = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل العملية'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddTransactionScreen(
                    transaction: transaction,
                  ),
                ),
              ).then((result) {
                if (result == true) {
                  Navigator.pop(context, true);
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareTransaction,
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _printTransaction,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // بطاقة العملية الرئيسية
            _buildMainCard(transaction),
            const SizedBox(height: 16),

            // معلومات العميل
            if (contact != null)
              _buildContactCard(contact),
            const SizedBox(height: 16),

            // أزرار إضافية
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainCard(Transaction transaction) {
    final color = transaction.typeColor;

    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.1),
              Colors.white,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            // أيقونة ونوع العملية
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    transaction.typeIcon,
                    color: color,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.typeName,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      Text(
                        DateFormat('yyyy/MM/dd HH:mm').format(transaction.date),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  CurrencyUtils.formatAmount(transaction.amount),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // تفاصيل العملية
            _buildDetailItem('المبلغ', CurrencyUtils.formatAmount(transaction.amount)),
            _buildDetailItem('العملة', transaction.currency),
            _buildDetailItem('النوع', transaction.typeName),
            if (transaction.description != null)
              _buildDetailItem('الوصف', transaction.description!, isMultiLine: true),
            _buildDetailItem('التاريخ', DateFormat('yyyy/MM/dd').format(transaction.date)),
            _buildDetailItem('الوقت', DateFormat('HH:mm').format(transaction.date)),
            _buildDetailItem('رقم العملية', transaction.id.substring(0, 8)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, {bool isMultiLine = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
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

  Widget _buildContactCard(Contact contact) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: contact.type == ContactType.customer
              ? Colors.blue.shade100
              : Colors.orange.shade100,
          child: Text(
            contact.name[0],
            style: TextStyle(
              color: contact.type == ContactType.customer
                  ? Colors.blue.shade700
                  : Colors.orange.shade700,
              fontWeight: FontWeight.bold,
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
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (contact.phone != null) ...[
              IconButton(
                icon: const Icon(Icons.phone, color: Colors.green),
                onPressed: () => _makePhoneCall(contact.phone!),
              ),
              IconButton(
                icon: const Icon(Icons.whatsapp, color: Colors.green),
                onPressed: () => _openWhatsApp(contact.phone!),
              ),
            ],
          ],
        ),
        onTap: () {
          // الانتقال إلى تفاصيل جهة الاتصال
        },
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _printTransaction,
            icon: const Icon(Icons.print),
            label: const Text('طباعة'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _shareTransaction,
            icon: const Icon(Icons.share),
            label: const Text('مشاركة'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddTransactionScreen(
                    transaction: widget.transaction,
                  ),
                ),
              ).then((result) {
                if (result == true) {
                  Navigator.pop(context, true);
                }
              });
            },
            icon: const Icon(Icons.edit),
            label: const Text('تعديل'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              foregroundColor: Colors.blue,
            ),
          ),
        ),
      ],
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

  void _shareTransaction() async {
    final transaction = widget.transaction;
    final shareText = '''
العمليات المالية
النوع: ${transaction.typeName}
المبلغ: ${CurrencyUtils.formatAmount(transaction.amount)}
العملة: ${transaction.currency}
الوصف: ${transaction.description ?? 'لا يوجد'}
التاريخ: ${DateFormat('yyyy/MM/dd HH:mm').format(transaction.date)}
رقم العملية: ${transaction.id.substring(0, 8)}
    ''';
    await Share.share(shareText);
  }

  void _printTransaction() {
    // سيتم تنفيذ الطباعة باستخدام حزمة pdf
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('جاري طباعة العملية...'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}