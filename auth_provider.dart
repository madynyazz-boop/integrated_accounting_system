import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:integrated_accounting_system/data/repositories/auth_repository_impl.dart';
import 'package:integrated_accounting_system/data/datasources/firebase_datasource.dart';
import 'package:integrated_accounting_system/domain/entities/user.dart';
import 'package:integrated_accounting_system/domain/usecases/auth/sign_in.dart';
import 'package:integrated_accounting_system/domain/usecases/auth/sign_up.dart';
import 'package:integrated_accounting_system/domain/usecases/auth/sign_out.dart';
import 'package:integrated_accounting_system/domain/usecases/auth/reset_password.dart';
import 'package:integrated_accounting_system/domain/usecases/auth/get_current_user.dart';

// مزود المصادر
final firebaseDataSourceProvider = Provider<FirebaseDataSource>((ref) {
  return FirebaseDataSource();
});

// مزود المستودع
final authRepositoryProvider = Provider<AuthRepositoryImpl>((ref) {
  final dataSource = ref.watch(firebaseDataSourceProvider);
  return AuthRepositoryImpl(dataSource);
});

// مزود حالات الاستخدام
final signInUseCaseProvider = Provider<SignInUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SignInUseCase(repository);
});

final signUpUseCaseProvider = Provider<SignUpUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SignUpUseCase(repository);
});

final signOutUseCaseProvider = Provider<SignOutUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SignOutUseCase(repository);
});

final resetPasswordUseCaseProvider = Provider<ResetPasswordUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return ResetPasswordUseCase(repository);
});

final getCurrentUserUseCaseProvider = Provider<GetCurrentUserUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return GetCurrentUserUseCase(repository);
});

// حالة المصادقة
class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;

  AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

// Notifier للمصادقة
class AuthNotifier extends StateNotifier<AuthState> {
  final SignInUseCase _signInUseCase;
  final SignUpUseCase _signUpUseCase;
  final SignOutUseCase _signOutUseCase;
  final ResetPasswordUseCase _resetPasswordUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;

  AuthNotifier(
    this._signInUseCase,
    this._signUpUseCase,
    this._signOutUseCase,
    this._resetPasswordUseCase,
    this._getCurrentUserUseCase,
  ) : super(AuthState()) {
    _checkAuthStatus();
  }

  // التحقق من حالة المصادقة
  Future<void> _checkAuthStatus() async {
    try {
      final user = await _getCurrentUserUseCase.execute();
      state = state.copyWith(
        user: user,
        isAuthenticated: user != null,
      );
    } catch (e) {
      state = state.copyWith(
        isAuthenticated: false,
        error: e.toString(),
      );
    }
  }

  // تسجيل الدخول
  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _signInUseCase.execute(email, password);
      state = state.copyWith(
        user: user,
        isAuthenticated: true,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  // إنشاء حساب جديد
  Future<bool> signUp(String email, String password, String name, {String? phone}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _signUpUseCase.execute(
        email: email,
        password: password,
        name: name,
        phone: phone,
      );
      state = state.copyWith(
        user: user,
        isAuthenticated: true,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  // تسجيل الخروج
  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    try {
      await _signOutUseCase.execute();
      state = state.copyWith(
        user: null,
        isAuthenticated: false,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // إعادة تعيين كلمة المرور
  Future<bool> resetPassword(String email) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _resetPasswordUseCase.execute(email);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  // تحديث حالة المستخدم
  void updateUser(User user) {
    state = state.copyWith(user: user);
  }

  // مسح الخطأ
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// مزود حالة المصادقة
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final signIn = ref.watch(signInUseCaseProvider);
  final signUp = ref.watch(signUpUseCaseProvider);
  final signOut = ref.watch(signOutUseCaseProvider);
  final resetPassword = ref.watch(resetPasswordUseCaseProvider);
  final getCurrentUser = ref.watch(getCurrentUserUseCaseProvider);
  
  return AuthNotifier(
    signIn,
    signUp,
    signOut,
    resetPassword,
    getCurrentUser,
  );
});