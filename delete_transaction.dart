import 'package:integrated_accounting_system/domain/repositories/transaction_repository.dart';

class DeleteTransactionUseCase {
  final TransactionRepository repository;

  DeleteTransactionUseCase(this.repository);

  Future<void> execute(String id) async {
    // التحقق من صحة المعرف
    if (id.isEmpty) {
      throw Exception('معرف العملية مطلوب');
    }
    
    await repository.deleteTransaction(id);
  }
}