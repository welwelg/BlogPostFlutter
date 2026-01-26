import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repository/auth_repository.dart';

// 1. Provider for the Repository (Dependency Injection)
final authRepositoryProvider = Provider((ref) {
  return AuthRepository(Supabase.instance.client);
});

// 2. Stream Provider to listen to Auth State Changes (Login/Logout events)
// This is the MAGIC part. It automatically updates the UI when auth state changes.
final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

// 3. Controller for UI actions
final authControllerProvider = StateNotifierProvider<AuthController, bool>((ref) {
  return AuthController(authRepository: ref.watch(authRepositoryProvider));
});

class AuthController extends StateNotifier<bool> {
  final AuthRepository _authRepository;

  // 'state' here is a boolean: true = loading, false = idle
  AuthController({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(false); 

  Future<void> signUp(String email, String password, String name) async {
    state = true; // Set loading to true
    try {
      await _authRepository.signUp(email, password, name);
    } finally {
      state = false; // Set loading to false regardless of success/error
    }
  }

  Future<void> signIn(String email, String password) async {
    state = true;
    try {
      await _authRepository.signIn(email, password);
    } finally {
      state = false;
    }
  }

  Future<void> signOut() async {
    await _authRepository.signOut();
  }
}