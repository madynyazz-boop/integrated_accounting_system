import 'package:integrated_accounting_system/core/enums/enums.dart';

class Transaction {
  final String id;
  final String? contactId;
  final TransactionType type;
  final double amount;
  final String currency;
  final String? description;
  final DateTime date;
  final DateTime createdAt;
  final List<Attachment> attachments;

  Transaction({
    required this.id,
    this.contactId,
    required this.type,
    required this.amount,
    required this.currency,
    this.description,
    required this.date,
    required this.createdAt,
    this.attachments = const [],
  });

  // نسخ الكائن مع تغييرات
  Transaction copyWith({
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
    return Transaction(
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

  // الحصول على اسم النوع بالعربية
  String get typeName {
    switch (type) {
      case TransactionType.receipt:
        return 'قبض';
      case TransactionType.payment:
        return 'صرف';
      case TransactionType.debt:
        return 'دين';
      case TransactionType.settlement:
        return 'تسديد';
      case TransactionType.transfer:
        return 'تحويل';
    }
  }

  // الحصول على أيقونة النوع
  IconData get typeIcon {
    switch (type) {
      case TransactionType.receipt:
        return Icons.arrow_downward;
      case TransactionType.payment:
        return Icons.arrow_upward;
      case TransactionType.debt:
        return Icons.account_balance;
      case TransactionType.settlement:
        return Icons.check_circle;
      case TransactionType.transfer:
        return Icons.swap_horiz;
    }
  }

  // الحصول على لون النوع
  Color get typeColor {
    switch (type) {
      case TransactionType.receipt:
        return Colors.green;
      case TransactionType.payment:
        return Colors.red;
      case TransactionType.debt:
        return Colors.orange;
      case TransactionType.settlement:
        return Colors.blue;
      case TransactionType.transfer:
        return Colors.purple;
    }
  }

  // التحقق من نوع العملية
  bool get isReceipt => type == TransactionType.receipt;
  bool get isPayment => type == TransactionType.payment;
  bool get isDebt => type == TransactionType.debt;
  bool get isSettlement => type == TransactionType.settlement;
  bool get isTransfer => type == TransactionType.transfer;

  // الحصول على قيمة العملية (موجبة أو سالبة)
  double get signedAmount {
    switch (type) {
      case TransactionType.receipt:
        return amount;
      case TransactionType.payment:
        return -amount;
      default:
        return amount;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Transaction && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Transaction(id: $id, type: $type, amount: $amount)';
  }
}

class Attachment {
  final String id;
  final String path;
  final String name;
  final AttachmentType type;
  final DateTime createdAt;

  Attachment({
    required this.id,
    required this.path,
    required this.name,
    required this.type,
    required this.createdAt,
  });

  // الحصول على اسم النوع بالعربية
  String get typeName {
    switch (type) {
      case AttachmentType.image:
        return 'صورة';
      case AttachmentType.pdf:
        return 'PDF';
      case AttachmentType.other:
        return 'ملف';
    }
  }

  // الحصول على أيقونة النوع
  IconData get typeIcon {
    switch (type) {
      case AttachmentType.image:
        return Icons.image;
      case AttachmentType.pdf:
        return Icons.picture_as_pdf;
      case AttachmentType.other:
        return Icons.insert_drive_file;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Attachment && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// استيراد Icons لتجنب الأخطاء
import 'package:flutter/material.dart';