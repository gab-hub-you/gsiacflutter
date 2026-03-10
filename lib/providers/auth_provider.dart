import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/citizen.dart';

class AuthProvider extends ChangeNotifier {
  String? _token;
  Citizen? _user;
  bool _isLoading = false;
  String? _errorMessage;

  String? get token => _token;
  Citizen? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _token != null;

  AuthProvider() {
    _init();
  }

  void _init() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final Session? session = data.session;
      _token = session?.accessToken;
      if (session?.user != null) {
        // Map Supabase User to your Citizen model
        // You might want to fetch additional data from a 'profiles' table here
        _user = Citizen(
          id: session!.user.id,
          fullName: session.user.userMetadata?['full_name'] ?? 'User',
          address: session.user.userMetadata?['address'] ?? '',
          birthdate: DateTime.tryParse(session.user.userMetadata?['birthdate'] ?? '') ?? DateTime.now(),
          email: session.user.email ?? '',
        );
      } else {
        _user = null;
      }
      notifyListeners();
    });
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    debugPrint("Attempting login for email: '${email.trim()}'");
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      debugPrint("AuthException during login: ${e.message} (Status: ${e.statusCode})");
      if (e.message.toLowerCase().contains('invalid login credentials')) {
        _errorMessage = "Invalid email or password. Please try again.";
      } else if (e.message.toLowerCase().contains('email not confirmed')) {
        _errorMessage = "Email not confirmed. Please check your inbox for a verification link.";
      } else {
        _errorMessage = e.message;
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = "An unexpected error occurred. Please try again later.";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String fullName,
    required String address,
    required DateTime birthdate,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    debugPrint("Attempting registration for email: '${email.trim()}'");
    try {
      await Supabase.instance.client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'full_name': fullName,
          'address': address,
          'birthdate': birthdate.toIso8601String(),
        },
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      debugPrint("AuthException during registration: ${e.message} (Status: ${e.statusCode})");
      if (e.message.toLowerCase().contains('user already registered') || 
          e.message.toLowerCase().contains('already exists')) {
        _errorMessage = "This email is already registered. Please login instead.";
      } else if (e.message.toLowerCase().contains('email rate limit exceeded')) {
        _errorMessage = "Email rate limit exceeded. Please wait a while before trying again or contact support if this persists.";
      } else {
        _errorMessage = e.message;
      }
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }


  Future<void> logout() async {
    await Supabase.instance.client.auth.signOut();
    _token = null;
    _user = null;
    notifyListeners();
  }
}
