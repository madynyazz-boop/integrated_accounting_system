import 'package:flutter_riverpod/flutter_riverpod.dart';

// مزود للغة الحالية
final localeProvider = StateProvider<String>((ref) => 'ar');

// مزود لحالة السمة (داكن/فاتح)
final themeModeProvider = StateProvider<bool>((ref) => false);

// مزود لحالة الاتصال بالإنترنت
final connectivityProvider = StateProvider<bool>((ref) => true);

// مزود لحالة المستخدم الحالي
final currentUserProvider = StateProvider<String?>((ref) => null);

// مزود لحالة التزامن
final syncStatusProvider = StateProvider<bool>((ref) => false);

// مزود لشاشة التحميل
final loadingProvider = StateProvider<bool>((ref) => false);

// مزود للرسائل
final messageProvider = StateProvider<String?>((ref) => null);

// مزود لإعادة تحميل الصفحات
final refreshProvider = StateProvider<bool>((ref) => false);