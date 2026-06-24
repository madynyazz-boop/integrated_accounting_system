import 'package:integrated_accounting_system/domain/entities/transaction.dart';
import 'package:integrated_accounting_system/domain/repositories/transaction_repository.dart';

class UpdateTransactionUseCase {
  final TransactionRepository repository;

  UpdateTransactionUseCase(this.repository);

  Future<Transaction> execute(Transaction transaction) async {
    // التحقق من صحة المعرف
    if (transaction.id.isEmpty) {
      throw Exception('معرف العملية مطلوب');
    }
    
    // التحقق من صحة المبلغ
    if (transaction.amount <= 0) {
      throw Exception('المبلغ يجب أن يكون أكبر من صفر');
    }

    return await repository.updateTransaction(transaction);
  }
}