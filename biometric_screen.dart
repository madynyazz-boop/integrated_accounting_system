import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:integrated_accounting_system/core/widgets/custom_button.dart';

class BiometricScreen extends ConsumerStatefulWidget {
  final VoidCallback onSuccess;
  final VoidCallback? onCancel;

  const BiometricScreen({
    super.key,
    required this.onSuccess,
    this.onCancel,
  });

  @override
  ConsumerState<BiometricScreen> createState() => _BiometricScreenState();
}

class _BiometricScreenState extends ConsumerState<BiometricScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isAuthenticating = false;
  bool _isSupported = false;
  List<BiometricType> _availableBiometrics = [];

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    try {
      final isSupported = await _localAuth.isDeviceSupported();
      final available = await _localAuth.getAvailableBiometrics();
      
      setState(() {
        _isSupported = isSupported;
        _availableBiometrics = available;
      });
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
    });

    try {
      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: 'الرجاء استخدام المصادقة البيومترية للوصول إلى التطبيق',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      setState(() {
        _isAuthenticating = false;
      });

      if (isAuthenticated) {
        widget.onSuccess();
      }
    } catch (e) {
      setState(() {
        _isAuthenticating = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل المصادقة: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getBiometricTypeName(BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return 'البصمة الوجهية';
      case BiometricType.fingerprint:
        return 'بصمة الإصبع';
      case BiometricType.iris:
        return 'بصمة العين';
      default:
        return 'غير معروف';
    }
  }

  IconData _getBiometricIcon(BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return Icons.face;
      case BiometricType.fingerprint:
        return Icons.fingerprint;
      case BiometricType.iris:
        return Icons.remove_red_eye;
      default:
        return Icons.security;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // أيقونة المصادقة
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor.withOpacity(0.1),
                      Theme.of(context).primaryColor.withOpacity(0.05),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.fingerprint,
                  size: 60,
                  color: _isAuthenticating 
                      ? Colors.grey[400] 
                      : Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 32),

              // العنوان
              Text(
                'المصادقة البيومترية',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'استخدم بصمتك أو التعرف على الوجه للدخول',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),

              // حالة المصادقة
              if (_isAuthenticating) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'جاري المصادقة...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 32),
              ],

              // البصمات المتاحة
              if (_availableBiometrics.isNotEmpty && !_isAuthenticating) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: _availableBiometrics.map((type) {
                      return ListTile(
                        leading: Icon(
                          _getBiometricIcon(type),
                          color: Theme.of(context).primaryColor,
                        ),
                        title: Text(_getBiometricTypeName(type)),
                        trailing: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 20,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 32),
              ],

              // زر المصادقة
              CustomButton(
                text: _isAuthenticating 
                    ? 'جاري المصادقة...' 
                    : 'المصادقة الآن',
                onPressed: _authenticate,
                isLoading: _isAuthenticating,
                icon: Icons.fingerprint,
              ),
              const SizedBox(height: 16),

              // زر الإلغاء
              OutlinedButton(
                onPressed: widget.onCancel ?? () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('إلغاء'),
              ),

              // رسالة إذا لم تكن البصمة مدعومة
              if (!_isSupported && !_isAuthenticating) ...[
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning,
                        color: Colors.orange[700],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'جهازك لا يدعم المصادقة البيومترية',
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}