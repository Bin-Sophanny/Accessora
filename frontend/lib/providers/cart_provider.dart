import 'package:flutter/material.dart';
import '../models/cart.dart';
import '../models/cart_item.dart';
import '../services/api_service.dart';

class CartProvider extends ChangeNotifier {
  late String _userId;
  Cart? _cart;
  bool _isLoading = false;
  String? _error;

  CartProvider() {
    _userId = '';
  }

  String get userId => _userId;
  Cart? get cart => _cart;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get itemCount => _cart?.itemCount ?? 0;
  double get total => _cart?.total ?? 0.0;

  // Set userId when user logs in
  void setUserId(String userId) {
    _userId = userId;
    notifyListeners();
  }

  Future<void> fetchCart({String? userId}) async {
    final actualUserId = userId ?? _userId;
    if (actualUserId.isEmpty) {
      _error = 'User not authenticated';
      notifyListeners();
      return;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('DEBUG: Fetching cart with userId: $actualUserId');
      _cart = await ApiService.getCart(actualUserId);
      print('DEBUG: Cart fetched successfully, items: ${_cart?.items.length}');
      _error = null;
    } catch (e) {
      _error = e.toString();
      print('DEBUG: Error fetching cart: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addToCart(String productId, String name, double price, int quantity, {String? userId}) async {
    final actualUserId = userId ?? _userId;
    if (actualUserId.isEmpty) {
      _error = 'User not authenticated. Please log in first.';
      notifyListeners();
      return;
    }
    try {
      print('DEBUG: Adding to cart with userId: $actualUserId, productId: $productId');
      await ApiService.addToCart(actualUserId, productId, quantity);
      print('DEBUG: Successfully added to cart');
      // Fetch cart with the same userId
      final cart = await ApiService.getCart(actualUserId);
      _cart = cart;
      print('DEBUG: Cart items count: ${_cart?.items.length}');
    } catch (e) {
      _error = e.toString();
      print('DEBUG: Error adding to cart: $e');
      notifyListeners();
    }
  }

  Future<void> removeFromCart(String itemId, {String? userId}) async {
    final actualUserId = userId ?? _userId;
    if (actualUserId.isEmpty) {
      _error = 'User not authenticated. Please log in first.';
      notifyListeners();
      return;
    }
    try {
      print('DEBUG: Removing item $itemId with userId: $actualUserId');
      await ApiService.removeFromCart(actualUserId, itemId);
      print('DEBUG: Item removed successfully');
      await fetchCart(userId: actualUserId);
    } catch (e) {
      _error = e.toString();
      print('DEBUG: Error removing from cart: $e');
      notifyListeners();
    }
  }

  Future<void> clearCart({String? userId}) async {
    final actualUserId = userId ?? _userId;
    if (actualUserId.isEmpty) {
      _error = 'User not authenticated';
      notifyListeners();
      return;
    }
    try {
      print('DEBUG: Clearing cart with userId: $actualUserId');
      await ApiService.clearCart(actualUserId);
      print('DEBUG: Cart cleared successfully');
      _cart = Cart(
        id: '',
        userId: actualUserId,
        items: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      print('DEBUG: Error clearing cart: $e');
      notifyListeners();
    }
  }

  Future<void> updateQuantity(String productId, int newQuantity, {String? userId}) async {
    final actualUserId = userId ?? _userId;
    if (newQuantity < 1) {
      await removeFromCart(productId, userId: actualUserId);
      return;
    }
    try {
      print('DEBUG: Updating quantity for productId: $productId, newQuantity: $newQuantity, userId: $actualUserId');
      // Find the current item to calculate the difference
      final item = _cart?.items.firstWhere(
        (item) => item.productId == productId,
        orElse: () => CartItem(productId: '', name: '', price: 0, quantity: 0),
      );
      
      if (item != null && item.productId.isNotEmpty) {
        final quantityDifference = newQuantity - item.quantity;
        // Call addToCart with the difference to sync with backend
        await ApiService.addToCart(actualUserId, productId, quantityDifference);
        print('DEBUG: Quantity updated successfully');
        // Fetch fresh data from backend
        await fetchCart(userId: actualUserId);
      }
    } catch (e) {
      _error = e.toString();
      print('DEBUG: Error updating quantity: $e');
      notifyListeners();
    }
  }

  Future<void> createOrder({
    required String shippingAddress,
    required String phoneNumber,
    required String province,
    String? userId,
  }) async {
    final actualUserId = userId ?? _userId;
    if (actualUserId.isEmpty) {
      _error = 'User not authenticated. Please log in first.';
      notifyListeners();
      return;
    }
    try {
      print('DEBUG: Creating order with userId: $actualUserId');
      await ApiService.createOrder(actualUserId, shippingAddress, phoneNumber, province);
      print('DEBUG: Order created successfully');
      // Clear cart with proper userId
      final cart = Cart(
        id: '',
        userId: actualUserId,
        items: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _cart = cart;
    } catch (e) {
      _error = e.toString();
      print('DEBUG: Error creating order: $e');
      notifyListeners();
    }
  }
}
