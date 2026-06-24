import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:integrated_accounting_system/core/enums/enums.dart';
import 'package:integrated_accounting_system/core/constants/app_constants.dart';
import 'package:integrated_accounting_system/core/utils/currency_utils.dart';
import 'package:integrated_accounting_system/core/widgets/custom_button.dart';
import 'package:integrated_accounting_system/core/widgets/custom_text_field.dart';
import 'package:integrated_accounting_system/domain/entities/debt.dart';
import 'package:integrated_accounting_system/domain/entities/contact.dart';
import 'package:integrated_accounting_system/presentation/providers/contacts_provider.dart';
import 'package:integrated_accounting_system/presentation/providers/debts_provider.dart';

class AddDebtScreen extends ConsumerStatefulWidget {
  final Debt? debt;

  const AddDebtScreen({super.key, this.debt});

  @override
  ConsumerState<AddDebtScreen> createState() => _AddDebtScreenState();
}

class _AddDebtScreenState extends ConsumerState<AddDebtScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedCurrency = 'ريال يمني';
  String? _selectedContactId;
  DateTime _selectedDueDate = DateTime.now().add(const Duration(days: 30));
  bool _isLoading = false;
  bool _isInstallment = false;
  int _installmentCount = 3;

  @override
  void initState() {
    super.initState();
    if (widget.debt != null) {
      _loadDebtData();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(contactsProvider.notifier).loadContacts();
    });
  }

  void _loadDebtData() {
    final d = widget.debt!;
    _selectedContactId = d.contactId;
    _selectedCurrency = d.currency;
    _selectedDueDate = d.dueDate;
    _amountController.text = d.totalAmount.toString();
    _descriptionController.text = d.description ?? '';
    _isInstallment = d.installments.isNotEmpty;
    _installmentCount = d.installments.isNotEmpty ? d.installments.length : 3;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contactsState = ref.watch(contactsProvider);
    final contacts = contactsState.contacts;
    final isEdit = widget.debt != null;
    final isRTL = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'تعديل دين' : 'إضافة دين جديد'),
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _deleteDebt,
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
              // اختيار العميل
              const Text(
                'العميل',
                style: TextStyle(
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

              // تاريخ الاستحقاق
              _buildDueDatePicker(),
              const SizedBox(height: 24),

              // خيار الأقساط
              _buildInstallmentOption(),
              const SizedBox(height: 24),

              // الوصف
              CustomTextField(
                label: 'الوصف',
                controller: _descriptionController,
                maxLines: 3,
                prefixIcon: const Icon(Icons.description),
                hint: 'أدخل وصف الدين...',
              ),
              const SizedBox(height: 32),

              // زر الحفظ
              CustomButton(
                text: isEdit ? 'تحديث الدين' : 'حفظ الدين',
                onPressed: _saveDebt,
                isLoading: _isLoading,
                icon: isEdit ? Icons.save : Icons.add,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactDropdown(List<Contact> contacts) {
    final customers = contacts.where((c) => c.type == ContactType.customer).toList();

    return DropdownButtonFormField<String>(
      value: _selectedContactId,
      hint: const Text('اختر العميل'),
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: const Icon(Icons.person),
      ),
      items: customers.map((contact) {
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
      onChanged: (value) {
        setState(() {
          _selectedContactId = value;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'الرجاء اختيار العميل';
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

  Widget _buildDueDatePicker() {
    final isRTL = Directionality.of(context) == TextDirection.rtl;

    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedDueDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
        );
        if (date != null) {
          setState(() {
            _selectedDueDate = date;
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
                'تاريخ الاستحقاق: ${_selectedDueDate.year}/${_selectedDueDate.month}/${_selectedDueDate.day}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstallmentOption() {
    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Switch(
                  value: _isInstallment,
                  onChanged: (value) {
                    setState(() {
                      _isInstallment = value;
                    });
                  },
                ),
                const SizedBox(width: 8),
                const Text(
                  'تقسيم الدين إلى أقساط',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (_isInstallment) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('عدد الأقساط:'),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _installmentCount,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: List.generate(10, (index) {
                        final count = index + 1;
                        return DropdownMenuItem(
                          value: count,
                          child: Text('$count أقساط'),
                        );
                      }),
                      onChanged: (value) {
                        setState(() {
                          _installmentCount = value ?? 3;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_amountController.text.isNotEmpty) ...[
                final amount = double.tryParse(_amountController.text) ?? 0;
                final installmentAmount = amount / _installmentCount;
                Text(
                  'قيمة كل قسط: ${CurrencyUtils.formatAmount(installmentAmount)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.blue,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  void _saveDebt() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedContactId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('الرجاء اختيار العميل'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        final amount = double.parse(_amountController.text);
        final description = _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim();

        bool success;

        if (widget.debt != null) {
          // تحديث دين موجود
          final updatedDebt = widget.debt!.copyWith(
            contactId: _selectedContactId!,
            totalAmount: amount,
            currency: _selectedCurrency,
            description: description,
            dueDate: _selectedDueDate,
          );
          success = await ref.read(debtsProvider.notifier)
              .updateDebt(updatedDebt);
        } else {
          // إضافة دين جديد
          success = await ref.read(debtsProvider.notifier).createDebt(
            contactId: _selectedContactId!,
            totalAmount: amount,
            currency: _selectedCurrency,
            description: description,
            dueDate: _selectedDueDate,
          );
        }

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.debt != null
                    ? 'تم تحديث الدين بنجاح'
                    : 'تم إضافة الدين بنجاح',
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

  void _deleteDebt() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الدين'),
        content: const Text('هل أنت متأكد من حذف هذا الدين؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref.read(debtsProvider.notifier)
                  .deleteDebt(widget.debt!.id);
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