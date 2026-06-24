import 'package:integrated_accounting_system/core/enums/enums.dart';
import 'package:integrated_accounting_system/domain/entities/debt.dart';
import 'package:integrated_accounting_system/domain/repositories/debt_repository.dart';

class GetDebtsUseCase {
  final DebtRepository repository;

  GetDebtsUseCase(this.repository);

  Future<List<Debt>> execute({
    String? contactId,
    DebtStatus? status,
  }) async {
    return await repository.getDebts(
      contactId: contactId,
      status: status,
    );
  }
}