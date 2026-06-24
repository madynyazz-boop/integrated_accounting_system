import 'package:integrated_accounting_system/domain/entities/debt.dart';
import 'package:integrated_accounting_system/domain/repositories/debt_repository.dart';

class UpdateDebtUseCase {
  final DebtRepository repository;

  UpdateDebtUseCase(this.repository);

  Future<Debt> execute(Debt debt) async {
    // التحقق من صحة المعرف
    if (debt.id.isEmpty) {
      throw Exception('معرف الدين مطلوب');
    }
    
    // التحقق من صحة المبلغ
    if (debt.totalAmount <= 0) {
      throw Exception('المبلغ يجب أن يكون أكبر من صفر');
    }

    return await repository.updateDebt(debt);
  }
}