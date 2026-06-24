import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:integrated_accounting_system/presentation/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Drawer(
      child: Column(
        children: [
          // رأس الدراور
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: Column(
              children: [
                const SizedBox(height: 40),
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  child: user?.imagePath != null
                      ? ClipOval(
                          child: Image.network(
                            user!.imagePath!,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Text(
                          user?.name.isNotEmpty == true ? user!.name[0] : '?',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                ),
                const SizedBox(height: 8),
                Text(
                  user?.name ?? 'مستخدم',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  user?.email ?? '',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // قائمة العناصر
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  context,
                  icon: Icons.dashboard,
                  title: 'الرئيسية',
                  route: '/dashboard',
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.people,
                  title: 'جهات الاتصال',
                  route: '/contacts',
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.receipt_long,
                  title: 'العمليات المالية',
                  route: '/transactions',
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.account_balance,
                  title: 'الديون',
                  route: '/debts',
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.analytics,
                  title: 'التقارير',
                  route: '/reports',
                ),
                const Divider(),
                _buildDrawerItem(
                  context,
                  icon: Icons.settings,
                  title: 'الإعدادات',
                  route: '/settings',
                ),
                const Divider(),
                _buildDrawerItem(
                  context,
                  icon: Icons.logout,
                  title: 'تسجيل الخروج',
                  onTap: () async {
                    await ref.read(authProvider.notifier).signOut();
                    context.go('/login');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? route,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap ?? () {
        Navigator.pop(context);
        if (route != null) {
          context.go(route);
        }
      },
    );
  }
}