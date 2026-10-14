import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../models/user.dart';

class AuthState {
  final AppUser? user;
  final bool loading;
  final String? error;

  const AuthState({this.user, this.loading = false, this.error});
}

class AuthViewModel extends Notifier<AuthState> {
  @override
  AuthState build() {
    Future.microtask(_restore);
    return const AuthState(loading: true);
  }

  Future<void> _restore() async {
    try {
      final profile = await ref.read(apiClientProvider).myProfile();
      state = AuthState(user: profile == null ? null : AppUser.fromJson(profile));
    } catch (_) {
      state = const AuthState();
    }
  }

  Future<void> login(String email, String password) async {
    state = const AuthState(loading: true);
    try {
      await ref.read(apiClientProvider).signIn(email, password);
      await _restore();
      ref.read(runRepositoryProvider).syncPending();
    } catch (e) {
      state = AuthState(error: e.toString());
    }
  }

  Future<void> logout() async {
    await ref.read(apiClientProvider).signOut();
    state = const AuthState();
  }
}

final authViewModelProvider = NotifierProvider<AuthViewModel, AuthState>(AuthViewModel.new);
