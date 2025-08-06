import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/auth_service.dart';

final authProvider = StateNotifierProvider<AuthController, bool>(
  (ref) => AuthController(),
);

class AuthController extends StateNotifier<bool> {
  AuthController() : super(AuthService().currentSession != null);

  static bool isLoggedIn() => AuthService().currentSession != null;

  Future<void> login(String email, String password) async {
    final response = await AuthService().signIn(email, password);
    state = response.session != null;
  }

  Future<void> logout() async {
    await AuthService().signOut();
    state = false;
  }
}
