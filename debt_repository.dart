import 'package:integrated_accounting_system/core/enums/enums.dart';
import 'package:integrated_accounting_system/domain/entities/debt.dart';

abstract class DebtRepository {
  // جلب جميع الديون
  Future<List<Debt>> getDebts({
    String? contactId,
    DebtStatus? status,
  });
  
  // إنشاء دين جديد
  Future<Debt> createDebt(Debt debt);
  
  // تحديث دين
  Future<Debt> updateDebt(Debt debt);
  
  // حذف دين
  Future<void> deleteDebt(String id);
  
  // جلب دين بواسطة المعرف
  Future<Debt?> getDebtById(String id);
  
  // جلب الديون المتأخرة
  Future<List<Debt>> getOverdueDebts();
  
  // الحصول على إجمالي الديون
  Future<double> getTotalDebts();
}