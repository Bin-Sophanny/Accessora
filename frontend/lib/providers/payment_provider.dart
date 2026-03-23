import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:paypal_native_checkout/paypal_native_checkout.dart';
import 'package:paypal_native_checkout/models/custom/environment.dart';
import 'package:paypal_native_checkout/models/custom/currency_code.dart';
import 'package:paypal_native_checkout/models/custom/user_action.dart';
import 'package:paypal_native_checkout/models/custom/order_callback.dart';
import 'package:paypal_native_checkout/models/custom/purchase_unit.dart';
import 'dart:async';
import 'dart:convert';
import '../services/api_service.dart';

class PaymentProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _paymentData;
  bool _isPaymentSuccessful = false;
  String? _currentPayPalOrderId;
  
  late final PaypalNativeCheckout _paypalPlugin;

  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get paymentData => _paymentData;
  bool get isPaymentSuccessful => _isPaymentSuccessful;
  String? get currentPayPalOrderId => _currentPayPalOrderId;

  PaymentProvider() {
    _paypalPlugin = PaypalNativeCheckout.instance;
    _initPayPal();
  }

  void _initPayPal() async {
    try {
      // Enable debug mode for development
      PaypalNativeCheckout.isDebugMode = true;

      // Initialize PayPal with proper configuration
      const String paypalClientId = "ATv8tAgy7i8TThtlg7ac5-D1gMHVCs0yfgXQZcXgLKWyJhCRhCkbT7Q7lL-ZtYMi5WOmDvjAUtlrTz26";

      if (paypalClientId.isEmpty) {
        throw Exception('PayPal Client ID is empty. Please configure it properly.');
      }

      await _paypalPlugin.init(
        returnUrl: "com.example.accessora://paypalpay",
        clientID: paypalClientId,
        payPalEnvironment: FPayPalEnvironment.sandbox,
        currencyCode: FPayPalCurrencyCode.usd,
        action: FPayPalUserAction.payNow,
      );

      print('✅ PayPal initialized successfully');
    } catch (e) {
      print('❌ PayPal initialization error: $e');
      _error = 'Failed to initialize PayPal: $e';
      notifyListeners();
    }
  }

  Future<bool> processNativePayment({
    required String token,
    required List<Map<String, dynamic>> cartItems,
    required String shippingAddress,
    required String phone,
    required String province,
    required double shippingCost,
  }) async {
    try {
      _isLoading = false; // Don't show loading yet - wait for PayPal callback
      _isPaymentSuccessful = false;
      _error = null;
      notifyListeners();

      // Validate cart items
      if (cartItems.isEmpty) {
        _error = 'Cart is empty. Please add items before checkout.';
        notifyListeners();
        return false;
      }

      // Calculate total amount
      double subtotal = cartItems.fold<double>(0, (sum, item) {
        return sum + ((item['price'] ?? 0.0) * (item['quantity'] ?? 1));
      });
      double totalAmount = subtotal + shippingCost;

      print('💰 Total amount: \$$totalAmount');
      print('📦 Cart items: ${cartItems.length}');
      
      // Clear previous items
      _paypalPlugin.removeAllPurchaseItems();

      // Add cart items to purchase units
      int itemsAdded = 0;
      for (var item in cartItems) {
        if (_paypalPlugin.canAddMorePurchaseUnit) {
          final itemAmount = (item['price'] ?? 0.0) * (item['quantity'] ?? 1);
          _paypalPlugin.addPurchaseUnit(
            FPayPalPurchaseUnit(
              amount: itemAmount,
              referenceId: (item['productId'] ?? 'product_$itemsAdded').toString(),
            ),
          );
          itemsAdded++;
          print('✅ Added item: ${item['productId']} - Amount: \$$itemAmount');
        } else {
          print('⚠️ Cannot add more items. Max 4 purchase units allowed.');
          break;
        }
      }

      // Add shipping if there's room
      if (_paypalPlugin.canAddMorePurchaseUnit && shippingCost > 0) {
        _paypalPlugin.addPurchaseUnit(
          FPayPalPurchaseUnit(
            amount: shippingCost,
            referenceId: "shipping",
          ),
        );
        print('✅ Added shipping: \$$shippingCost');
      }

      // Set up callbacks
      _paypalPlugin.setPayPalOrderCallback(
        callback: FPayPalOrderCallback(
          onSuccess: (data) async {
            print('✅ Payment Success: $data');
            
            try {
              // NOW show loading after PayPal confirms
              _isLoading = true;
              notifyListeners();
              
              final orderId = data.orderId;
              final payerId = data.payerId ?? '';
              
              if (orderId == null || orderId.isEmpty) {
                _error = 'Order ID not received from PayPal. Please try again.';
                _isLoading = false;
                _isPaymentSuccessful = false;
                notifyListeners();
                return;
              }

              print('📝 Confirming payment with backend for order: $orderId');

              // Confirm payment with backend
              final confirmed = await confirmPayment(
                token: token,
                paypalOrderId: orderId,
                payerId: payerId,
                cartItems: cartItems,
                shippingAddress: shippingAddress,
                phone: phone,
                province: province,
                shippingCost: shippingCost,
              );

              if (confirmed != null) {
                _isPaymentSuccessful = true;
                _error = null;
                _paymentData = confirmed;
                print('✅ Payment confirmed successfully!');
              } else {
                _error = _error ?? 'Failed to confirm payment with server. Please contact support.';
                _isPaymentSuccessful = false;
              }
            } catch (e) {
              print('❌ Error in success callback: $e');
              _error = 'Error processing payment: ${e.toString()}';
              _isPaymentSuccessful = false;
            } finally {
              _isLoading = false;
              notifyListeners();
            }
          },
          onError: (data) {
            print('❌ Payment Error: ${data.reason}');
            print('❌ Full Error Data: $data');
            _error = 'PayPal Error: ${data.reason}';
            _isLoading = false;
            _isPaymentSuccessful = false;
            notifyListeners();
          },
          onCancel: () {
            print('⚠️ Payment Cancelled by User');
            _error = 'You cancelled the payment. Please try again if you wish to proceed.';
            _isLoading = false;
            _isPaymentSuccessful = false;
            notifyListeners();
          },
          onShippingChange: (data) {
            print('📍 Shipping address changed: $data');
          },
        ),
      );

      // Create shipping address map for PayPal
      Map<String, dynamic> paypalAddress = {
        'line1': shippingAddress,
        'line2': '', // Secondary address line (required by SDK)
        'city': province,
        'state': province,
        'postalCode': '00000',
        'countryCode': 'KH', // Cambodia
      };

      print('🔄 Opening PayPal checkout...');
      // Start payment with proper parameters
      _paypalPlugin.makeOrder(
        action: FPayPalUserAction.payNow,
        fullName: phone,
        address: paypalAddress,
      );

      return true;
    } catch (e) {
      print('❌ Exception in processNativePayment: $e');
      _error = 'Exception: ${e.toString()}';
      _isLoading = false;
      _isPaymentSuccessful = false;
      notifyListeners();
      return false;
    }
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
