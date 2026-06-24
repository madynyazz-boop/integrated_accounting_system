import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:integrated_accounting_system/core/utils/currency_utils.dart';
import 'package:integrated_accounting_system/core/widgets/custom_button.dart';
import 'package:integrated_accounting_system/core/widgets/custom_text_field.dart';
import 'package:integrated_accounting_system/domain/entities/debt.dart';
import 'package:integrated_accounting_system/presentation/providers/debts_provider.dart';

class AddInstallmentScreen extends ConsumerStatefulWidget {
  final Debt debt;

  const AddInstallmentScreen({
    super.key,
    required this.debt,
  });

  @override
  ConsumerState<AddInstallmentScreen> createState() => _AddInstallmentScreenState();
}

class _AddInstallmentScreenState extends ConsumerState<AddInstallmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 30));
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // تعيين المبلغ المتبقي كقيمة افتراضية
    _amountController.text = widget.debt.remainingAmount.toString();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final debt = widget.debt;
    final isRTL = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تسديد قسط'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // معلومات الدين
              Card(
                elevation: 2,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'معلومات الدين',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow('إجمالي الدين', CurrencyUtils.formatAmount(debt.totalAmount)),
                      _buildInfoRow('المدفوع', CurrencyUtils.formatAmount(debt.paidAmount)),
                      _buildInfoRow('المتبقي', CurrencyUtils.formatAmount(debt.remainingAmount)),
                      _buildInfoRow('تاريخ الاستحقاق', '${debt.dueDate.year}/${debt.dueDate.month}/${debt.dueDate.day}'),
                      if (debt.description != null)
                        _buildInfoRow('الوصف', debt.description!),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // حقل المبلغ
              CustomTextField(
                label: 'مبلغ القسط',
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
                  if (amount > widget.debt.remainingAmount) {
                    return 'المبلغ لا يمكن أن يتجاوز المتبقي';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // تاريخ القسط
              _buildDatePicker(),
              const SizedBox(height: 32),

              // زر الحفظ
              CustomButton(
                text: 'تسديد القسط',
                onPressed: _saveInstallment,
                isLoading: _isLoading,
                icon: Icons.payment,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
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

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
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
                'تاريخ القسط: ${_selectedDate.year}/${_selectedDate.month}/${_selectedDate.day}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveInstallment() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final amount = double.parse(_amountController.text);

        // إنشاء قسط جديد
        final newInstallment = Installment(
          id: '', // سيتم إنشاؤه في المستودع
          debtId: widget.debt.id,
          amount: amount,
          dueDate: _selectedDate,
          status: InstallmentStatus.pending,
          paidDate: null,
          createdAt: DateTime.now(),
        );

        // تحديث الدين مع القسط الجديد
        final updatedDebt = widget.debt.copyWith(
          paidAmount: widget.debt.paidAmount + amount,
          status: widget.debt.paidAmount + amount >= widget.debt.totalAmount
              ? DebtStatus.paid
              : DebtStatus.active,
          installments: [...widget.debt.installments, newInstallment],
        );

        final success = await ref.read(debtsProvider.notifier)
            .updateDebt(updatedDebt);

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم تسديد القسط بنجاح'),
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
}