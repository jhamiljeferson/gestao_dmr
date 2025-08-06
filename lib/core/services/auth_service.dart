import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class AuthService {
  final SupabaseClient _client = SupabaseService().client;

  Future<AuthResponse> signIn(String email, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      print('Login realizado para: ' + email);
      return response;
    } catch (e) {
      print('Erro ao fazer login: ' + e.toString());
      rethrow;
    }
  }

  Future<AuthResponse> signUp(String email, String password) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );
      print('Usuário criado no Supabase Auth: ' + email);
      return response;
    } catch (e) {
      print('Erro ao criar usuário no Supabase Auth: ' + e.toString());
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
      print('Logout realizado');
    } catch (e) {
      print('Erro ao fazer logout: ' + e.toString());
      rethrow;
    }
  }

  Session? get currentSession => _client.auth.currentSession;
  User? get currentUser => _client.auth.currentUser;
}
