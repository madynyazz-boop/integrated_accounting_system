import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:integrated_accounting_system/core/enums/enums.dart';
import 'package:integrated_accounting_system/data/repositories/transaction_repository_impl.dart';
import 'package:integrated_accounting_system/data/datasources/local_database.dart';
import 'package:integrated_accounting_system/domain/entities/transaction.dart';
import 'package:integrated_accounting_system/domain/usecases/transactions/get_transactions.dart';
import 'package:integrated_accounting_system/domain/usecases/transactions/create_transaction.dart';
import 'package:integrated_accounting_system/domain/usecases/transactions/update_transaction.dart';
import 'package:integrated_accounting_system/domain/usecases/transactions/delete_transaction.dart';

// مزود المستودع
final transactionRepositoryProvider = Provider<TransactionRepositoryImpl>((ref) {
  final localDatabase = ref.watch(localDatabaseProvider);
  return TransactionRepositoryImpl(localDatabase);
});

// مزود حالات الاستخدام
final getTransactionsUseCaseProvider = Provider<GetTransactionsUseCase>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  return GetTransactionsUseCase(repository);
});

final createTransactionUseCaseProvider = Provider<CreateTransactionUseCase>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  return CreateTransactionUseCase(repository);
});

final updateTransactionUseCaseProvider = Provider<UpdateTransactionUseCase>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  return UpdateTransactionUseCase(repository);
});

final deleteTransactionUseCaseProvider = Provider<DeleteTransactionUseCase>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  return DeleteTransactionUseCase(repository);
});

// حالة المعاملات
class TransactionsState {
  final List<Transaction> transactions;
  final bool isLoading;
  final String? error;
  final TransactionType? selectedType;
  final double totalReceipt;
  final double totalPayment;
  final String searchQuery;

  TransactionsState({
    this.transactions = const [],
    this.isLoading = false,
    this.error,
    this.selectedType,
    this.totalReceipt = 0,
    this.totalPayment = 0,
    this.searchQuery = '',
  });

  TransactionsState copyWith({
    List<Transaction>? transactions,
    bool? isLoading,
    String? error,
    TransactionType? selectedType,
    double? totalReceipt,
    double? totalPayment,
    String? searchQuery,
  }) {
    return TransactionsState(
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedType: selectedType ?? this.selectedType,
      totalReceipt: totalReceipt ?? this.totalReceipt,
      totalPayment: totalPayment ?? this.totalPayment,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  // الرصيد الإجمالي
  double get balance => totalReceipt - totalPayment;
  
  // عدد المعاملات
  int get count => transactions.length;
  
  // القبض فقط
  List<Transaction> get receipts => transactions.where((t) => t.type == TransactionType.receipt).toList();
  
  // الصرف فقط
  List<Transaction> get payments => transactions.where((t) => t.type == TransactionType.payment).toList();
}

// Notifier للمعاملات
class TransactionsNotifier extends StateNotifier<TransactionsState> {
  final GetTransactionsUseCase _getTransactionsUseCase;
  final CreateTransactionUseCase _createTransactionUseCase;
  final UpdateTransactionUseCase _updateTransactionUseCase;
  final DeleteTransactionUseCase _deleteTransactionUseCase;
  final TransactionRepositoryImpl _repository;

  TransactionsNotifier(
    this._getTransactionsUseCase,
    this._createTransactionUseCase,
    this._updateTransactionUseCase,
    this._deleteTransactionUseCase,
    this._repository,
  ) : super(TransactionsState());

  // تحميل المعاملات
  Future<void> loadTransactions() async {
    state = state.copyWith(isLoading: true);
    try {
      final transactions = await _getTransactionsUseCase.execute(
        type: state.selectedType,
      );
      final totalReceipt = await _repository.getTotalReceipt();
      final totalPayment = await _repository.getTotalPayment();
      
      state = state.copyWith(
        transactions: transactions,
        isLoading: false,
        totalReceipt: totalReceipt,
        totalPayment: totalPayment,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // إنشاء معاملة جديدة
  Future<bool> createTransaction({
    String? contactId,
    required TransactionType type,
    required double amount,
    required String currency,
    String? description,
    required DateTime date,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final transaction = await _createTransactionUseCase.execute(
        contactId: contactId,
        type: type,
        amount: amount,
        currency: currency,
        description: description,
        date: date,
      );
      state = state.copyWith(
        transactions: [transaction, ...state.transactions],
        isLoading: false,
      );
      await _updateTotals();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  // تحديث معاملة
  Future<bool> updateTransaction(Transaction transaction) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updated = await _updateTransactionUseCase.execute(transaction);
      final index = state.transactions.indexWhere((t) => t.id == transaction.id);
      if (index != -1) {
        final newList = List<Transaction>.from(state.transactions);
        newList[index] = updated;
        state = state.copyWith(transactions: newList, isLoading: false);
      }
      await _updateTotals();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  // حذف معاملة
  Future<bool> deleteTransaction(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _deleteTransactionUseCase.execute(id);
      state = state.copyWith(
        transactions: state.transactions.where((t) => t.id != id).toList(),
        isLoading: false,
      );
      await _updateTotals();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  // تصفية حسب النوع
  void filterByType(TransactionType? type) {
    state = state.copyWith(selectedType: type);
    loadTransactions();
  }

  // البحث
  void searchTransactions(String query) {
    state = state.copyWith(searchQuery: query);
    if (query.isEmpty) {
      loadTransactions();
    } else {
      final filtered = state.transactions.where((t) {
        final description = t.description?.toLowerCase() ?? '';
        final amount = t.amount.toString();
        return description.contains(query.toLowerCase()) || amount.contains(query);
      }).toList();
      state = state.copyWith(transactions: filtered);
    }
  }

  // تحديث الإجماليات
  Future<void> _updateTotals() async {
    final totalReceipt = await _repository.getTotalReceipt();
    final totalPayment = await _repository.getTotalPayment();
    state = state.copyWith(
      totalReceipt: totalReceipt,
      totalPayment: totalPayment,
    );
  }

  // مسح الخطأ
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// مزود حالة المعاملات
final transactionsProvider = StateNotifierProvider<TransactionsNotifier, TransactionsState>((ref) {
  final get = ref.watch(getTransactionsUseCaseProvider);
  final create = ref.watch(createTransactionUseCaseProvider);
  final update = ref.watch(updateTransactionUseCaseProvider);
  final delete = ref.watch(deleteTransactionUseCaseProvider);
  final repository = ref.watch(transactionRepositoryProvider);
  
  return TransactionsNotifier(get, create, update, delete, repository);
});