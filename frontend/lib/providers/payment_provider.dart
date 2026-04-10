import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import '../services/api_service.dart';

class PaymentProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _paymentData;
  bool _isPaymentSuccessful = false;
  String? _currentPayPalOrderId;

  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get paymentData => _paymentData;
  bool get isPaymentSuccessful => _isPaymentSuccessful;
  String? get currentPayPalOrderId => _currentPayPalOrderId;

  PaymentProvider() {
    // PaymentProvider initialized (WebView payment flow in use)
  }

  Future<Map<String, dynamic>?> confirmPayment({
    required String token,
    required String paypalOrderId,
    required String payerId,
    required List<Map<String, dynamic>> cartItems,
    required String shippingAddress,
    required String phone,
    required String province,
    required double shippingCost,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/payment/confirm'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'paypalOrderId': paypalOrderId,
          'payerId': payerId,
          'cartItems': cartItems,
          'shippingAddress': shippingAddress,
          'phone': phone,
          'province': province,
          'shippingCost': shippingCost,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Payment confirmation took too long. Please check your connection.');
        },
      );

      print('DEBUG: Payment confirm response status: ${response.statusCode}');
      print('DEBUG: Payment confirm response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _paymentData = data;
        _isLoading = false;
        notifyListeners();
        return data;
      } else {
        try {
          final error = jsonDecode(response.body);
          _error = error['error'] ?? 'Failed to confirm payment';
        } catch (e) {
          _error = 'Server error: ${response.statusCode} - ${response.body}';
        }
        _isLoading = false;
        notifyListeners();
        return null;
      }
    } catch (e) {
      _error = 'Exception: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  void clearPayment() {
    _paymentData = null;
    _error = null;
    _isLoading = false;
    _isPaymentSuccessful = false;
    _currentPayPalOrderId = null;
    notifyListeners();
  }

  /// Clear only the loading state without clearing the order ID
  /// Used after creating PayPal order to hide the dialog
  void clearLoadingState() {
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  // WebView PayPal Methods
  void setCurrentPayPalOrderId(String orderId) {
    _currentPayPalOrderId = orderId;
    notifyListeners();
  }

  /// Create PayPal order for WebView checkout
  /// Returns the approval URL to load in WebView
  Future<String?> createPayPalOrder({
    required String token,
    required List<Map<String, dynamic>> cartItems,
    required String shippingAddress,
    required String phone,
    required String province,
    required double shippingCost,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/payment/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'cartItems': cartItems,
          'shippingAddress': shippingAddress,
          'phone': phone,
          'province': province,
          'shippingCost': shippingCost,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Order creation took too long. Please check your connection.');
        },
      );

      print('DEBUG: Create order response status: ${response.statusCode}');
      print('DEBUG: Create order response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _currentPayPalOrderId = data['paypalOrderId'] ?? data['id'];
        _isLoading = false;
        notifyListeners();
        return data['approvalUrl'] ?? ''; // Get approval URL
      } else {
        try {
          final error = jsonDecode(response.body);
          _error = error['error'] ?? 'Failed to create PayPal order';
        } catch (e) {
          _error = 'Server error: ${response.statusCode}';
        }
        _isLoading = false;
        notifyListeners();
        return null;
      }
    } catch (e) {
      print('❌ Error creating PayPal order: $e');
      _error = 'Exception: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Confirm PayPal payment for WebView checkout
  /// Called after user authorizes payment on PayPal
  Future<Map<String, dynamic>?> confirmPayPalPayment({
    required String token,
    required List<Map<String, dynamic>> cartItems,
    required String shippingAddress,
    required String phone,
    required String province,
    required double shippingCost,
  }) async {
    try {
      if (_currentPayPalOrderId == null) {
        _error = 'No PayPal order ID found. Please try again.';
        notifyListeners();
        return null;
      }

      print('📦 Using PayPal Order ID for confirmation: $_currentPayPalOrderId');
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/payment/confirm'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'paypalOrderId': _currentPayPalOrderId,
          'cartItems': cartItems,
          'shippingAddress': shippingAddress,
          'phone': phone,
          'province': province,
          'shippingCost': shippingCost,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Payment confirmation took too long. Please check your connection.');
        },
      );

      print('DEBUG: Confirm payment response status: ${response.statusCode}');
      print('DEBUG: Confirm payment response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _paymentData = data;
        _isPaymentSuccessful = true;
        _isLoading = false;
        notifyListeners();
        return data;
      } else {
        try {
          final error = jsonDecode(response.body);
          _error = error['error'] ?? 'Failed to confirm payment';
        } catch (e) {
          _error = 'Server error: ${response.statusCode}';
        }
        _isPaymentSuccessful = false;
        _isLoading = false;
        notifyListeners();
        return null;
      }
    } catch (e) {
      print('❌ Error confirming PayPal payment: $e');
      _error = 'Exception: $e';
      _isPaymentSuccessful = false;
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }
}
