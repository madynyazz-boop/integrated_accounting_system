import 'package:integrated_accounting_system/core/enums/enums.dart';

class Contact {
  final String id;
  final ContactType type;
  final String name;
  final String? phone;
  final String? whatsapp;
  final String? email;
  final String? address;
  final String? imagePath;
  final String? notes;
  final DateTime createdAt;

  Contact({
    required this.id,
    required this.type,
    required this.name,
    this.phone,
    this.whatsapp,
    this.email,
    this.address,
    this.imagePath,
    this.notes,
    required this.createdAt,
  });

  // نسخ الكائن مع تغييرات
  Contact copyWith({
    String? id,
    ContactType? type,
    String? name,
    String? phone,
    String? whatsapp,
    String? email,
    String? address,
    String? imagePath,
    String? notes,
    DateTime? createdAt,
  }) {
    return Contact(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      whatsapp: whatsapp ?? this.whatsapp,
      email: email ?? this.email,
      address: address ?? this.address,
      imagePath: imagePath ?? this.imagePath,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // الحصول على اسم النوع بالعربية
  String get typeName {
    return type == ContactType.customer ? 'عميل' : 'مورد';
  }

  // الحصول على أيقونة النوع
  String get typeIcon {
    return type == ContactType.customer ? '👤' : '🏢';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Contact && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Contact(id: $id, name: $name, type: $type)';
  }
}