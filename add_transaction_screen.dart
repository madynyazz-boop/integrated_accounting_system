import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:integrated_accounting_system/core/enums/enums.dart';
import 'package:integrated_accounting_system/core/constants/app_constants.dart';
import 'package:integrated_accounting_system/core/utils/currency_utils.dart';
import 'package:integrated_accounting_system/core/widgets/custom_button.dart';
import 'package:integrated_accounting_system/core/widgets/custom_text_field.dart';
import 'package:integrated_accounting_system/domain/entities/contact.dart';
import 'package:integrated_accounting_system/domain/entities/transaction.dart';
import 'package:integrated_accounting_system/presentation/providers/contacts_provider.dart';
import 'package:integrated_accounting_system/presentation/providers/transactions_provider.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  final Transaction? transaction;

  const AddTransactionScreen({super.key, this.transaction});

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  TransactionType? _selectedType;
  String _selectedCurrency = 'ريال يمني';
  String? _selectedContactId;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      _loadTransactionData();
    }
  }

  void _loadTransactionData() {
    final t = widget.transaction!;
    _selectedType = t.type;
    _selectedCurrency = t.currency;
    _selectedContactId = t.contactId;
    _selectedDate = t.date;
    _selectedTime = TimeOfDay.fromDateTime(t.date);
    _descriptionController.text = t.description ?? '';
    _amountController.text = t.amount.toString();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contactsState = ref.watch(contactsProvider);
    final contacts = contactsState.contacts;
    final isEdit = widget.transaction != null;
    final isRTL = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'تعديل عملية' : 'عملية مالية جديدة'),
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _deleteTransaction,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // نوع العملية
              const Text(
                'نوع العملية',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildTransactionTypeGrid(),
              const SizedBox(height: 24),

              // العميل/المورد
              Text(
                _selectedType == TransactionType.payment ? 'المورد' : 'العميل',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildContactDropdown(contacts),
              const SizedBox(height: 24),

              // المبلغ والعملة
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: CustomTextField(
                      label: 'المبلغ',
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      prefixIcon: const Icon(Icons.money),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'المبلغ مطلوب';
                        }
                        final amount = double.tryParse(value);
                        if (amount == null || amount <= 0) {
                          return 'المبلغ يجب أن يكون أكبر من صفر';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildCurrencyDropdown(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // التاريخ والوقت
              Row(
                children: [
                  Expanded(
                    child: _buildDatePicker(),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTimePicker(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // الوصف
              CustomTextField(
                label: 'الوصف',
                controller: _descriptionController,
                maxLines: 3,
                prefixIcon: const Icon(Icons.description),
                hint: 'أدخل وصف العملية...',
              ),
              const SizedBox(height: 32),

              // زر الحفظ
              CustomButton(
                text: isEdit ? 'تحديث العملية' : 'حفظ العملية',
                onPressed: _saveTransaction,
                isLoading: _isLoading,
                icon: isEdit ? Icons.save : Icons.add,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionTypeGrid() {
    final types = [
      {'type': TransactionType.receipt, 'label': 'قبض', 'icon': Icons.arrow_downward, 'color': Colors.green},
      {'type': TransactionType.payment, 'label': 'صرف', 'icon': Icons.arrow_upward, 'color': Colors.red},
      {'type': TransactionType.debt, 'label': 'دين', 'icon': Icons.account_balance, 'color': Colors.orange},
      {'type': TransactionType.settlement, 'label': 'تسديد', 'icon': Icons.check_circle, 'color': Colors.blue},
      {'type': TransactionType.transfer, 'label': 'تحويل', 'icon': Icons.swap_horiz, 'color': Colors.purple},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        childAspectRatio: 0.9,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: types.length,
      itemBuilder: (context, index) {
        final item = types[index];
        final isSelected = _selectedType == item['type'];
        final color = item['color'] as Color;

        return InkWell(
          onTap: () {
            setState(() {
              _selectedType = item['type'] as TransactionType;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.2) : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? color : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  item['icon'] as IconData,
                  color: isSelected ? color : Colors.grey[600],
                  size: 28,
                ),
                const SizedBox(height: 4),
                Text(
                  item['label'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected ? color : Colors.grey[600],
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContactDropdown(List<Contact> contacts) {
    // فلترة العملاء حسب نوع العملية
    final filteredContacts = contacts.where((contact) {
      if (_selectedType == TransactionType.payment) {
        return contact.type == ContactType.supplier;
      } else if (_selectedType == TransactionType.receipt ||
                 _selectedType == TransactionType.debt ||
                 _selectedType == TransactionType.settlement) {
        return contact.type == ContactType.customer;
      } else {
        return true;
      }
    }).toList();

    if (_selectedType == TransactionType.transfer) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'عمليات التحويل لا تحتاج إلى عميل/مورد',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return DropdownButtonFormField<String>(
      value: _selectedContactId,
      hint: const Text('اختر العميل/المورد'),
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: Icon(
          _selectedType == TransactionType.payment ? Icons.business : Icons.person,
        ),
      ),
      items: [
        const DropdownMenuItem(
          value: null,
          child: Text('بدون عميل/مورد'),
        ),
        ...filteredContacts.map((contact) {
          return DropdownMenuItem(
            value: contact.id,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey[300],
                  child: Text(
                    contact.name[0],
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact.name,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      if (contact.phone != null)
                        Text(
                          contact.phone!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
      onChanged: (value) {
        setState(() {
          _selectedContactId = value;
        });
      },
      validator: (value) {
        if (_selectedType != TransactionType.transfer && 
            _selectedType != null &&
            value == null) {
          return 'الرجاء اختيار العميل/المورد';
        }
        return null;
      },
    );
  }

  Widget _buildCurrencyDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCurrency,
      decoration: InputDecoration(
        labelText: 'العملة',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: const Icon(Icons.currency_exchange),
      ),
      items: AppConstants.currencies.map((currency) {
        return DropdownMenuItem(
          value: currency,
          child: Row(
            children: [
              Text(CurrencyUtils.getCurrencySymbol(currency)),
              const SizedBox(width: 8),
              Text(currency),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCurrency = value!;
        });
      },
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (date != null) {
          setState(() {
            _selectedDate = date;
          });
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Colors.grey),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${_selectedDate.year}/${_selectedDate.month}/${_selectedDate.day}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker() {
    return InkWell(
      onTap: () async {
        final time = await showTimePicker(
          context: context,
          initialTime: _selectedTime,
        );
        if (time != null) {
          setState(() {
            _selectedTime = time;
          });
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time, color: Colors.grey),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _selectedTime.format(context),
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final amount = double.parse(_amountController.text);
        final dateTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );

        bool success;

        if (widget.transaction != null) {
          // تحديث عملية موجودة
          final updatedTransaction = widget.transaction!.copyWith(
            contactId: _selectedContactId,
            type: _selectedType!,
            amount: amount,
            currency: _selectedCurrency,
            description: _descriptionController.text,
            date: dateTime,
          );
          success = await ref.read(transactionsProvider.notifier)
              .updateTransaction(updatedTransaction);
        } else {
          // إضافة عملية جديدة
          success = await ref.read(transactionsProvider.notifier)
              .createTransaction(
            contactId: _selectedContactId,
            type: _selectedType!,
            amount: amount,
            currency: _selectedCurrency,
            description: _descriptionController.text,
            date: dateTime,
          );
        }

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.transaction != null
                    ? 'تم تحديث العملية بنجاح'
                    : 'تم إضافة العملية بنجاح',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('حدث خطأ: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _deleteTransaction() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف العملية'),
        content: const Text('هل أنت متأكد من حذف هذه العملية؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref.read(transactionsProvider.notifier)
                  .deleteTransaction(widget.transaction!.id);
              if (success && mounted) {
                Navigator.pop(context, true);
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