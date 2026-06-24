class Validators {
  static String? validateRequired(String? value, {String fieldName = 'الحقل'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName مطلوب';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return null;
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'البريد الإلكتروني غير صحيح';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) return null;
    final phoneRegex = RegExp(r'^[0-9\-\+\s]{8,15}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'رقم الهاتف غير صحيح';
    }
    return null;
  }

  static String? validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'المبلغ مطلوب';
    }
    final cleaned = value.replaceAll(RegExp(r'[,\s]'), '');
    final amount = double.tryParse(cleaned);
    if (amount == null || amount <= 0) {
      return 'المبلغ يجب أن يكون أكبر من صفر';
    }
    if (amount > 999999999.99) {
      return 'المبلغ كبير جداً';
    }
    return null;
  }

  static String? validateMinLength(String? value, int minLength, {String fieldName = 'الحقل'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName مطلوب';
    }
    if (value.trim().length < minLength) {
      return '$fieldName يجب أن يكون على الأقل $minLength أحرف';
    }
    return null;
  }

  static String? validateMaxLength(String? value, int maxLength, {String fieldName = 'الحقل'}) {
    if (value == null) return null;
    if (value.trim().length > maxLength) {
      return '$fieldName يجب أن لا يتجاوز $maxLength حرف';
    }
    return null;
  }

  static String? validateDate(DateTime? value) {
    if (value == null) {
      return 'التاريخ مطلوب';
    }
    if (value.isAfter(DateTime.now())) {
      return 'لا يمكن اختيار تاريخ مستقبلي';
    }
    return null;
  }

  static String? validateFutureDate(DateTime? value) {
    if (value == null) {
      return 'التاريخ مطلوب';
    }
    if (value.isBefore(DateTime.now())) {
      return 'التاريخ يجب أن يكون في المستقبل';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'كلمة المرور مطلوبة';
    }
    if (value.length < 6) {
      return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
    }
    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'تأكيد كلمة المرور مطلوب';
    }
    if (value != password) {
      return 'كلمة المرور غير متطابقة';
    }
    return null;
  }
}