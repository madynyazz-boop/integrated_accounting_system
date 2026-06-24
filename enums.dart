enum ContactType { 
  customer, // عميل
  supplier  // مورد
}

enum TransactionType {
  receipt,    // قبض
  payment,    // صرف
  debt,       // دين
  settlement, // تسديد
  transfer    // تحويل
}

enum DebtStatus { 
  active,   // نشط
  overdue,  // متأخر
  paid      // مدفوع
}

enum InstallmentStatus { 
  pending,  // معلق
  paid,     // مدفوع
  overdue   // متأخر
}

enum AttachmentType { 
  image, // صورة
  pdf,   // ملف PDF
  other  // ملفات أخرى
}

enum ReportType {
  daily,   // يومي
  weekly,  // أسبوعي
  monthly, // شهري
  yearly   // سنوي
}

enum SyncStatus {
  synced,     // متزامن
  pending,    // معلق
  failed,     // فشل
  inProgress  // جاري
}