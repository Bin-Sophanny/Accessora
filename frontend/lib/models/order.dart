import 'cart_item.dart';

class Order {
  final String id;
  final String userId;
  final List<CartItem> items;
  final double totalPrice;
  final String shippingAddress;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalPrice,
    required this.shippingAddress,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    List<CartItem> items = [];
    if (json['items'] != null) {
      items = (json['items'] as List)
          .map((item) => CartItem.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return Order(
      id: json['_id'] ?? '',
      userId: json['userId'] ?? '',
      items: items,
      totalPrice: (json['totalPrice'] ?? 0).toDouble(),
      shippingAddress: json['shippingAddress'] ?? '',
      status: json['status'] ?? 'pending',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'userId': userId,
    'items': items.map((item) => item.toJson()).toList(),
    'totalPrice': totalPrice,
    'shippingAddress': shippingAddress,
    'status': status,
  };
}
