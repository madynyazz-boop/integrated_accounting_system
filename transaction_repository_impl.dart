import 'package:integrated_accounting_system/core/enums/enums.dart';
import 'package:integrated_accounting_system/data/datasources/local_database.dart';
import 'package:integrated_accounting_system/data/models/transaction_model.dart';
import 'package:integrated_accounting_system/domain/entities/transaction.dart';
import 'package:integrated_accounting_system/domain/repositories/transaction_repository.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final LocalDatabase _localDatabase;
  final Uuid _uuid = const Uuid();

  TransactionRepositoryImpl(this._localDatabase);

  @override
  Future<List<Transaction>> getTransactions({
    DateTime? fromDate,
    DateTime? toDate,
    String? contactId,
    TransactionType? type,
  }) async {
    final db = await _localDatabase.database;

    String sql = 'SELECT * FROM transactions WHERE 1=1';
    List<dynamic> args = [];

    if (fromDate != null) {
      sql += ' AND date >= ?';
      args.add(fromDate.millisecondsSinceEpoch);
    }

    if (toDate != null) {
      sql += ' AND date <= ?';
      args.add(toDate.millisecondsSinceEpoch);
    }

    if (contactId != null) {
      sql += ' AND contactId = ?';
      args.add(contactId);
    }

    if (type != null) {
      sql += ' AND type = ?';
      args.add(type.toString().split('.').last);
    }

    sql += ' ORDER BY date DESC';

    final List<Map<String, dynamic>> maps = await db.rawQuery(sql, args);
    return maps.map((map) => TransactionModel.fromMap(map)).toList();
  }

  @override
  Future<Transaction> createTransaction(Transaction transaction) async {
    final db = await _localDatabase.database;
    final model = TransactionModel(
      id: _uuid.v4(),
      contactId: transaction.contactId,
      type: transaction.type,
      amount: transaction.amount,
      currency: transaction.currency,
      description: transaction.description,
      date: transaction.date,
      createdAt: DateTime.now(),
    );

    await db.insert('transactions', model.toMap());
    await _addAuditLog(db, 'create', 'transaction', model.id);
    return model;
  }

  @override
  Future<Transaction> updateTransaction(Transaction transaction) async {
    final db = await _localDatabase.database;
    final model = TransactionModel(
      id: transaction.id,
      contactId: transaction.contactId,
      type: transaction.type,
      amount: transaction.amount,
      currency: transaction.currency,
      description: transaction.description,
      date: transaction.date,
      createdAt: transaction.createdAt,
    );

    await db.update(
      'transactions',
      model.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );

    await _addAuditLog(db, 'update', 'transaction', model.id);
    return model;
  }

  @override
  Future<void> deleteTransaction(String id) async {
    final db = await _localDatabase.database;
    await _addAuditLog(db, 'delete', 'transaction', id);
    await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<double> getTotalBalance() async {
    final db = await _localDatabase.database;
    final result = await db.rawQuery('''
      SELECT 
        SUM(CASE WHEN type = 'receipt' THEN amount ELSE 0 END) as totalReceipt,
        SUM(CASE WHEN type = 'payment' THEN amount ELSE 0 END) as totalPayment
      FROM transactions
    ''');

    final receipt = result.first['totalReceipt'] as double? ?? 0;
    final payment = result.first['totalPayment'] as double? ?? 0;
    return receipt - payment;
  }

  @override
  Future<double> getTotalReceipt() async {
    final db = await _localDatabase.database;
    final result = await db.rawQuery('''
      SELECT SUM(amount) as total
      FROM transactions
      WHERE type = 'receipt'
    ''');
    return result.first['total'] as double? ?? 0;
  }

  @override
  Future<double> getTotalPayment() async {
    final db = await _localDatabase.database;
    final result = await db.rawQuery('''
      SELECT SUM(amount) as total
      FROM transactions
      WHERE type = 'payment'
    ''');
    return result.first['total'] as double? ?? 0;
  }

  @override
  Future<double> getMonthlyProfit(DateTime month) async {
    final db = await _localDatabase.database;
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0);

    final result = await db.rawQuery('''
      SELECT 
        SUM(CASE WHEN type = 'receipt' THEN amount ELSE 0 END) as totalReceipt,
        SUM(CASE WHEN type = 'payment' THEN amount ELSE 0 END) as totalPayment
      FROM transactions
      WHERE date >= ? AND date <= ?
    ''', [
      startOfMonth.millisecondsSinceEpoch,
      endOfMonth.millisecondsSinceEpoch,
    ]);

    final receipt = result.first['totalReceipt'] as double? ?? 0;
    final payment = result.first['totalPayment'] as double? ?? 0;
    return receipt - payment;
  }

  @override
  Future<Map<String, double>> getDailySummary(DateTime date) async {
    final db = await _localDatabase.database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final result = await db.rawQuery('''
      SELECT 
        SUM(CASE WHEN type = 'receipt' THEN amount ELSE 0 END) as totalReceipt,
        SUM(CASE WHEN type = 'payment' THEN amount ELSE 0 END) as totalPayment
      FROM transactions
      WHERE date >= ? AND date <= ?
    ''', [
      startOfDay.millisecondsSinceEpoch,
      endOfDay.millisecondsSinceEpoch,
    ]);

    return {
      'receipt': result.first['totalReceipt'] as double? ?? 0,
      'payment': result.first['totalPayment'] as double? ?? 0,
    };
  }

  @override
  Future<List<Map<String, dynamic>>> getMonthlyChartData(DateTime year) async {
    final db = await _localDatabase.database;
    final List<Map<String, dynamic>> data = [];

    for (int month = 1; month <= 12; month++) {
      final startOfMonth = DateTime(year.year, month, 1);
      final endOfMonth = DateTime(year.year, month + 1, 0);

      final result = await db.rawQuery('''
        SELECT 
          SUM(CASE WHEN type = 'receipt' THEN amount ELSE 0 END) as totalReceipt,
          SUM(CASE WHEN type = 'payment' THEN amount ELSE 0 END) as totalPayment
        FROM transactions
        WHERE date >= ? AND date <= ?
      ''', [
        startOfMonth.millisecondsSinceEpoch,
        endOfMonth.millisecondsSinceEpoch,
      ]);

      data.add({
        'month': month,
        'receipt': result.first['totalReceipt'] as double? ?? 0,
        'payment': result.first['totalPayment'] as double? ?? 0,
        'profit': (result.first['totalReceipt'] as double? ?? 0) - 
                  (result.first['totalPayment'] as double? ?? 0),
      });
    }

    return data;
  }

  Future<void> _addAuditLog(Database db, String action, String entityType, String entityId) async {
    await db.insert('audit_logs', {
      'id': _uuid.v4(),
      'action': action,
      'entityType': entityType,
      'entityId': entityId,
      'userId': 'current_user_id', // سيتم استبداله بالمستخدم الحالي
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
  }
}