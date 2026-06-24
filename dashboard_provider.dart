import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:integrated_accounting_system/data/repositories/transaction_repository_impl.dart';
import 'package:integrated_accounting_system/data/repositories/contact_repository_impl.dart';
import 'package:integrated_accounting_system/data/repositories/debt_repository_impl.dart';

// حالة لوحة التحكم
class DashboardState {
  final double totalBalance;
  final double totalReceipt;
  final double totalPayment;
  final int contactsCount;
  final double totalDebts;
  final Map<String, double> dailySummary;
  final List<Map<String, dynamic>> monthlyChart;
  final bool isLoading;
  final String? error;

  DashboardState({
    this.totalBalance = 0,
    this.totalReceipt = 0,
    this.totalPayment = 0,
    this.contactsCount = 0,
    this.totalDebts = 0,
    this.dailySummary = const {},
    this.monthlyChart = const [],
    this.isLoading = false,
    this.error,
  });

  DashboardState copyWith({
    double? totalBalance,
    double? totalReceipt,
    double? totalPayment,
    int? contactsCount,
    double? totalDebts,
    Map<String, double>? dailySummary,
    List<Map<String, dynamic>>? monthlyChart,
    bool? isLoading,
    String? error,
  }) {
    return DashboardState(
      totalBalance: totalBalance ?? this.totalBalance,
      totalReceipt: totalReceipt ?? this.totalReceipt,
      totalPayment: totalPayment ?? this.totalPayment,
      contactsCount: contactsCount ?? this.contactsCount,
      totalDebts: totalDebts ?? this.totalDebts,
      dailySummary: dailySummary ?? this.dailySummary,
      monthlyChart: monthlyChart ?? this.monthlyChart,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Notifier للوحة التحكم
class DashboardNotifier extends StateNotifier<DashboardState> {
  final TransactionRepositoryImpl _transactionRepository;
  final ContactRepositoryImpl _contactRepository;
  final DebtRepositoryImpl _debtRepository;

  DashboardNotifier(
    this._transactionRepository,
    this._contactRepository,
    this._debtRepository,
  ) : super(DashboardState());

  // تحميل بيانات لوحة التحكم
  Future<void> loadDashboardData() async {
    state = state.copyWith(isLoading: true);
    try {
      // تحميل البيانات بالتوازي
      final results = await Future.wait([
        _transactionRepository.getTotalBalance(),
        _transactionRepository.getTotalReceipt(),
        _transactionRepository.getTotalPayment(),
        _contactRepository.getContactsCount(),
        _debtRepository.getTotalDebts(),
        _transactionRepository.getDailySummary(DateTime.now()),
        _transactionRepository.getMonthlyChartData(DateTime.now()),
      ]);

      state = state.copyWith(
        totalBalance: results[0],
        totalReceipt: results[1],
        totalPayment: results[2],
        contactsCount: results[3],
        totalDebts: results[4],
        dailySummary: results[5],
        monthlyChart: results[6],
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // تحديث البيانات
  Future<void> refresh() async {
    await loadDashboardData();
  }

  // مسح الخطأ
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// مزود لوحة التحكم
final dashboardProvider = StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  final transactionRepo = ref.watch(transactionRepositoryProvider);
  final contactRepo = ref.watch(contactRepositoryProvider);
  final debtRepo = ref.watch(debtRepositoryProvider);
  
  return DashboardNotifier(transactionRepo, contactRepo, debtRepo);
});