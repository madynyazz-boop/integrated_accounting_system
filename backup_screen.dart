import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:integrated_accounting_system/core/widgets/custom_button.dart';

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _isLoading = false;
  bool _autoBackup = true;
  String _lastBackup = '2024-01-15 10:30';
  String _backupSize = '2.4 MB';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('النسخ الاحتياطي'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // معلومات النسخ الاحتياطي
            Card(
              elevation: 2,
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'النسخ الاحتياطي',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.calendar_today, 'آخر نسخ احتياطي', _lastBackup),
                    _buildInfoRow(Icons.storage, 'حجم النسخة', _backupSize),
                    _buildInfoRow(Icons.cloud, 'عدد النسخ', '3 نسخ'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // خيارات النسخ الاحتياطي
            Card(
              elevation: 2,
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'خيارات النسخ الاحتياطي',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    SwitchListTile(
                      title: const Text('النسخ الاحتياطي التلقائي'),
                      subtitle: const Text('إنشاء نسخ احتياطية تلقائياً بشكل دوري'),
                      value: _autoBackup,
                      onChanged: (value) {
                        setState(() {
                          _autoBackup = value;
                        });
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.cloud_upload),
                      title: const Text('المزامنة مع السحابة'),
                      subtitle: const Text('مزامنة البيانات مع السحابة'),
                      trailing: Switch(
                        value: true,
                        onChanged: (value) {},
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.schedule),
                      title: const Text('جدولة النسخ الاحتياطي'),
                      subtitle: const Text('كل يوم'),
                      trailing: DropdownButton<String>(
                        value: 'يومي',
                        items: const [
                          DropdownMenuItem(value: 'يومي', child: Text('يومي')),
                          DropdownMenuItem(value: 'أسبوعي', child: Text('أسبوعي')),
                          DropdownMenuItem(value: 'شهري', child: Text('شهري')),
                        ],
                        onChanged: (value) {},
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // أزرار الإجراءات
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'إنشاء نسخة احتياطية',
                    onPressed: _createBackup,
                    isLoading: _isLoading,
                    icon: Icons.backup,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'استعادة نسخة',
                    onPressed: _restoreBackup,
                    isOutlined: true,
                    icon: Icons.restore,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    text: 'حذف النسخ القديمة',
                    onPressed: _deleteOldBackups,
                    isOutlined: true,
                    icon: Icons.delete_sweep,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // قائمة النسخ الاحتياطية
            const Text(
              'النسخ الاحتياطية المتاحة',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildBackupItem(
              'نسخة 1',
              '2024-01-15 10:30',
              '2.4 MB',
              true,
            ),
            _buildBackupItem(
              'نسخة 2',
              '2024-01-14 10:30',
              '2.3 MB',
              false,
            ),
            _buildBackupItem(
              'نسخة 3',
              '2024-01-13 10:30',
              '2.3 MB',
              false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 12),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupItem(String name, String date, String size, bool isLatest) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(
          Icons.backup,
          color: isLatest ? Colors.green : Colors.grey,
        ),
        title: Text(
          name,
          style: TextStyle(
            fontWeight: isLatest ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(date),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              size,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(width: 8),
            if (isLatest)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'الأحدث',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 10,
                  ),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.more_vert, size: 18),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  void _createBackup() async {
    setState(() => _isLoading = true);

    try {
      // تنفيذ إنشاء النسخ الاحتياطي
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إنشاء النسخة الاحتياطية بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _lastBackup = DateTime.now().toString().substring(0, 16);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _restoreBackup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('استعادة النسخة الاحتياطية'),
        content: const Text(
          'سيتم استعادة البيانات من النسخة الاحتياطية. سيتم استبدال جميع البيانات الحالية. هل أنت متأكد؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم استعادة البيانات بنجاح'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('استعادة'),
          ),
        ],
      ),
    );
  }

  void _deleteOldBackups() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف النسخ القديمة'),
        content: const Text('سيتم حذف جميع النسخ الاحتياطية القديمة باستثناء أحدث نسخة. هل أنت متأكد؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم حذف النسخ القديمة بنجاح'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}