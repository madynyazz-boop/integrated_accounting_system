import 'package:integrated_accounting_system/core/enums/enums.dart';
import 'package:integrated_accounting_system/domain/entities/transaction.dart';
import 'package:integrated_accounting_system/domain/repositories/transaction_repository.dart';

class GetTransactionsUseCase {
  final TransactionRepository repository;

  GetTransactionsUseCase(this.repository);

  Future<List<Transaction>> execute({
    DateTime? fromDate,
    DateTime? toDate,
    String? contactId,
    TransactionType? type,
  }) async {
    return await repository.getTransactions(
      fromDate: fromDate,
      toDate: toDate,
      contactId: contactId,
      type: type,
    );
  }
}