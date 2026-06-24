import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:integrated_accounting_system/core/enums/enums.dart';
import 'package:integrated_accounting_system/core/utils/currency_utils.dart';
import 'package:integrated_accounting_system/core/widgets/empty_state_widget.dart';
import 'package:integrated_accounting_system/core/widgets/loading_widget.dart';
import 'package:integrated_accounting_system/domain/entities/transaction.dart';
import 'package:integrated_accounting_system/presentation/providers/transactions_provider.dart';
import 'package:integrated_accounting_system/presentation/screens/transactions/add_transaction_screen.dart';
import 'package:integrated_accounting_system/presentation/screens/transactions/transaction_details_screen.dart';
import 'package:integrated_accounting_system/presentation/widgets/common/error_widget.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(transactionsProvider.notifier).loadTransactions();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transactionsState = ref.watch(transactionsProvider);
    final transactions = transactionsState.transactions;
    final isLoading = transactionsState.isLoading;
    final error = transactionsState.error;
    final isRTL = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      appBar: AppBar(
        title: const Text('العمليات المالية'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: _showQuickStats,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              _buildSummaryBar(transactionsState),
              _buildFilterChips(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddTransaction(),
        icon: const Icon(Icons.add),
        label: const Text('عملية جديدة'),
      ),
      body: _buildBody(transactionsState),
    );
  }

  Widget _buildBody(TransactionsState state) {
    if (state.isLoading) {
      return const LoadingWidget();
    }

    if (state.error != null) {
      return ErrorWidgetComponent(
        message: state.error!,
        onRetry: () => ref.read(transactionsProvider.notifier).loadTransactions(),
      );
    }

    if (state.transactions.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.receipt_long,
        title: 'لا توجد عمليات',
        subtitle: 'قم بإضافة أول عملية مالية',
        buttonText: 'إضافة عملية',
        onPressed: () => _navigateToAddTransaction(),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: state.transactions.length,
      itemBuilder: (context, index) {
        final transaction = state.transactions[index];
        return _buildTransactionCard(transaction);
      },
    );
  }

  Widget _buildSummaryBar(TransactionsState state) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(
            'القبض',
            state.totalReceipt,
            Colors.green,
            Icons.arrow_downward,
          ),
          _buildSummaryItem(
            'الصرف',
            state.totalPayment,
            Colors.red,
            Icons.arrow_upward,
          ),
          _buildSummaryItem(
            'الرصيد',
            state.balance,
            Colors.blue,
            Icons.account_balance,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, double amount, Color color, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
        const SizedBox(width: 4),
        Text(
          CurrencyUtils.formatAmount(amount),
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
    final selectedType = ref.watch(transactionsProvider).selectedType;

    return Container(
      height: 45,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildChip('الكل', null, selectedType == null),
          _buildChip('قبض', TransactionType.receipt, selectedType == TransactionType.receipt),
          _buildChip('صرف', TransactionType.payment, selectedType == TransactionType.payment),
          _buildChip('دين', TransactionType.debt, selectedType == TransactionType.debt),
          _buildChip('تسديد', TransactionType.settlement, selectedType == TransactionType.settlement),
          _buildChip('تحويل', TransactionType.transfer, selectedType == TransactionType.transfer),
        ],
      ),
    );
  }

  Widget _buildChip(String label, TransactionType? type, bool selected) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {
          ref.read(transactionsProvider.notifier).filterByType(type);
        },
        backgroundColor: Colors.grey[200],
        selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
        checkmarkColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildTransactionCard(Transaction transaction) {
    return Slidable(
      key: ValueKey(transaction.id),
      endActionPane: ActionPane(
        motion: const StretchMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => _editTransaction(transaction),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: 'تعديل',
          ),
          SlidableAction(
            onPressed: (_) => _deleteTransaction(transaction),
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
            backgroundColor: transaction.typeColor.withOpacity(0.2),
            child: Icon(
              transaction.typeIcon,
              color: transaction.typeColor,
              size: 24,
            ),
          ),
          title: Text(
            transaction.description ?? transaction.typeName,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${transaction.date.year}/${transaction.date.month}/${transaction.date.day}',
                style: const TextStyle(fontSize: 12),
              ),
              if (transaction.contactId != null)
                Text(
                  'رقم العميل: ${transaction.contactId!.substring(0, 8)}',
                  style: const TextStyle(fontSize: 11),
                ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyUtils.formatAmount(transaction.amount),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: transaction.typeColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: transaction.typeColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  transaction.typeName,
                  style: TextStyle(
                    fontSize: 11,
                    color: transaction.typeColor,
                  ),
                ),
              ),
            ],
          ),
          onTap: () => _navigateToDetails(transaction),
        ),
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('بحث عن عملية'),
        content: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'ابحث بالوصف أو المبلغ...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onChanged: (value) {
            ref.read(transactionsProvider.notifier).searchTransactions(value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              _searchController.clear();
              ref.read(transactionsProvider.notifier).searchTransactions('');
              Navigator.pop(context);
            },
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    final selectedType = ref.read(transactionsProvider).selectedType;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تصفية العمليات'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFilterOption('الكل', null, selectedType == null),
              _buildFilterOption('قبض', TransactionType.receipt, selectedType == TransactionType.receipt),
              _buildFilterOption('صرف', TransactionType.payment, selectedType == TransactionType.payment),
              _buildFilterOption('دين', TransactionType.debt, selectedType == TransactionType.debt),
              _buildFilterOption('تسديد', TransactionType.settlement, selectedType == TransactionType.settlement),
              _buildFilterOption('تحويل', TransactionType.transfer, selectedType == TransactionType.transfer),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterOption(String label, TransactionType? type, bool selected) {
    return ListTile(
      title: Text(label),
      leading: Radio<TransactionType?>(
        value: type,
        groupValue: ref.read(transactionsProvider).selectedType,
        onChanged: (value) {
          ref.read(transactionsProvider.notifier).filterByType(value);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showQuickStats() {
    final state = ref.read(transactionsProvider);

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
              'إحصائيات سريعة',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatItem(
              'إجمالي القبض',
              state.totalReceipt,
              Icons.arrow_downward,
              Colors.green,
            ),
            _buildStatItem(
              'إجمالي الصرف',
              state.totalPayment,
              Icons.arrow_upward,
              Colors.red,
            ),
            _buildStatItem(
              'صافي الرصيد',
              state.balance,
              Icons.account_balance,
              Colors.blue,
            ),
            const Divider(),
            _buildStatItem(
              'عدد العمليات',
              state.count.toDouble(),
              Icons.receipt_long,
              Colors.purple,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, double value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Text(
            label == 'عدد العمليات' 
                ? value.toInt().toString()
                : CurrencyUtils.formatAmount(value),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToAddTransaction() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddTransactionScreen(),
      ),
    ).then((result) {
      if (result == true) {
        ref.read(transactionsProvider.notifier).loadTransactions();
      }
    });
  }

  void _navigateToDetails(Transaction transaction) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransactionDetailsScreen(
          transaction: transaction,
        ),
      ),
    );
  }

  void _editTransaction(Transaction transaction) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTransactionScreen(
          transaction: transaction,
        ),
      ),
    ).then((result) {
      if (result == true) {
        ref.read(transactionsProvider.notifier).loadTransactions();
      }
    });
  }

  void _deleteTransaction(Transaction transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف العملية'),
        content: Text(
          'هل أنت متأكد من حذف عملية "${transaction.description ?? transaction.typeName}"؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref.read(transactionsProvider.notifier)
                  .deleteTransaction(transaction.id);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم حذف العملية بنجاح'),
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