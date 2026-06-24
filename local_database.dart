import 'package:integrated_accounting_system/database/database_helper.dart';

class LocalDatabase {
  static final LocalDatabase _instance = LocalDatabase._internal();
  factory LocalDatabase() => _instance;
  LocalDatabase._internal();

  // الحصول على قاعدة البيانات
  Future get database => DatabaseHelper().database;

  // إغلاق قاعدة البيانات
  Future<void> close() async {
    await DatabaseHelper().close();
  }
}