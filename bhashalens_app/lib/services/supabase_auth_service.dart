import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

class SupabaseAuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<String?> signUp(String email, String password) async {
    try {
      final AuthResponse response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      if (response.user != null) {
        debugPrint('User signed up: ${response.user!.email}');
        return null; // Success
      } else if (response.session == null && response.user == null) {
        return 'Please check your email to verify your account.';
      }
      return 'Sign up failed. Please try again.';
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> signIn(String email, String password) async {
    try {
      final AuthResponse response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user != null) {
        debugPrint('User signed in: ${response.user!.email}');
        return null; // Success
      }
      return 'Sign in failed. Please check your credentials.';
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> signOut() async {
    try {
      await _supabase.auth.signOut();
      debugPrint('User signed out');
      return null; // Success
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> resetPasswordForEmail(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      debugPrint('Password reset email sent to: $email');
      return null; // Success
    } catch (e) {
      return e.toString();
    }
  }

  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}
