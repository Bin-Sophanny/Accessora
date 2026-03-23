import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;
import '../models/product.dart';
import '../models/cart.dart';
import '../models/order.dart';

class ApiService {
  // Use 10.0.2.2 for Android emulator, localhost for web/iOS
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5000/api';
    } else if (Platform.isIOS) {
      return 'http://localhost:5000/api';
    } else {
      return 'http://localhost:5000/api'; // For web
    }
  }

  // Products API
  static Future<List<Product>> getAllProducts() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/products'));
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Product.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load products');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  static Future<Product> getProductById(String id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/products/$id'));
      if (response.statusCode == 200) {
        return Product.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Product not found');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  static Future<List<Product>> getProductsByCategory(String category) async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/products/category/$category'));
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Product.fromJson(json)).toList();
      } else {
        throw Exception('No products found in this category');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Cart API
  static Future<Cart> getCart(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/cart/$userId'));
      if (response.statusCode == 200) {
        return Cart.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to load cart');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  static Future<void> addToCart(
      String userId, String productId, int quantity) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/cart/$userId/add'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'productId': productId,
          'quantity': quantity,
        }),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to add to cart');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  static Future<void> removeFromCart(String userId, String productId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/cart/$userId/remove/$productId'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to remove from cart');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  static Future<void> clearCart(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/cart/$userId/clear'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to clear cart');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Orders API
  static Future<List<Order>> getUserOrders(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/orders/$userId'));
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Order.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load orders');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  static Future<Order> createOrder(String userId, String shippingAddress,
      String phoneNumber, String province) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orders/$userId/create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'shippingAddress': shippingAddress,
          'phoneNumber': phoneNumber,
          'province': province,
        }),
      );
      if (response.statusCode == 200) {
        return Order.fromJson(jsonDecode(response.body)['order']);
      } else {
        throw Exception('Failed to create order');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  static Future<Order> getOrderById(String userId, String orderId) async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/orders/$userId/$orderId'));
      if (response.statusCode == 200) {
        return Order.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Order not found');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Payment API
  static Future<Map<String, dynamic>> createPayment(
    String token,
    List<Map<String, dynamic>> cartItems,
    String shippingAddress,
    String phone,
    String province,
    double shippingCost,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/payment/create'),
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
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create payment');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  static Future<Map<String, dynamic>> confirmPayment(
    String token,
    String paypalOrderId,
    List<Map<String, dynamic>> cartItems,
    String shippingAddress,
    String phone,
    String province,
    double shippingCost,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/payment/confirm'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'paypalOrderId': paypalOrderId,
          'cartItems': cartItems,
          'shippingAddress': shippingAddress,
          'phone': phone,
          'province': province,
          'shippingCost': shippingCost,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to confirm payment');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
