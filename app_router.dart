import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// هذه الملفات ستُنشأ لاحقاً
import 'package:integrated_accounting_system/presentation/screens/auth/login_screen.dart';
import 'package:integrated_accounting_system/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:integrated_accounting_system/presentation/screens/contacts/contacts_screen.dart';
import 'package:integrated_accounting_system/presentation/screens/transactions/transactions_screen.dart';
import 'package:integrated_accounting_system/presentation/screens/debts/debts_screen.dart';
import 'package:integrated_accounting_system/presentation/screens/reports/reports_screen.dart';
import 'package:integrated_accounting_system/presentation/screens/settings/settings_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/dashboard',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
        routes: [
          GoRoute(
            path: 'contacts',
            builder: (context, state) => const ContactsScreen(),
          ),
          GoRoute(
            path: 'transactions',
            builder: (context, state) => const TransactionsScreen(),
          ),
          GoRoute(
            path: 'debts',
            builder: (context, state) => const DebtsScreen(),
          ),
          GoRoute(
            path: 'reports',
            builder: (context, state) => const ReportsScreen(),
          ),
          GoRoute(
            path: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
});