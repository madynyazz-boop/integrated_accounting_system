import 'package:integrated_accounting_system/core/enums/enums.dart';
import 'package:integrated_accounting_system/domain/entities/transaction.dart';

class AttachmentModel extends Attachment {
  AttachmentModel({
    required super.id,
    required super.path,
    required super.name,
    required super.type,
    required super.createdAt,
  });

  // تحويل من Map إلى كائن
  factory AttachmentModel.fromMap(Map<String, dynamic> map) {
    return AttachmentModel(
      id: map['id'] ?? '',
      path: map['path'] ?? '',
      name: map['name'] ?? '',
      type: AttachmentType.values.firstWhere(
        (e) => e.toString() == 'AttachmentType.${map['type']}',
        orElse: () => AttachmentType.other,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
    );
  }

  // تحويل من كائن إلى Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'path': path,
      'name': name,
      'type': type.toString().split('.').last,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  // تحويل من JSON
  factory AttachmentModel.fromJson(Map<String, dynamic> json) {
    return AttachmentModel(
      id: json['id'] ?? '',
      path: json['path'] ?? '',
      name: json['name'] ?? '',
      type: AttachmentType.values.firstWhere(
        (e) => e.toString() == 'AttachmentType.${json['type']}',
        orElse: () => AttachmentType.other,
      ),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  // تحويل إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'path': path,
      'name': name,
      'type': type.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // نسخ الكائن مع تغييرات
  AttachmentModel copyWith({
    String? id,
    String? path,
    String? name,
    AttachmentType? type,
    DateTime? createdAt,
  }) {
    return AttachmentModel(
      id: id ?? this.id,
      path: path ?? this.path,
      name: name ?? this.name,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}