import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:integrated_accounting_system/core/utils/currency_utils.dart';
import 'package:integrated_accounting_system/presentation/providers/dashboard_provider.dart';
import 'package:integrated_accounting_system/presentation/providers/transactions_provider.dart';
import 'package:integrated_accounting_system/presentation/providers/contacts_provider.dart';
import 'package:integrated_accounting_system/presentation/providers/debts_provider.dart';
import 'package:integrated_accounting_system/presentation/widgets/common/app_drawer.dart';
import 'package:integrated_accounting_system/presentation/widgets/common/loading_shimmer.dart';
import 'package:integrated_accounting_system/presentation/widgets/common/error_widget.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    await ref.read(dashboardProvider.notifier).loadDashboardData();
    await ref.read(transactionsProvider.notifier).loadTransactions();
    await ref.read(contactsProvider.notifier).loadContacts();
    await ref.read(debtsProvider.notifier).loadDebts();
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(dashboardProvider);
    final transactionsState = ref.watch(transactionsProvider);
    final debtsState = ref.watch(debtsProvider);
    final isRTL = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الرئيسية'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // عرض الإشعارات
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: dashboardState.isLoading
            ? LoadingShimmer.listShimmer()
            : dashboardState.error != null
                ? ErrorWidgetComponent(
                    message: dashboardState.error!,
                    onRetry: _loadData,
                  )
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // بطاقات الإحصائيات
                        _buildStatsGrid(dashboardState),
                        const SizedBox(height: 24),

                        // الرسم البياني
                        _buildChart(dashboardState),
                        const SizedBox(height: 24),

                        // آخر العمليات
                        _buildRecentTransactions(transactionsState),
                        const SizedBox(height: 24),

                        // تنبيهات الديون
                        _buildDebtAlerts(debtsState),
                      ],
                    ),
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showQuickActions,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatsGrid(DashboardState state) {
    final stats = [
      {
        'label': 'إجمالي القبض',
        'value': CurrencyUtils.formatAmount(state.totalReceipt),
        'color': Colors.green,
        'icon': Icons.arrow_downward,
      },
      {
        'label': 'إجمالي الصرف',
        'value': CurrencyUtils.formatAmount(state.totalPayment),
        'color': Colors.red,
        'icon': Icons.arrow_upward,
      },
      {
        'label': 'الرصيد الحالي',
        'value': CurrencyUtils.formatAmount(state.totalBalance),
        'color': Colors.blue,
        'icon': Icons.account_balance,
      },
      {
        'label': 'عدد العملاء',
        'value': state.contactsCount.toString(),
        'color': Colors.orange,
        'icon': Icons.people,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return Card(
          elevation: 4,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  (stat['color'] as Color).withOpacity(0.1),
                  Colors.white,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (stat['color'] as Color).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    stat['icon'] as IconData,
                    color: stat['color'] as Color,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  stat['label'] as String,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  stat['value'] as String,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: stat['color'] as Color,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChart(DashboardState state) {
    if (state.monthlyChart.isEmpty) {
      return const SizedBox.shrink();
    }

    final spots = state.monthlyChart.asMap().entries.map((entry) {
      return FlSpot(
        entry.key.toDouble(),
        entry.value['profit'] as double,
      );
    }).toList();

    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(16),
        height: 220,
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
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawHorizontalLine: true,
                    horizontalInterval: 1,
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const months = [
                            'يناير', 'فبراير', 'مارس', 'أبريل',
                            'مايو', 'يونيو', 'يوليو', 'أغسطس',
                            'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
                          ];
                          final index = value.toInt();
                          if (index >= 0 && index < months.length) {
                            return Text(
                              months[index],
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions(TransactionsState state) {
    final recent = state.transactions.take(5).toList();

    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'آخر العمليات',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // الانتقال إلى شاشة المعاملات
                  },
                  child: const Text('عرض الكل'),
                ),
              ],
            ),
            if (recent.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('لا توجد عمليات'),
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
                      size: 20,
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
                  onTap: () {
                    // الانتقال إلى تفاصيل المعاملة
                  },
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildDebtAlerts(DebtsState state) {
    final overdue = state.overdueDebts;

    if (overdue.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 4,
      color: Colors.red.shade50,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.red.shade700),
                const SizedBox(width: 8),
                Text(
                  'تنبيهات الديون المتأخرة (${overdue.length})',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...overdue.take(3).map((debt) {
              return ListTile(
                leading: const Icon(Icons.error_outline, color: Colors.red),
                title: Text(
                  'دين بقيمة ${CurrencyUtils.formatAmount(debt.totalAmount)}',
                ),
                subtitle: Text(
                  'تاريخ الاستحقاق: ${debt.dueDate.year}/${debt.dueDate.month}/${debt.dueDate.day}',
                ),
                trailing: TextButton(
                  onPressed: () {
                    // الانتقال إلى تسديد الدين
                  },
                  child: const Text('تسديد'),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showQuickActions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          children: [
            const SizedBox(height: 8),
            _buildQuickAction(
              icon: Icons.receipt,
              label: 'عملية جديدة',
              color: Colors.blue,
              onTap: () {
                Navigator.pop(context);
                // الانتقال إلى إضافة عملية
              },
            ),
            _buildQuickAction(
              icon: Icons.person_add,
              label: 'إضافة عميل',
              color: Colors.green,
              onTap: () {
                Navigator.pop(context);
                // الانتقال إلى إضافة عميل
              },
            ),
            _buildQuickAction(
              icon: Icons.account_balance,
              label: 'إضافة دين',
              color: Colors.orange,
              onTap: () {
                Navigator.pop(context);
                // الانتقال إلى إضافة دين
              },
            ),
            _buildQuickAction(
              icon: Icons.analytics,
              label: 'تقرير سريع',
              color: Colors.purple,
              onTap: () {
                Navigator.pop(context);
                // الانتقال إلى التقارير
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(icon, color: color),
      ),
      title: Text(label),
      onTap: onTap,
    );
  }
}