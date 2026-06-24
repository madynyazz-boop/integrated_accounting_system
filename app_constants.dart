class AppConstants {
  static const String appName = 'النظام المتكامل للحسابات';
  static const String appNameEn = 'Integrated Accounting System';
  static const String databaseName = 'accounting.db';
  static const int databaseVersion = 1;

  // قائمة العملات المدعومة
  static const List<String> currencies = [
    'ريال يمني',
    'ريال سعودي',
    'دولار أمريكي',
    'يورو',
  ];

  // رموز العملات
  static const Map<String, String> currencySymbols = {
    'ريال يمني': 'ر.ي',
    'ريال سعودي': 'ر.س',
    'دولار أمريكي': '\$',
    'يورو': '€',
  };

  // أنواع العمليات
  static const List<String> transactionTypes = [
    'قبض',
    'صرف',
    'دين',
    'تسديد',
    'تحويل',
  ];

  // أيقونات أنواع العمليات
  static const Map<String, String> transactionTypeIcons = {
    'قبض': 'arrow_downward',
    'صرف': 'arrow_upward',
    'دين': 'account_balance',
    'تسديد': 'check_circle',
    'تحويل': 'swap_horiz',
  };

  // الألوان حسب نوع العملية
  static const Map<String, int> transactionTypeColors = {
    'قبض': 0xFF4CAF50,  // أخضر
    'صرف': 0xFFF44336,  // أحمر
    'دين': 0xFFFF9800,  // برتقالي
    'تسديد': 0xFF2196F3, // أزرق
    'تحويل': 0xFF9C27B0, // بنفسجي
  };

  // المفاتيح المستخدمة في SharedPreferences
  static const String prefUserKey = 'current_user';
  static const String prefThemeKey = 'theme_mode';
  static const String prefLanguageKey = 'language';
  static const String prefLastSyncKey = 'last_sync';

  // حدود التطبيق
  static const int maxAttachments = 10;
  static const int maxDescriptionLength = 500;
  static const double minTransactionAmount = 0.01;
  static const double maxTransactionAmount = 999999999.99;
}