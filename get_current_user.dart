import 'package:integrated_accounting_system/domain/entities/user.dart';
import 'package:integrated_accounting_system/domain/repositories/auth_repository.dart';

class GetCurrentUserUseCase {
  final AuthRepository repository;

  GetCurrentUserUseCase(this.repository);

  Future<User?> execute() async {
    return await repository.getCurrentUser();
  }
}