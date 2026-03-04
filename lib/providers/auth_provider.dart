import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/citizen.dart';

class AuthProvider extends ChangeNotifier {
  String? _token;
  Citizen? _user;
  bool _isLoading = false;

  String? get token => _token;
  Citizen? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null;

  AuthProvider() {
    _loadSession();
  }

  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    // In a real app, we might check token validity or fetch user profile here
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    // MOCK API Call
    await Future.delayed(const Duration(seconds: 1));
    
    if (email == "citizen@example.com" && password == "password") {
      _token = "mock_jwt_token";
      _user = Citizen(
        id: "1",
        fullName: "Juan Dela Cruz",
        address: "123 Mabini St, Manila",
        birthdate: DateTime(1990, 5, 20),
        email: email,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', _token!);
      
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> loginAsDemo() async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));
    _token = "demo_token";
    _user = Citizen(
      id: "demo_1",
      fullName: "Demo User",
      address: "Demo Barangay, LG City",
      birthdate: DateTime(1995, 1, 1),
      email: "demo@ulgdsp.gov.ph",
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', _token!);

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> register({
    required String fullName,
    required String address,
    required DateTime birthdate,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    // MOCK API Call
    await Future.delayed(const Duration(seconds: 1));
    
    _isLoading = false;
    notifyListeners();
    return true; // Assume success for this demo
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    notifyListeners();
  }
}
