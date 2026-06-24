import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:integrated_accounting_system/core/enums/enums.dart';
import 'package:integrated_accounting_system/data/repositories/debt_repository_impl.dart';
import 'package:integrated_accounting_system/data/datasources/local_database.dart';
import 'package:integrated_accounting_system/domain/entities/debt.dart';
import 'package:integrated_accounting_system/domain/usecases/debts/get_debts.dart';
import 'package:integrated_accounting_system/domain/usecases/debts/create_debt.dart';
import 'package:integrated_accounting_system/domain/usecases/debts/update_debt.dart';
import 'package:integrated_accounting_system/domain/usecases/debts/delete_debt.dart';
import 'package:integrated_accounting_system/domain/usecases/debts/get_overdue_debts.dart';

// مزود المستودع
final debtRepositoryProvider = Provider<DebtRepositoryImpl>((ref) {
  final localDatabase = ref.watch(localDatabaseProvider);
  return DebtRepositoryImpl(localDatabase);
});

// مزود حالات الاستخدام
final getDebtsUseCaseProvider = Provider<GetDebtsUseCase>((ref) {
  final repository = ref.watch(debtRepositoryProvider);
  return GetDebtsUseCase(repository);
});

final createDebtUseCaseProvider = Provider<CreateDebtUseCase>((ref) {
  final repository = ref.watch(debtRepositoryProvider);
  return CreateDebtUseCase(repository);
});

final updateDebtUseCaseProvider = Provider<UpdateDebtUseCase>((ref) {
  final repository = ref.watch(debtRepositoryProvider);
  return UpdateDebtUseCase(repository);
});

final deleteDebtUseCaseProvider = Provider<DeleteDebtUseCase>((ref) {
  final repository = ref.watch(debtRepositoryProvider);
  return DeleteDebtUseCase(repository);
});

final getOverdueDebtsUseCaseProvider = Provider<GetOverdueDebtsUseCase>((ref) {
  final repository = ref.watch(debtRepositoryProvider);
  return GetOverdueDebtsUseCase(repository);
});

// حالة الديون
class DebtsState {
  final List<Debt> debts;
  final bool isLoading;
  final String? error;
  final DebtStatus? selectedStatus;
  final double totalDebts;

  DebtsState({
    this.debts = const [],
    this.isLoading = false,
    this.error,
    this.selectedStatus,
    this.totalDebts = 0,
  });

  DebtsState copyWith({
    List<Debt>? debts,
    bool? isLoading,
    String? error,
    DebtStatus? selectedStatus,
    double? totalDebts,
  }) {
    return DebtsState(
      debts: debts ?? this.debts,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      totalDebts: totalDebts ?? this.totalDebts,
    );
  }

  // الديون النشطة
  List<Debt> get activeDebts => debts.where((d) => d.status == DebtStatus.active).toList();
  
  // الديون المتأخرة
  List<Debt> get overdueDebts => debts.where((d) => d.status == DebtStatus.overdue).toList();
  
  // الديون المدفوعة
  List<Debt> get paidDebts => debts.where((d) => d.status == DebtStatus.paid).toList();
  
  // إجمالي المبالغ المتبقية
  double get totalRemaining => debts.fold(0, (sum, d) => sum + d.remainingAmount);
}

// Notifier للديون
class DebtsNotifier extends StateNotifier<DebtsState> {
  final GetDebtsUseCase _getDebtsUseCase;
  final CreateDebtUseCase _createDebtUseCase;
  final UpdateDebtUseCase _updateDebtUseCase;
  final DeleteDebtUseCase _deleteDebtUseCase;
  final GetOverdueDebtsUseCase _getOverdueDebtsUseCase;
  final DebtRepositoryImpl _repository;

  DebtsNotifier(
    this._getDebtsUseCase,
    this._createDebtUseCase,
    this._updateDebtUseCase,
    this._deleteDebtUseCase,
    this._getOverdueDebtsUseCase,
    this._repository,
  ) : super(DebtsState());

  // تحميل الديون
  Future<void> loadDebts() async {
    state = state.copyWith(isLoading: true);
    try {
      final debts = await _getDebtsUseCase.execute(
        status: state.selectedStatus,
      );
      final totalDebts = await _repository.getTotalDebts();
      
      state = state.copyWith(
        debts: debts,
        isLoading: false,
        totalDebts: totalDebts,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // إنشاء دين جديد
  Future<bool> createDebt({
    required String contactId,
    required double totalAmount,
    required String currency,
    String? description,
    required DateTime dueDate,
    List<Installment>? installments,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final debt = await _createDebtUseCase.execute(
        contactId: contactId,
        totalAmount: totalAmount,
        currency: currency,
        description: description,
        dueDate: dueDate,
        installments: installments,
      );
      state = state.copyWith(
        debts: [...state.debts, debt],
        isLoading: false,
      );
      await _updateTotal();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  // تحديث دين
  Future<bool> updateDebt(Debt debt) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updated = await _updateDebtUseCase.execute(debt);
      final index = state.debts.indexWhere((d) => d.id == debt.id);
      if (index != -1) {
        final newList = List<Debt>.from(state.debts);
        newList[index] = updated;
        state = state.copyWith(debts: newList, isLoading: false);
      }
      await _updateTotal();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  // حذف دين
  Future<bool> deleteDebt(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _deleteDebtUseCase.execute(id);
      state = state.copyWith(
        debts: state.debts.where((d) => d.id != id).toList(),
        isLoading: false,
      );
      await _updateTotal();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  // تصفية حسب الحالة
  void filterByStatus(DebtStatus? status) {
    state = state.copyWith(selectedStatus: status);
    loadDebts();
  }

  // الحصول على الديون المتأخرة
  Future<List<Debt>> getOverdueDebts() async {
    try {
      return await _getOverdueDebtsUseCase.execute();
    } catch (e) {
      return [];
    }
  }

  // تحديث الإجمالي
  Future<void> _updateTotal() async {
    final totalDebts = await _repository.getTotalDebts();
    state = state.copyWith(totalDebts: totalDebts);
  }

  // مسح الخطأ
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// مزود حالة الديون
final debtsProvider = StateNotifierProvider<DebtsNotifier, DebtsState>((ref) {
  final get = ref.watch(getDebtsUseCaseProvider);
  final create = ref.watch(createDebtUseCaseProvider);
  final update = ref.watch(updateDebtUseCaseProvider);
  final delete = ref.watch(deleteDebtUseCaseProvider);
  final getOverdue = ref.watch(getOverdueDebtsUseCaseProvider);
  final repository = ref.watch(debtRepositoryProvider);
  
  return DebtsNotifier(get, create, update, delete, getOverdue, repository);
});