import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:integrated_accounting_system/core/enums/enums.dart';
import 'package:integrated_accounting_system/core/utils/currency_utils.dart';
import 'package:integrated_accounting_system/core/widgets/empty_state_widget.dart';
import 'package:integrated_accounting_system/core/widgets/loading_widget.dart';
import 'package:integrated_accounting_system/domain/entities/debt.dart';
import 'package:integrated_accounting_system/presentation/providers/debts_provider.dart';
import 'package:integrated_accounting_system/presentation/providers/contacts_provider.dart';
import 'package:integrated_accounting_system/presentation/screens/debts/add_debt_screen.dart';
import 'package:integrated_accounting_system/presentation/screens/debts/add_installment_screen.dart';
import 'package:integrated_accounting_system/presentation/widgets/common/error_widget.dart';

class DebtsScreen extends ConsumerStatefulWidget {
  const DebtsScreen({super.key});

  @override
  ConsumerState<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends ConsumerState<DebtsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(debtsProvider.notifier).loadDebts();
      ref.read(contactsProvider.notifier).loadContacts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final debtsState = ref.watch(debtsProvider);
    final contactsState = ref.watch(contactsProvider);
    final debts = debtsState.debts;
    final isLoading = debtsState.isLoading;
    final error = debtsState.error;
    final isRTL = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الديون'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: _showStatsDialog,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Column(
            children: [
              _buildSummaryBar(debtsState),
              _buildFilterChips(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddDebt(),
        icon: const Icon(Icons.add),
        label: const Text('دين جديد'),
      ),
      body: _buildBody(debtsState, contactsState),
    );
  }

  Widget _buildBody(DebtsState debtsState, ContactsState contactsState) {
    if (debtsState.isLoading) {
      return const LoadingWidget();
    }

    if (debtsState.error != null) {
      return ErrorWidgetComponent(
        message: debtsState.error!,
        onRetry: () => ref.read(debtsProvider.notifier).loadDebts(),
      );
    }

    if (debtsState.debts.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.account_balance,
        title: 'لا توجد ديون',
        subtitle: 'قم بإضافة أول دين',
        buttonText: 'إضافة دين',
        onPressed: () => _navigateToAddDebt(),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: debtsState.debts.length,
      itemBuilder: (context, index) {
        final debt = debtsState.debts[index];
        final contact = contactsState.contacts.firstWhere(
          (c) => c.id == debt.contactId,
          orElse: () => throw Exception('Contact not found'),
        );
        return _buildDebtCard(debt, contact);
      },
    );
  }

  Widget _buildSummaryBar(DebtsState state) {
    final totalDebts = state.totalDebts;
    final totalRemaining = state.totalRemaining;
    final activeCount = state.activeDebts.length;
    final overdueCount = state.overdueDebts.length;

    return Container(
      height: 35,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('إجمالي الديون', totalDebts, Colors.blue),
          _buildSummaryItem('المتبقي', totalRemaining, Colors.orange),
          _buildSummaryItem('نشط ($activeCount)', activeCount.toDouble(), Colors.green),
          _buildSummaryItem('متأخر ($overdueCount)', overdueCount.toDouble(), Colors.red),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, double value, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10),
        ),
        Text(
          label.contains('نشط') || label.contains('متأخر')
              ? value.toInt().toString()
              : CurrencyUtils.formatAmount(value),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    final selectedStatus = ref.watch(debtsProvider).selectedStatus;

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildChip('الكل', null, selectedStatus == null),
          _buildChip('نشط', DebtStatus.active, selectedStatus == DebtStatus.active),
          _buildChip('متأخر', DebtStatus.overdue, selectedStatus == DebtStatus.overdue),
          _buildChip('مدفوع', DebtStatus.paid, selectedStatus == DebtStatus.paid),
        ],
      ),
    );
  }

  Widget _buildChip(String label, DebtStatus? status, bool selected) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {
          ref.read(debtsProvider.notifier).filterByStatus(status);
        },
        backgroundColor: Colors.grey[200],
        selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
        checkmarkColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildDebtCard(Debt debt, Contact contact) {
    final progress = debt.paidPercentage;
    final isOverdue = debt.isOverdue;

    return Slidable(
      key: ValueKey(debt.id),
      endActionPane: ActionPane(
        motion: const StretchMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => _addInstallment(debt),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            icon: Icons.payment,
            label: 'تسديد',
          ),
          SlidableAction(
            onPressed: (_) => _editDebt(debt),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: 'تعديل',
          ),
          SlidableAction(
            onPressed: (_) => _deleteDebt(debt),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'حذف',
          ),
        ],
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // الصف العلوي: الاسم والمبلغ
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          contact.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'تاريخ الاستحقاق: ${debt.dueDate.year}/${debt.dueDate.month}/${debt.dueDate.day}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isOverdue ? Colors.red : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        CurrencyUtils.formatAmount(debt.totalAmount),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
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
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // شريط التقدم
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress / 100,
                        backgroundColor: Colors.grey[200],
                        color: progress >= 100
                            ? Colors.green
                            : isOverdue
                                ? Colors.red
                                : Colors.blue,
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${progress.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // تفاصيل إضافية
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'المدفوع: ${CurrencyUtils.formatAmount(debt.paidAmount)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                    ),
                  ),
                  Text(
                    'المتبقي: ${CurrencyUtils.formatAmount(debt.remainingAmount)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: debt.remainingAmount > 0
                          ? Colors.orange
                          : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (debt.installments.isNotEmpty)
                    Text(
                      'أقساط: ${debt.installments.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterDialog() {
    final selectedStatus = ref.read(debtsProvider).selectedStatus;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تصفية الديون'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFilterOption('الكل', null, selectedStatus == null),
            _buildFilterOption('نشط', DebtStatus.active, selectedStatus == DebtStatus.active),
            _buildFilterOption('متأخر', DebtStatus.overdue, selectedStatus == DebtStatus.overdue),
            _buildFilterOption('مدفوع', DebtStatus.paid, selectedStatus == DebtStatus.paid),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(String label, DebtStatus? status, bool selected) {
    return ListTile(
      title: Text(label),
      leading: Radio<DebtStatus?>(
        value: status,
        groupValue: ref.read(debtsProvider).selectedStatus,
        onChanged: (value) {
          ref.read(debtsProvider.notifier).filterByStatus(value);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showStatsDialog() {
    final state = ref.read(debtsProvider);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'إحصائيات الديون',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatItem('إجمالي الديون', state.totalDebts, Colors.blue),
            _buildStatItem('المتبقي', state.totalRemaining, Colors.orange),
            _buildStatItem('الديون النشطة', state.activeDebts.length.toDouble(), Colors.green),
            _buildStatItem('الديون المتأخرة', state.overdueDebts.length.toDouble(), Colors.red),
            _buildStatItem('الديون المدفوعة', state.paidDebts.length.toDouble(), Colors.grey),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.circle,
              color: color,
              size: 12,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Text(
            label.contains('نشطة') || label.contains('متأخرة') || label.contains('مدفوعة')
                ? value.toInt().toString()
                : CurrencyUtils.formatAmount(value),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToAddDebt() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddDebtScreen(),
      ),
    ).then((result) {
      if (result == true) {
        ref.read(debtsProvider.notifier).loadDebts();
      }
    });
  }

  void _addInstallment(Debt debt) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddInstallmentScreen(debt: debt),
      ),
    ).then((result) {
      if (result == true) {
        ref.read(debtsProvider.notifier).loadDebts();
      }
    });
  }

  void _editDebt(Debt debt) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddDebtScreen(debt: debt),
      ),
    ).then((result) {
      if (result == true) {
        ref.read(debtsProvider.notifier).loadDebts();
      }
    });
  }

  void _deleteDebt(Debt debt) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الدين'),
        content: Text(
          'هل أنت متأكد من حذف هذا الدين بقيمة ${CurrencyUtils.formatAmount(debt.totalAmount)}؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref.read(debtsProvider.notifier)
                  .deleteDebt(debt.id);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم حذف الدين بنجاح'),
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