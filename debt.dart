import 'package:integrated_accounting_system/core/enums/enums.dart';

class Debt {
  final String id;
  final String contactId;
  final double totalAmount;
  final double paidAmount;
  final String currency;
  final String? description;
  final DateTime dueDate;
  final DebtStatus status;
  final DateTime createdAt;
  final List<Installment> installments;

  Debt({
    required this.id,
    required this.contactId,
    required this.totalAmount,
    required this.paidAmount,
    required this.currency,
    this.description,
    required this.dueDate,
    required this.status,
    required this.createdAt,
    this.installments = const [],
  });

  // المبلغ المتبقي
  double get remainingAmount => totalAmount - paidAmount;

  // النسبة المئوية المدفوعة
  double get paidPercentage {
    if (totalAmount == 0) return 0;
    return (paidAmount / totalAmount) * 100;
  }

  // هل الدين مدفوع بالكامل
  bool get isFullyPaid => paidAmount >= totalAmount;

  // هل الدين متأخر
  bool get isOverdue => dueDate.isBefore(DateTime.now()) && status != DebtStatus.paid;

  // نسخ الكائن مع تغييرات
  Debt copyWith({
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
    return Debt(
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

  // الحصول على اسم الحالة بالعربية
  String get statusName {
    switch (status) {
      case DebtStatus.active:
        return 'نشط';
      case DebtStatus.overdue:
        return 'متأخر';
      case DebtStatus.paid:
        return 'مدفوع';
    }
  }

  // الحصول على لون الحالة
  Color get statusColor {
    switch (status) {
      case DebtStatus.active:
        return Colors.blue;
      case DebtStatus.overdue:
        return Colors.red;
      case DebtStatus.paid:
        return Colors.green;
    }
  }

  // الحصول على أيقونة الحالة
  IconData get statusIcon {
    switch (status) {
      case DebtStatus.active:
        return Icons.timer;
      case DebtStatus.overdue:
        return Icons.warning;
      case DebtStatus.paid:
        return Icons.check_circle;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Debt && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Debt(id: $id, totalAmount: $totalAmount, status: $status)';
  }
}

class Installment {
  final String id;
  final String debtId;
  final double amount;
  final DateTime dueDate;
  final InstallmentStatus status;
  final DateTime? paidDate;
  final DateTime createdAt;

  Installment({
    required this.id,
    required this.debtId,
    required this.amount,
    required this.dueDate,
    required this.status,
    this.paidDate,
    required this.createdAt,
  });

  // هل القسط متأخر
  bool get isOverdue => dueDate.isBefore(DateTime.now()) && status != InstallmentStatus.paid;

  // هل القسط مدفوع
  bool get isPaid => status == InstallmentStatus.paid;

  // نسخ الكائن مع تغييرات
  Installment copyWith({
    String? id,
    String? debtId,
    double? amount,
    DateTime? dueDate,
    InstallmentStatus? status,
    DateTime? paidDate,
    DateTime? createdAt,
  }) {
    return Installment(
      id: id ?? this.id,
      debtId: debtId ?? this.debtId,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      paidDate: paidDate ?? this.paidDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // الحصول على اسم الحالة بالعربية
  String get statusName {
    switch (status) {
      case InstallmentStatus.pending:
        return 'معلق';
      case InstallmentStatus.paid:
        return 'مدفوع';
      case InstallmentStatus.overdue:
        return 'متأخر';
    }
  }

  // الحصول على لون الحالة
  Color get statusColor {
    switch (status) {
      case InstallmentStatus.pending:
        return Colors.orange;
      case InstallmentStatus.paid:
        return Colors.green;
      case InstallmentStatus.overdue:
        return Colors.red;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Installment && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}