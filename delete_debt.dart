import 'package:integrated_accounting_system/domain/repositories/debt_repository.dart';

class DeleteDebtUseCase {
  final DebtRepository repository;

  DeleteDebtUseCase(this.repository);

  Future<void> execute(String id) async {
    // التحقق من صحة المعرف
    if (id.isEmpty) {
      throw Exception('معرف الدين مطلوب');
    }
    
    await repository.deleteDebt(id);
  }
}