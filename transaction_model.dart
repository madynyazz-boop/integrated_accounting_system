import 'package:integrated_accounting_system/core/enums/enums.dart';
import 'package:integrated_accounting_system/domain/entities/transaction.dart';

class TransactionModel extends Transaction {
  TransactionModel({
    required super.id,
    super.contactId,
    required super.type,
    required super.amount,
    required super.currency,
    super.description,
    required super.date,
    required super.createdAt,
    super.attachments = const [],
  });

  // تحويل من Map إلى كائن
  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] ?? '',
      contactId: map['contactId'],
      type: TransactionType.values.firstWhere(
        (e) => e.toString() == 'TransactionType.${map['type']}',
        orElse: () => TransactionType.receipt,
      ),
      amount: (map['amount'] ?? 0).toDouble(),
      currency: map['currency'] ?? 'ريال يمني',
      description: map['description'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] ?? 0),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
    );
  }

  // تحويل من كائن إلى Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'contactId': contactId,
      'type': type.toString().split('.').last,
      'amount': amount,
      'currency': currency,
      'description': description,
      'date': date.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  // تحويل من JSON
  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] ?? '',
      contactId: json['contactId'],
      type: TransactionType.values.firstWhere(
        (e) => e.toString() == 'TransactionType.${json['type']}',
        orElse: () => TransactionType.receipt,
      ),
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'ريال يمني',
      description: json['description'],
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  // تحويل إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contactId': contactId,
      'type': type.toString().split('.').last,
      'amount': amount,
      'currency': currency,
      'description': description,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // نسخ الكائن مع تغييرات
  TransactionModel copyWith({
    String? id,
    String? contactId,
    TransactionType? type,
    double? amount,
    String? currency,
    String? description,
    DateTime? date,
    DateTime? createdAt,
    List<Attachment>? attachments,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      contactId: contactId ?? this.contactId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      description: description ?? this.description,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      attachments: attachments ?? this.attachments,
    );
  }
}