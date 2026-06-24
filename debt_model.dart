import 'package:integrated_accounting_system/core/enums/enums.dart';
import 'package:integrated_accounting_system/domain/entities/debt.dart';

class DebtModel extends Debt {
  DebtModel({
    required super.id,
    required super.contactId,
    required super.totalAmount,
    required super.paidAmount,
    required super.currency,
    super.description,
    required super.dueDate,
    required super.status,
    required super.createdAt,
    super.installments = const [],
  });

  // تحويل من Map إلى كائن
  factory DebtModel.fromMap(Map<String, dynamic> map) {
    return DebtModel(
      id: map['id'] ?? '',
      contactId: map['contactId'] ?? '',
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      paidAmount: (map['paidAmount'] ?? 0).toDouble(),
      currency: map['currency'] ?? 'ريال يمني',
      description: map['description'],
      dueDate: DateTime.fromMillisecondsSinceEpoch(map['dueDate'] ?? 0),
      status: DebtStatus.values.firstWhere(
        (e) => e.toString() == 'DebtStatus.${map['status']}',
        orElse: () => DebtStatus.active,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
    );
  }

  // تحويل من كائن إلى Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'contactId': contactId,
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'currency': currency,
      'description': description,
      'dueDate': dueDate.millisecondsSinceEpoch,
      'status': status.toString().split('.').last,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  // تحويل من JSON
  factory DebtModel.fromJson(Map<String, dynamic> json) {
    return DebtModel(
      id: json['id'] ?? '',
      contactId: json['contactId'] ?? '',
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      paidAmount: (json['paidAmount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'ريال يمني',
      description: json['description'],
      dueDate: DateTime.parse(json['dueDate'] ?? DateTime.now().toIso8601String()),
      status: DebtStatus.values.firstWhere(
        (e) => e.toString() == 'DebtStatus.${json['status']}',
        orElse: () => DebtStatus.active,
      ),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  // تحويل إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contactId': contactId,
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'currency': currency,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'status': status.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // نسخ الكائن مع تغييرات
  DebtModel copyWith({
    String? id,
    String? contactId,
    double? totalAmount,
    double? paidAmount,
    String? currency,
    String? description,
    DateTime? dueDate,
    DebtStatus? status,
    DateTime? createdAt,
    List<Installment>? installments,
  }) {
    return DebtModel(
      id: id ?? this.id,
      contactId: contactId ?? this.contactId,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      currency: currency ?? this.currency,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      installments: installments ?? this.installments,
    );
  }
}