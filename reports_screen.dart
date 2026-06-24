import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:integrated_accounting_system/core/utils/currency_utils.dart';
import 'package:integrated_accounting_system/core/utils/date_utils.dart';
import 'package:integrated_accounting_system/presentation/providers/transactions_provider.dart';
import 'package:integrated_accounting_system/presentation/providers/debts_provider.dart';
import 'package:integrated_accounting_system/presentation/providers/contacts_provider.dart';
import 'package:integrated_accounting_system/presentation/widgets/common/loading_shimmer.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  int _selectedTab = 0;
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    ref.read(transactionsProvider.notifier).loadTransactions();
    ref.read(debtsProvider.notifier).loadDebts();
    ref.read(contactsProvider.notifier).loadContacts();
  }

  @override
  Widget build(BuildContext context) {
    final transactionsState = ref.watch(transactionsProvider);
    final debtsState = ref.watch(debtsProvider);
    final contactsState = ref.watch(contactsProvider);
    final isRTL = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      appBar: AppBar(
        title: const Text('التقارير'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _exportPDF,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _buildTabBar(),
        ),
      ),
      body: _buildBody(transactionsState, debtsState, contactsState),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildTab('ملخص عام', 0),
          _buildTab('أرباح وخسائر', 1),
          _buildTab('الديون', 2),
          _buildTab('العملاء', 3),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isSelected = _selectedTab == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          setState(() {
            _selectedTab = index;
          });
        },
        backgroundColor: Colors.grey[200],
        selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
        checkmarkColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildBody(
    TransactionsState transactionsState,
    DebtsState debtsState,
    ContactsState contactsState,
  ) {
    if (transactionsState.isLoading || debtsState.isLoading || contactsState.isLoading) {
      return LoadingShimmer.listShimmer();
    }

    switch (_selectedTab) {
      case 0:
        return _buildGeneralReport(transactionsState, debtsState, contactsState);
      case 1:
        return _buildProfitReport(transactionsState);
      case 2:
        return _buildDebtReport(debtsState);
      case 3:
        return _buildCustomerReport(transactionsState, contactsState);
      default:
        return const SizedBox.shrink();
    }
  }

  // ===================== تقرير عام =====================
  Widget _buildGeneralReport(
    TransactionsState transactionsState,
    DebtsState debtsState,
    ContactsState contactsState,
  ) {
    final totalReceipt = transactionsState.totalReceipt;
    final totalPayment = transactionsState.totalPayment;
    final balance = transactionsState.balance;
    final totalDebts = debtsState.totalDebts;
    final contactsCount = contactsState.contacts.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // بطاقات الإحصائيات الرئيسية
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.1,
            children: [
              _buildStatCard(
                'إجمالي القبض',
                CurrencyUtils.formatAmount(totalReceipt),
                Colors.green,
                Icons.arrow_downward,
              ),
              _buildStatCard(
                'إجمالي الصرف',
                CurrencyUtils.formatAmount(totalPayment),
                Colors.red,
                Icons.arrow_upward,
              ),
              _buildStatCard(
                'صافي الرصيد',
                CurrencyUtils.formatAmount(balance),
                Colors.blue,
                Icons.account_balance,
              ),
              _buildStatCard(
                'إجمالي الديون',
                CurrencyUtils.formatAmount(totalDebts),
                Colors.orange,
                Icons.account_balance,
              ),
              _buildStatCard(
                'عدد العملاء',
                contactsCount.toString(),
                Colors.purple,
                Icons.people,
              ),
              _buildStatCard(
                'عدد العمليات',
                transactionsState.count.toString(),
                Colors.teal,
                Icons.receipt_long,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ملخص الديون
          if (debtsState.debts.isNotEmpty)
            Card(
              elevation: 2,
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ملخص الديون',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDebtSummaryItem(
                      'نشط',
                      debtsState.activeDebts.length,
                      debtsState.activeDebts.fold(0.0, (sum, d) => sum + d.totalAmount),
                      Colors.blue,
                    ),
                    _buildDebtSummaryItem(
                      'متأخر',
                      debtsState.overdueDebts.length,
                      debtsState.overdueDebts.fold(0.0, (sum, d) => sum + d.totalAmount),
                      Colors.red,
                    ),
                    _buildDebtSummaryItem(
                      'مدفوع',
                      debtsState.paidDebts.length,
                      debtsState.paidDebts.fold(0.0, (sum, d) => sum + d.totalAmount),
                      Colors.green,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebtSummaryItem(String label, int count, double amount, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$label ($count)',
            style: const TextStyle(fontSize: 14),
          ),
          const Spacer(),
          Text(
            CurrencyUtils.formatAmount(amount),
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

  // ===================== تقرير الأرباح والخسائر =====================
  Widget _buildProfitReport(TransactionsState state) {
    // حساب الأرباح الشهرية
    final monthlyData = _calculateMonthlyProfit(state.transactions);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // الرسم البياني
          Card(
            elevation: 2,
            child: Container(
              padding: const EdgeInsets.all(16),
              height: 300,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'الأرباح الشهرية',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _buildMonthlyChart(monthlyData),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // جدول الأرباح الشهرية
          Card(
            elevation: 2,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'تفاصيل الأرباح الشهرية',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 20,
                      columns: const [
                        DataColumn(label: Text('الشهر')),
                        DataColumn(label: Text('القبض')),
                        DataColumn(label: Text('الصرف')),
                        DataColumn(label: Text('الأرباح')),
                      ],
                      rows: monthlyData.map((data) {
                        final monthName = DateUtils.getMonthName(data['month'] as int);
                        final receipt = data['receipt'] as double;
                        final payment = data['payment'] as double;
                        final profit = data['profit'] as double;
                        final color = profit >= 0 ? Colors.green : Colors.red;

                        return DataRow(
                          cells: [
                            DataCell(Text(monthName)),
                            DataCell(Text(CurrencyUtils.formatAmount(receipt))),
                            DataCell(Text(CurrencyUtils.formatAmount(payment))),
                            DataCell(
                              Text(
                                CurrencyUtils.formatAmount(profit),
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyChart(List<Map<String, dynamic>> data) {
    if (data.isEmpty) {
      return const Center(child: Text('لا توجد بيانات'));
    }

    final spots = data.asMap().entries.map((entry) {
      final profit = entry.value['profit'] as double;
      return FlSpot(
        entry.key.toDouble(),
        profit,
      );
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          horizontalInterval: 1000,
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < data.length) {
                  return Text(
                    DateUtils.getShortMonthName(data[index]['month'] as int),
                    style: const TextStyle(fontSize: 10),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Theme.of(context).primaryColor,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Theme.of(context).primaryColor.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _calculateMonthlyProfit(List<Transaction> transactions) {
    final Map<int, Map<String, double>> monthlyData = {};

    for (var i = 1; i <= 12; i++) {
      monthlyData[i] = {
        'receipt': 0.0,
        'payment': 0.0,
        'profit': 0.0,
      };
    }

    for (final transaction in transactions) {
      final month = transaction.date.month;
      final amount = transaction.amount;

      if (transaction.type == TransactionType.receipt) {
        monthlyData[month]!['receipt'] = (monthlyData[month]!['receipt'] ?? 0) + amount;
      } else if (transaction.type == TransactionType.payment) {
        monthlyData[month]!['payment'] = (monthlyData[month]!['payment'] ?? 0) + amount;
      }
    }

    final result = <Map<String, dynamic>>[];
    for (var i = 1; i <= 12; i++) {
      final data = monthlyData[i]!;
      result.add({
        'month': i,
        'receipt': data['receipt'] ?? 0,
        'payment': data['payment'] ?? 0,
        'profit': (data['receipt'] ?? 0) - (data['payment'] ?? 0),
      });
    }

    return result;
  }

  // ===================== تقرير الديون =====================
  Widget _buildDebtReport(DebtsState state) {
    final debts = state.debts;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // إحصائيات الديون
          Card(
            elevation: 2,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'إحصائيات الديون',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildDebtStatItem(
                        'إجمالي الديون',
                        CurrencyUtils.formatAmount(state.totalDebts),
                        Colors.blue,
                      ),
                      _buildDebtStatItem(
                        'المتبقي',
                        CurrencyUtils.formatAmount(state.totalRemaining),
                        Colors.orange,
                      ),
                      _buildDebtStatItem(
                        'الديون النشطة',
                        state.activeDebts.length.toString(),
                        Colors.green,
                      ),
                      _buildDebtStatItem(
                        'الديون المتأخرة',
                        state.overdueDebts.length.toString(),
                        Colors.red,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // جدول الديون
          if (debts.isNotEmpty)
            Card(
              elevation: 2,
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'قائمة الديون',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 20,
                        columns: const [
                          DataColumn(label: Text('العميل')),
                          DataColumn(label: Text('المبلغ')),
                          DataColumn(label: Text('المدفوع')),
                          DataColumn(label: Text('المتبقي')),
                          DataColumn(label: Text('الحالة')),
                          DataColumn(label: Text('التاريخ')),
                        ],
                        rows: debts.map((debt) {
                          return DataRow(
                            cells: [
                              DataCell(Text(debt.contactId.substring(0, 8))),
                              DataCell(Text(CurrencyUtils.formatAmount(debt.totalAmount))),
                              DataCell(Text(CurrencyUtils.formatAmount(debt.paidAmount))),
                              DataCell(Text(
                                CurrencyUtils.formatAmount(debt.remainingAmount),
                                style: TextStyle(
                                  color: debt.remainingAmount > 0 ? Colors.orange : Colors.green,
                                ),
                              )),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: debt.statusColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    debt.statusName,
                                    style: TextStyle(
                                      color: debt.statusColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(Text(
                                '${debt.dueDate.year}/${debt.dueDate.month}/${debt.dueDate.day}',
                              )),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDebtStatItem(String label, String value, Color color) {
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
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // ===================== تقرير العملاء =====================
  Widget _buildCustomerReport(
    TransactionsState transactionsState,
    ContactsState contactsState,
  ) {
    final contacts = contactsState.contacts;
    final customers = contacts.where((c) => c.type == ContactType.customer).toList();

    // حساب إحصائيات كل عميل
    final customerStats = customers.map((customer) {
      final customerTransactions = transactionsState.transactions
          .where((t) => t.contactId == customer.id)
          .toList();

      final totalReceipt = customerTransactions
          .where((t) => t.type == TransactionType.receipt)
          .fold(0.0, (sum, t) => sum + t.amount);

      final totalPayment = customerTransactions
          .where((t) => t.type == TransactionType.payment)
          .fold(0.0, (sum, t) => sum + t.amount);

      final balance = totalReceipt - totalPayment;
      final transactionCount = customerTransactions.length;

      return {
        'customer': customer,
        'totalReceipt': totalReceipt,
        'totalPayment': totalPayment,
        'balance': balance,
        'transactionCount': transactionCount,
      };
    }).toList();

    // ترتيب حسب الرصيد
    customerStats.sort((a, b) => (b['balance'] as double).compareTo(a['balance'] as double));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // إحصائيات العملاء
          Card(
            elevation: 2,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'إحصائيات العملاء',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildCustomerStatItem(
                        'إجمالي العملاء',
                        customers.length.toString(),
                        Colors.blue,
                      ),
                      _buildCustomerStatItem(
                        'إجمالي المعاملات',
                        transactionsState.count.toString(),
                        Colors.green,
                      ),
                      _buildCustomerStatItem(
                        'إجمالي القبض',
                        CurrencyUtils.formatAmount(transactionsState.totalReceipt),
                        Colors.green,
                      ),
                      _buildCustomerStatItem(
                        'إجمالي الصرف',
                        CurrencyUtils.formatAmount(transactionsState.totalPayment),
                        Colors.red,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // قائمة العملاء
          if (customerStats.isNotEmpty)
            Card(
              elevation: 2,
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ترتيب العملاء حسب الرصيد',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...customerStats.take(10).map((stat) {
                      final customer = stat['customer'] as Contact;
                      final balance = stat['balance'] as double;
                      final totalReceipt = stat['totalReceipt'] as double;
                      final totalPayment = stat['totalPayment'] as double;
                      final transactionCount = stat['transactionCount'] as int;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          child: Text(
                            customer.name[0],
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          customer.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'المعاملات: $transactionCount | القبض: ${CurrencyUtils.formatAmount(totalReceipt)} | الصرف: ${CurrencyUtils.formatAmount(totalPayment)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              CurrencyUtils.formatAmount(balance),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: balance >= 0 ? Colors.green : Colors.red,
                              ),
                            ),
                            Text(
                              balance >= 0 ? 'رصيد دائن' : 'رصيد مدين',
                              style: TextStyle(
                                fontSize: 11,
                                color: balance >= 0 ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCustomerStatItem(String label, String value, Color color) {
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
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  void _exportPDF() {
    // سيتم تنفيذ التصدير إلى PDF باستخدام حزمة pdf
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('جاري تصدير التقرير...'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}