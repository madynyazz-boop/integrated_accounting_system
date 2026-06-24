import 'package:integrated_accounting_system/core/enums/enums.dart';
import 'package:integrated_accounting_system/domain/entities/transaction.dart';

abstract class TransactionRepository {
  // جلب جميع المعاملات
  Future<List<Transaction>> getTransactions({
    DateTime? fromDate,
    DateTime? toDate,
    String? contactId,
    TransactionType? type,
  });
  
  // إنشاء معاملة جديدة
  Future<Transaction> createTransaction(Transaction transaction);
  
  // تحديث معاملة
  Future<Transaction> updateTransaction(Transaction transaction);
  
  // حذف معاملة
  Future<void> deleteTransaction(String id);
  
  // الحصول على الرصيد الإجمالي
  Future<double> getTotalBalance();
  
  // الحصول على إجمالي القبض
  Future<double> getTotalReceipt();
  
  // الحصول على إجمالي الصرف
  Future<double> getTotalPayment();
  
  // الحصول على أرباح الشهر
  Future<double> getMonthlyProfit(DateTime month);
  
  // الحصول على ملخص يومي
  Future<Map<String, double>> getDailySummary(DateTime date);
  
  // الحصول على بيانات الرسم البياني الشهري
  Future<List<Map<String, dynamic>>> getMonthlyChartData(DateTime year);
}