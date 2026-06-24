import 'package:intl/intl.dart';
import 'package:integrated_accounting_system/core/constants/app_constants.dart';

class CurrencyUtils {
  static String formatAmount(double amount, {String currency = 'ر.ي'}) {
    final formatter = NumberFormat('#,##0.00', 'ar');
    return '$currency ${formatter.format(amount)}';
  }

  static String formatAmountWithoutCurrency(double amount) {
    final formatter = NumberFormat('#,##0.00', 'ar');
    return formatter.format(amount);
  }

  static String formatAmountSimple(double amount) {
    if (amount == 0) return '0';
    if (amount.truncate() == amount) {
      return amount.toInt().toString();
    }
    return amount.toStringAsFixed(2);
  }

  static String getCurrencySymbol(String currencyName) {
    return AppConstants.currencySymbols[currencyName] ?? currencyName;
  }

  static double parseAmount(String amountString) {
    // إزالة الفواصل والمسافات
    final cleaned = amountString.replaceAll(RegExp(r'[,\s]'), '');
    return double.tryParse(cleaned) ?? 0.0;
  }

  static String getCurrencyNameFromSymbol(String symbol) {
    final entry = AppConstants.currencySymbols.entries
        .firstWhere((entry) => entry.value == symbol, orElse: () => const MapEntry('', ''));
    return entry.key;
  }

  static bool isValidAmount(String amount) {
    if (amount.isEmpty) return false;
    final parsed = double.tryParse(amount.replaceAll(RegExp(r'[,\s]'), ''));
    if (parsed == null) return false;
    return parsed >= 0 && parsed <= 999999999.99;
  }

  static String formatAmountForDisplay(double amount, {bool showSign = false}) {
    String sign = '';
    if (showSign && amount > 0) {
      sign = '+';
    } else if (showSign && amount < 0) {
      sign = '-';
    }
    return '$sign${formatAmountWithoutCurrency(amount.abs())}';
  }

  static double roundToTwoDecimals(double amount) {
    return double.parse(amount.toStringAsFixed(2));
  }
}