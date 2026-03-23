import 'package:flutter/material.dart';
import '../models/order.dart';
import '../services/api_service.dart';

class OrderProvider extends ChangeNotifier {
  List<Order> _orders = [];
  bool _isLoading = false;
  String? _error;

  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchUserOrders(String userId) async {
    if (userId.isEmpty) {
      _error = 'User not authenticated';
      _orders = [];
      notifyListeners();
      return;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _orders = await ApiService.getUserOrders(userId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Order> getOrderById(String userId, String orderId) async {
    if (userId.isEmpty) {
      throw Exception('User not authenticated');
    }
    try {
      return await ApiService.getOrderById(userId, orderId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
