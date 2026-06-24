import 'package:integrated_accounting_system/core/enums/enums.dart';
import 'package:integrated_accounting_system/domain/entities/contact.dart';

class ContactModel extends Contact {
  ContactModel({
    required super.id,
    required super.type,
    required super.name,
    super.phone,
    super.whatsapp,
    super.email,
    super.address,
    super.imagePath,
    super.notes,
    required super.createdAt,
  });

  // تحويل من Map إلى كائن
  factory ContactModel.fromMap(Map<String, dynamic> map) {
    return ContactModel(
      id: map['id'] ?? '',
      type: map['type'] == 'customer' ? ContactType.customer : ContactType.supplier,
      name: map['name'] ?? '',
      phone: map['phone'],
      whatsapp: map['whatsapp'],
      email: map['email'],
      address: map['address'],
      imagePath: map['imagePath'],
      notes: map['notes'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
    );
  }

  // تحويل من كائن إلى Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type == ContactType.customer ? 'customer' : 'supplier',
      'name': name,
      'phone': phone,
      'whatsapp': whatsapp,
      'email': email,
      'address': address,
      'imagePath': imagePath,
      'notes': notes,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  // تحويل من JSON
  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      id: json['id'] ?? '',
      type: json['type'] == 'customer' ? ContactType.customer : ContactType.supplier,
      name: json['name'] ?? '',
      phone: json['phone'],
      whatsapp: json['whatsapp'],
      email: json['email'],
      address: json['address'],
      imagePath: json['imagePath'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  // تحويل إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type == ContactType.customer ? 'customer' : 'supplier',
      'name': name,
      'phone': phone,
      'whatsapp': whatsapp,
      'email': email,
      'address': address,
      'imagePath': imagePath,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // نسخ الكائن مع تغييرات
  ContactModel copyWith({
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
    return ContactModel(
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
}