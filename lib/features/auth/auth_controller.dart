import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/auth_user.dart';
import '../../data/repositories/auth_repository.dart';

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<AuthSession?>>((ref) {
      return AuthController(ref.watch(authRepositoryProvider));
    });

class AuthController extends StateNotifier<AsyncValue<AuthSession?>> {
  final AuthRepository _repository;

  AuthController(this._repository) : super(const AsyncValue.loading()) {
    restore();
  }

  Future<void> restore() async {
    state = const AsyncValue.loading();
    final session = await _repository.restoreSession();
    state = AsyncValue.data(session);
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.login(email: email, password: password),
    );
  }

  Future<void> signup({
    required String email,
    required String password,
    required String name,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.signup(email: email, password: password, name: name),
    );
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AsyncValue.data(null);
  }
}
