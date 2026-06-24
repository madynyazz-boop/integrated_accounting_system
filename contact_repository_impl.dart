import 'package:integrated_accounting_system/core/enums/enums.dart';
import 'package:integrated_accounting_system/data/datasources/local_database.dart';
import 'package:integrated_accounting_system/data/models/contact_model.dart';
import 'package:integrated_accounting_system/domain/entities/contact.dart';
import 'package:integrated_accounting_system/domain/repositories/contact_repository.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

class ContactRepositoryImpl implements ContactRepository {
  final LocalDatabase _localDatabase;
  final Uuid _uuid = const Uuid();

  ContactRepositoryImpl(this._localDatabase);

  @override
  Future<List<Contact>> getContacts({ContactType? type}) async {
    final db = await _localDatabase.database;
    
    String sql = 'SELECT * FROM contacts';
    List<dynamic> args = [];
    
    if (type != null) {
      sql += ' WHERE type = ?';
      args.add(type == ContactType.customer ? 'customer' : 'supplier');
    }
    
    sql += ' ORDER BY name ASC';
    
    final List<Map<String, dynamic>> maps = await db.rawQuery(sql, args);
    return maps.map((map) => ContactModel.fromMap(map)).toList();
  }

  @override
  Future<Contact> createContact(Contact contact) async {
    final db = await _localDatabase.database;
    final model = ContactModel(
      id: _uuid.v4(),
      type: contact.type,
      name: contact.name,
      phone: contact.phone,
      whatsapp: contact.whatsapp,
      email: contact.email,
      address: contact.address,
      imagePath: contact.imagePath,
      notes: contact.notes,
      createdAt: DateTime.now(),
    );

    await db.insert('contacts', model.toMap());
    return model;
  }

  @override
  Future<Contact> updateContact(Contact contact) async {
    final db = await _localDatabase.database;
    final model = ContactModel(
      id: contact.id,
      type: contact.type,
      name: contact.name,
      phone: contact.phone,
      whatsapp: contact.whatsapp,
      email: contact.email,
      address: contact.address,
      imagePath: contact.imagePath,
      notes: contact.notes,
      createdAt: contact.createdAt,
    );

    await db.update(
      'contacts',
      model.toMap(),
      where: 'id = ?',
      whereArgs: [contact.id],
    );
    return model;
  }

  @override
  Future<void> deleteContact(String id) async {
    final db = await _localDatabase.database;
    await db.delete(
      'contacts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<Contact?> getContactById(String id) async {
    final db = await _localDatabase.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'contacts',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isNotEmpty) {
      return ContactModel.fromMap(maps.first);
    }
    return null;
  }

  @override
  Future<List<Contact>> searchContacts(String query) async {
    final db = await _localDatabase.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'contacts',
      where: 'name LIKE ? OR phone LIKE ? OR email LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
    );
    return maps.map((map) => ContactModel.fromMap(map)).toList();
  }

  @override
  Future<int> getContactsCount({ContactType? type}) async {
    final db = await _localDatabase.database;
    String sql = 'SELECT COUNT(*) as count FROM contacts';
    List<dynamic> args = [];
    
    if (type != null) {
      sql += ' WHERE type = ?';
      args.add(type == ContactType.customer ? 'customer' : 'supplier');
    }
    
    final result = await db.rawQuery(sql, args);
    return result.first['count'] as int? ?? 0;
  }
}