import 'package:integrated_accounting_system/domain/entities/debt.dart';
import 'package:integrated_accounting_system/domain/repositories/debt_repository.dart';

class GetOverdueDebtsUseCase {
  final DebtRepository repository;

  GetOverdueDebtsUseCase(this.repository);

  Future<List<Debt>> execute() async {
    return await repository.getOverdueDebts();
  }
}