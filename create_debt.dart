import 'package:integrated_accounting_system/core/enums/enums.dart';
import 'package:integrated_accounting_system/domain/entities/debt.dart';
import 'package:integrated_accounting_system/domain/repositories/debt_repository.dart';

class CreateDebtUseCase {
  final DebtRepository repository;

  CreateDebtUseCase(this.repository);

  Future<Debt> execute({
    required String contactId,
    required double totalAmount,
    required String currency,
    String? description,
    required DateTime dueDate,
    List<Installment>? installments,
  }) async {
    // التحقق من صحة المبلغ
    if (totalAmount <= 0) {
      throw Exception('المبلغ يجب أن يكون أكبر من صفر');
    }
    
    // التحقق من صحة التاريخ
    if (dueDate.isBefore(DateTime.now())) {
      throw Exception('تاريخ الاستحقاق يجب أن يكون في المستقبل');
    }

    // إنشاء كائن Debt
    final debt = Debt(
      id: '', // سيتم إنشاؤه في المستودع
      contactId: contactId,
      totalAmount: totalAmount,
      paidAmount: 0,
      currency: currency,
      description: description,
      dueDate: dueDate,
      status: DebtStatus.active,
      createdAt: DateTime.now(),
      installments: installments ?? [],
    );

    return await repository.createDebt(debt);
  }
}