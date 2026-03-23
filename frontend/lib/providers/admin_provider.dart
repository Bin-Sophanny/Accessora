import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/api_service.dart';

class AdminProvider extends ChangeNotifier {
  List<dynamic> _products = [];
  List<dynamic> _orders = [];
  Map<String, dynamic>? _stats;
  bool _isLoading = false;
  String? _error;

  List<dynamic> get products => _products;
  List<dynamic> get orders => _orders;
  Map<String, dynamic>? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get all products (admin)
  Future<void> fetchProducts(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/admin/products'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('DEBUG Admin fetchProducts: StatusCode = ${response.statusCode}');
      print('DEBUG Admin fetchProducts Response: ${response.body}');

      if (response.statusCode == 200) {
        _products = jsonDecode(response.body);
        _error = null;
      } else {
        final data = jsonDecode(response.body);
        _error = data['error'] ?? 'Failed to fetch products';
        print('DEBUG Admin fetch error: $_error');
      }
    } catch (e) {
      _error = e.toString();
      print('DEBUG Admin fetch exception: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create product
  Future<void> createProduct({
    required String token,
    required String name,
    required String description,
    required double price,
    required String category,
    required int stock,
    String? image,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/admin/products/create'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'description': description,
          'price': price,
          'category': category,
          'stock': stock,
          'image': image ?? '',
        }),
      );

      if (response.statusCode == 201) {
        await fetchProducts(token);
        _error = null;
      } else {
        final data = jsonDecode(response.body);
        _error = data['error'] ?? 'Failed to create product';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update product
  Future<void> updateProduct({
    required String token,
    required String productId,
    required String name,
    required String description,
    required double price,
    required String category,
    required int stock,
    String? image,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.put(
        Uri.parse('${ApiService.baseUrl}/admin/products/$productId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'description': description,
          'price': price,
          'category': category,
          'stock': stock,
          'image': image,
        }),
      );

      if (response.statusCode == 200) {
        await fetchProducts(token);
        _error = null;
      } else {
        final data = jsonDecode(response.body);
        _error = data['error'] ?? 'Failed to update product';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete product
  Future<void> deleteProduct(String token, String productId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.delete(
        Uri.parse('${ApiService.baseUrl}/admin/products/$productId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        await fetchProducts(token);
        _error = null;
      } else {
        final data = jsonDecode(response.body);
        _error = data['error'] ?? 'Failed to delete product';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get all orders (admin)
  Future<void> fetchOrders(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/admin/orders'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('DEBUG Admin fetchOrders: StatusCode = ${response.statusCode}');
      print('DEBUG Admin fetchOrders Response: ${response.body}');

      if (response.statusCode == 200) {
        _orders = jsonDecode(response.body);
        _error = null;
      } else {
        _error = 'Failed to fetch orders';
        print('DEBUG Admin orders error: $_error');
      }
    } catch (e) {
      _error = e.toString();
      print('DEBUG Admin orders exception: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update order status
  Future<void> updateOrderStatus({
    required String token,
    required String orderId,
    required String status,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.put(
        Uri.parse('${ApiService.baseUrl}/admin/orders/$orderId/status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'status': status}),
      );

      if (response.statusCode == 200) {
        await fetchOrders(token);
        _error = null;
      } else {
        final data = jsonDecode(response.body);
        _error = data['error'] ?? 'Failed to update order';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get dashboard stats
  Future<void> fetchStats(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/admin/dashboard/stats'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('DEBUG Admin fetchStats: StatusCode = ${response.statusCode}');
      print('DEBUG Admin fetchStats Response: ${response.body}');

      if (response.statusCode == 200) {
        _stats = jsonDecode(response.body);
        _error = null;
      } else {
        _error = 'Failed to fetch stats';
        print('DEBUG Admin stats error: $_error');
      }
    } catch (e) {
      _error = e.toString();
      print('DEBUG Admin stats exception: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
