import 'package:integrated_accounting_system/core/enums/enums.dart';
import 'package:integrated_accounting_system/data/datasources/local_database.dart';
import 'package:integrated_accounting_system/data/models/debt_model.dart';
import 'package:integrated_accounting_system/domain/entities/debt.dart';
import 'package:integrated_accounting_system/domain/repositories/debt_repository.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

class DebtRepositoryImpl implements DebtRepository {
  final LocalDatabase _localDatabase;
  final Uuid _uuid = const Uuid();

  DebtRepositoryImpl(this._localDatabase);

  @override
  Future<List<Debt>> getDebts({
    String? contactId,
    DebtStatus? status,
  }) async {
    final db = await _localDatabase.database;

    String sql = 'SELECT * FROM debts WHERE 1=1';
    List<dynamic> args = [];

    if (contactId != null) {
      sql += ' AND contactId = ?';
      args.add(contactId);
    }

    if (status != null) {
      sql += ' AND status = ?';
      args.add(status.toString().split('.').last);
    }

    sql += ' ORDER BY dueDate ASC';

    final List<Map<String, dynamic>> maps = await db.rawQuery(sql, args);
    return maps.map((map) => DebtModel.fromMap(map)).toList();
  }

  @override
  Future<Debt> createDebt(Debt debt) async {
    final db = await _localDatabase.database;
    final model = DebtModel(
      id: _uuid.v4(),
      contactId: debt.contactId,
      totalAmount: debt.totalAmount,
      paidAmount: debt.paidAmount,
      currency: debt.currency,
      description: debt.description,
      dueDate: debt.dueDate,
      status: debt.status,
      createdAt: DateTime.now(),
    );

    await db.insert('debts', model.toMap());
    
    // إضافة الأقساط إن وجدت
    for (final installment in debt.installments) {
      await _createInstallment(db, installment, model.id);
    }
    
    return model;
  }

  @override
  Future<Debt> updateDebt(Debt debt) async {
    final db = await _localDatabase.database;
    final model = DebtModel(
      id: debt.id,
      contactId: debt.contactId,
      totalAmount: debt.totalAmount,
      paidAmount: debt.paidAmount,
      currency: debt.currency,
      description: debt.description,
      dueDate: debt.dueDate,
      status: debt.status,
      createdAt: debt.createdAt,
    );

    await db.update(
      'debts',
      model.toMap(),
      where: 'id = ?',
      whereArgs: [debt.id],
    );
    return model;
  }

  @override
  Future<void> deleteDebt(String id) async {
    final db = await _localDatabase.database;
    await db.delete(
      'debts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<Debt?> getDebtById(String id) async {
    final db = await _localDatabase.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'debts',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isNotEmpty) {
      return DebtModel.fromMap(maps.first);
    }
    return null;
  }

  @override
  Future<List<Debt>> getOverdueDebts() async {
    final db = await _localDatabase.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'debts',
      where: 'dueDate < ? AND status != ?',
      whereArgs: [now, 'paid'],
    );
    return maps.map((map) => DebtModel.fromMap(map)).toList();
  }

  @override
  Future<double> getTotalDebts() async {
    final db = await _localDatabase.database;
    final result = await db.rawQuery('''
      SELECT SUM(totalAmount - paidAmount) as total
      FROM debts
      WHERE status != 'paid'
    ''');
    return result.first['total'] as double? ?? 0;
  }

  Future<void> _createInstallment(Database db, Installment installment, String debtId) async {
    await db.insert('installments', {
      'id': _uuid.v4(),
      'debtId': debtId,
      'amount': installment.amount,
      'dueDate': installment.dueDate.millisecondsSinceEpoch,
      'status': installment.status.toString().split('.').last,
      'paidDate': installment.paidDate?.millisecondsSinceEpoch,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
  }
}