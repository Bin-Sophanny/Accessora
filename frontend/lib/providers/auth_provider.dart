import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  String? _token;
  String? _userId;
  String? _email;
  String? _name;
  String? _phone = '';
  String? _address = '';
  String? _province = 'Phnom Penh';
  String? _profileImage;
  String? _error;
  bool _isLoading = false;
  String? _unverifiedEmail; // For tracking unverified login attempts

  bool get isAuthenticated => _isAuthenticated;
  String? get token => _token;
  String? get userId => _userId;
  String? get email => _email;
  String? get name => _name;
  String? get phone => _phone;
  String? get address => _address;
  String? get province => _province;
  String? get profileImage => _profileImage;
  String? get error => _error;
  bool get isLoading => _isLoading;
  String? get unverifiedEmail => _unverifiedEmail;



  // Register user
  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'phone': phone,
        }),
      );

      if (response.statusCode == 200) {
        _email = email;
        _error = null;
      } else {
        final data = jsonDecode(response.body);
        _error = data['error'] ?? 'Registration failed';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Verify email
  Future<void> verifyEmail(String email, String code) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    // Normalize email
    final normalizedEmail = email.toLowerCase().trim();

    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/auth/verify-email'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': normalizedEmail, 'code': code}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['token'];
        _isAuthenticated = true;
        _userId = data['user']['id'];
        _email = data['user']['email'];
        _name = data['user']['name'];
        _phone = data['user']['phone'] ?? '';
        _address = data['user']['address'] ?? '';
        _province = data['user']['province'] ?? 'Phnom Penh';
        _profileImage = data['user']['profileImage'];
        _error = null;
      } else {
        final data = jsonDecode(response.body);
        _error = data['error'] ?? 'Verification failed';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Resend verification code
  Future<void> resendVerificationCode(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    // Normalize email
    final normalizedEmail = email.toLowerCase().trim();

    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/auth/resend-verification-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': normalizedEmail}),
      );

      if (response.statusCode == 200) {
        _error = null;
      } else {
        final data = jsonDecode(response.body);
        _error = data['error'] ?? 'Failed to resend code';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Login user
  Future<void> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    _unverifiedEmail = null;
    notifyListeners();

    // Normalize email
    final normalizedEmail = email.toLowerCase().trim();

    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': normalizedEmail,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['token'];
        _isAuthenticated = true;
        _userId = data['user']['id'];
        _email = data['user']['email'];
        _name = data['user']['name'];
        _phone = data['user']['phone'] ?? '';
        _address = data['user']['address'] ?? '';
        _province = data['user']['province'] ?? 'Phnom Penh';
        _profileImage = data['user']['profileImage'];
        _error = null;
      } else {
        final data = jsonDecode(response.body);
        _error = data['error'] ?? 'Login failed';
        // Check if email needs verification
        if (data['needsVerification'] == true && data['email'] != null) {
          _unverifiedEmail = data['email'];
        }
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Logout
  void logout() {
    _isAuthenticated = false;
    _token = null;
    _userId = null;
    _email = null;
    _name = null;
    _phone = '';
    _address = '';
    _province = 'Phnom Penh';
    _profileImage = null;
    _error = null;
    _unverifiedEmail = null;
    notifyListeners();
  }

  // Forgot password
  Future<void> forgotPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    // Normalize email
    final normalizedEmail = email.toLowerCase().trim();

    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': normalizedEmail}),
      );

      if (response.statusCode == 200) {
        _error = null;
      } else {
        final data = jsonDecode(response.body);
        _error = data['error'] ?? 'Request failed';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Reset password
  Future<void> resetPassword(String code, String newPassword) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': code,
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        _error = null;
      } else {
        final data = jsonDecode(response.body);
        _error = data['error'] ?? 'Reset failed';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update user profile
  Future<void> updateProfile({
    String? name,
    String? phone,
    String? address,
    String? province,
    String? profileImage,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('DEBUG: Updating profile with token: $_token');
      print('DEBUG: Base URL: ${ApiService.baseUrl}');
      
      final response = await http.put(
        Uri.parse('${ApiService.baseUrl}/auth/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({
          if (name != null) 'name': name,
          if (phone != null) 'phone': phone,
          if (address != null) 'address': address,
          if (province != null) 'province': province,
          if (profileImage != null) 'profileImage': profileImage,
        }),
      );

      print('DEBUG: Response status: ${response.statusCode}');
      final responseBodyPreview = response.body.length > 200 
          ? response.body.substring(0, 200) 
          : response.body;
      print('DEBUG: Response body: $responseBodyPreview');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = data['user'];
        _name = user['name'] ?? _name;
        _phone = user['phone'] ?? _phone;
        _address = user['address'] ?? _address;
        _province = user['province'] ?? _province;
        _profileImage = user['profileImage'];
        _error = null;
        print('DEBUG: Profile updated successfully');
      } else {
        // Try to parse as JSON, if it fails it's likely HTML error
        try {
          final data = jsonDecode(response.body);
          _error = data['error'] ?? 'Update failed';
        } catch (e) {
          _error = 'Server error (${response.statusCode}): ${response.body.substring(0, 100)}';
          print('DEBUG: Server returned non-JSON response: ${response.body}');
        }
      }
    } catch (e) {
      _error = e.toString();
      print('DEBUG: Profile update error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
