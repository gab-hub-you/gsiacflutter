import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final Session? session = data.session;
      _token = session?.accessToken;
      if (session?.user != null) {
        await fetchProfile(session!.user.id);
      } else {
        _user = null;
        notifyListeners();
      }
    });
  }

  Future<void> fetchProfile(String userId) async {
    try {
      final data = await Supabase.instance.client
          .from('citizens')
          .select()
          .eq('id', userId)
          .single();
      
      _user = Citizen.fromJson(data);
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching profile: $e");
      // Fallback to minimal data from auth metadata if DB fetch fails
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final metadata = user.userMetadata ?? {};
        _user = Citizen(
          id: user.id,
          username: metadata['username'] ?? '',
          firstName: metadata['firstName'] ?? '',
          lastName: metadata['lastName'] ?? '',
          address: metadata['address'] ?? '',
          birthdate: DateTime.tryParse(metadata['birthdate'] ?? '') ?? DateTime.now(),
          email: user.email ?? '',
          profilePictureUrl: metadata['profilePictureUrl'],
          verificationStatus: VerificationStatus.values.firstWhere(
            (e) => e.name == (metadata['verificationStatus'] ?? 'unverified'),
            orElse: () => VerificationStatus.unverified,
          ),
        );
        notifyListeners();
      }
    }
  }

  Future<void> refreshProfile() async {
    final curUser = Supabase.instance.client.auth.currentUser;
    if (curUser != null) {
      await fetchProfile(curUser.id);
    }
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
    required String email,
    required String password,
    required String username,
    required String phoneNumber,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    debugPrint("Attempting initial registration for email: '${email.trim()}'");
    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'username': username,
          'phone_number': phoneNumber,
          'verification_status': VerificationStatus.unverified.name,
        },
      );

      if (response.user != null) {
        debugPrint("Auth signUp successful for user ID: ${response.user!.id}. Database sync should be handled by trigger.");
      } else {
        debugPrint("Auth signUp success but user object is null. This might happen if email confirmation is required.");
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      debugPrint("AuthException during registration: ${e.message} (Status: ${e.statusCode})");
      if (e.message.toLowerCase().contains('user already registered') || 
          e.message.toLowerCase().contains('already exists')) {
        _errorMessage = "This email is already registered. Please login instead.";
      } else if (e.message.toLowerCase().contains('email rate limit exceeded')) {
        _errorMessage = "Email rate limit exceeded. Please wait a while before trying again.";
      } else {
        _errorMessage = e.message;
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint("Unexpected error during registration: $e");
      _errorMessage = "Registration failed: ${e.toString()}";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> validateCitizen({
    required String firstName,
    required String lastName,
    String? middleName,
    String? suffix,
    String? sex,
    String? status,
    required String address,
    required DateTime birthdate,
    required String town,
    required String barangay,
    String? govIdUrl,
    String? selfieUrl,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;

      await Supabase.instance.client.auth.updateUser(
        UserAttributes(
          data: {
            'firstName': firstName,
            'lastName': lastName,
            'middleName': middleName,
            'suffix': suffix,
            'sex': sex,
            'status': status,
            'address': address,
            'birthdate': birthdate.toIso8601String(),
            'town': town,
            'barangay': barangay,
            'govIdUrl': govIdUrl,
            'selfieUrl': selfieUrl,
            'verificationStatus': VerificationStatus.pending.name,
          },
        ),
      );

      // Sync with public citizens table
      await Supabase.instance.client.from('citizens').upsert({
        'id': userId,
        'first_name': firstName,
        'last_name': lastName,
        'middle_name': middleName,
        'suffix': suffix,
        'sex': sex,
        'status': status,
        'address': address,
        'birthdate': birthdate.toIso8601String(),
        'town': town,
        'barangay': barangay,
        'gov_id_url': govIdUrl,
        'selfie_url': selfieUrl,
        'verification_status': VerificationStatus.pending.name,
        'profile_picture_url': _user?.profilePictureUrl,
      });
      
      // Sync local user object
      if (_user != null) {
        _user = Citizen(
          id: _user!.id,
          username: _user!.username,
          profilePictureUrl: _user!.profilePictureUrl,
          firstName: firstName,
          lastName: lastName,
          middleName: middleName,
          suffix: suffix,
          sex: sex,
          status: status,
          address: address,
          birthdate: birthdate,
          email: _user!.email,
          phoneNumber: _user!.phoneNumber,
          town: town,
          barangay: barangay,
          govIdUrl: govIdUrl,
          selfieUrl: selfieUrl,
          verificationStatus: VerificationStatus.pending,
          lifeStatus: _user!.lifeStatus,
        );
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<String?> uploadVerificationDocument(List<int> bytes, String fileName) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final path = '$userId/verification/$fileName';
      
      await Supabase.instance.client.storage
          .from('verification-docs')
          .uploadBinary(path, Uint8List.fromList(bytes));

      final url = Supabase.instance.client.storage
          .from('verification-docs')
          .getPublicUrl(path);
      
      _isLoading = false;
      notifyListeners();
      return url;
    } catch (e) {
      debugPrint("Upload error: $e");
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }


  Future<String?> uploadProfilePicture(List<int> bytes, String fileName) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final path = '$userId/profiles/$fileName';
      
      await Supabase.instance.client.storage
          .from('verification-docs')
          .uploadBinary(
            path, 
            Uint8List.fromList(bytes),
            fileOptions: const FileOptions(upsert: true),
          );

      final url = Supabase.instance.client.storage
          .from('verification-docs')
          .getPublicUrl(path);

      final success = await updateProfileMetadata({'profilePictureUrl': url});
      if (!success) {
        throw Exception(_errorMessage ?? 'Failed to update database profile');
      }
      
      _isLoading = false;
      notifyListeners();
      return url;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateProfileMetadata(Map<String, dynamic> data) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(data: data),
      );

      // Map dynamic keys to database snake_case keys if necessary
      final Map<String, dynamic> dbData = {};
      data.forEach((key, value) {
        if (key == 'profilePictureUrl') {
          dbData['profile_picture_url'] = value;
        } else if (key == 'firstName') {
          dbData['first_name'] = value;
        } else if (key == 'lastName') {
          dbData['last_name'] = value;
        } else if (key == 'middleName') {
          dbData['middle_name'] = value;
        } else if (key == 'verificationStatus') {
          dbData['verification_status'] = value;
        } else if (key == 'govIdUrl') {
          dbData['gov_id_url'] = value;
        } else if (key == 'selfieUrl') {
          dbData['selfie_url'] = value;
        } else {
          dbData[key] = value;
        }
      });

      if (dbData.isNotEmpty) {
        debugPrint("Syncing to citizens table for user $userId: $dbData");
        await Supabase.instance.client
            .from('citizens')
            .update(dbData)
            .eq('id', userId);
      }
      
      // Update local user object lazily
      if (_user != null) {
        final Map<String, dynamic> userJson = _user!.toJson();
        userJson.addAll(data);
        _user = Citizen.fromJson(userJson);
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
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
