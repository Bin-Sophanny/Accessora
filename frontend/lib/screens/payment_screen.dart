import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/payment_provider.dart';
import '../providers/auth_provider.dart';
import 'paypal_webview_screen.dart';

class PaymentScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final String shippingAddress;
  final String phone;
  final String province;
  final double shippingCost;

  const PaymentScreen({
    super.key,
    required this.cartItems,
    required this.shippingAddress,
    required this.phone,
    required this.province,
    required this.shippingCost,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isPaymentProcessing = false;

  @override
  void initState() {
    super.initState();
    // Listen for payment success and errors
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final paymentProvider = context.read<PaymentProvider>();
      
      // Check if loading state changes
      paymentProvider.addListener(_handlePaymentStateChange);
    });
  }

  @override
  void dispose() {
    final paymentProvider = context.read<PaymentProvider>();
    paymentProvider.removeListener(_handlePaymentStateChange);
    super.dispose();
  }

  void _handlePaymentStateChange() {
    final paymentProvider = context.read<PaymentProvider>();
    
    // Show loading dialog when confirming with backend
    if (paymentProvider.isLoading && !_isPaymentProcessing) {
      _showLoadingDialog('Processing Payment', 'Confirming with server...');
      return;
    }
    
    // Hide loading dialog and show result
    if (!paymentProvider.isLoading && _isPaymentProcessing) {
      Navigator.of(context, rootNavigator: true).pop(); // Close loading dialog
      
      if (paymentProvider.isPaymentSuccessful) {
        _handlePaymentSuccess(paymentProvider);
      } else if (paymentProvider.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${paymentProvider.error}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      
      setState(() => _isPaymentProcessing = false);
    }
  }

  void _showLoadingDialog(String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Color(0xFF00D9FF)),
              ),
              const SizedBox(height: 16),
              Text(message),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handlePaymentSuccess(PaymentProvider paymentProvider) async {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Payment confirmed! Order created successfully.'),
        backgroundColor: Color(0xFF00D9FF),
        duration: Duration(seconds: 2),
      ),
    );

    // Clear payment data
    paymentProvider.clearPayment();
    
    // Wait a moment for snackbar to show
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/home',
        (route) => false,
      );
    }
  }

  Future<void> _startWebViewPayment() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final paymentProvider = context.read<PaymentProvider>();

      // Remove the listener before navigating to WebView
      // This prevents dialogs from showing when the WebView is active
      paymentProvider.removeListener(_handlePaymentStateChange);

      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaypalWebviewScreen(
              cartItems: widget.cartItems,
              shippingAddress: widget.shippingAddress,
              phone: widget.phone,
              province: widget.province,
              shippingCost: widget.shippingCost,
              paymentToken: authProvider.token ?? '',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exception: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Secure Payment',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        elevation: 4,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Consumer<PaymentProvider>(
        builder: (context, paymentProvider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Information Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock, color: Colors.blue[600], size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Secure PayPal Payment',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Complete your payment securely with PayPal.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Order Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order Summary',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...widget.cartItems.map((item) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Product x${item['quantity']}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.black87),
                            ),
                          ),
                          Text(
                            '\$${(item['price'] * item['quantity']).toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const Divider(color: Color(0xFF00D9FF)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Shipping:',
                        style: TextStyle(color: Colors.black87),
                      ),
                      Text(
                        '\$${widget.shippingCost.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Amount:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        '\$${((widget.cartItems.fold<double>(0, (sum, item) => sum + (item['price'] * item['quantity']))) + widget.shippingCost).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Color(0xFF00D9FF),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Shipping Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Shipping Information',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 16, color: Colors.black54),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.shippingAddress,
                          style: const TextStyle(color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 16, color: Colors.black54),
                      const SizedBox(width: 8),
                      Text(
                        widget.phone,
                        style: const TextStyle(color: Colors.black87),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_city,
                          size: 16, color: Colors.black54),
                      const SizedBox(width: 8),
                      Text(
                        widget.province,
                        style: const TextStyle(color: Colors.black87),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // WebView PayPal Payment Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isPaymentProcessing ? null : _startWebViewPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF009cde),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isPaymentProcessing || paymentProvider.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text('Pay with PayPal'),
              ),
            ),
            const SizedBox(height: 12),
            // Error Message Display
            if (paymentProvider.error != null && paymentProvider.error!.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        paymentProvider.error!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (paymentProvider.error != null && paymentProvider.error!.isNotEmpty)
              const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: (_isPaymentProcessing || paymentProvider.isLoading)
                    ? null
                    : () {
                        paymentProvider.clearPayment();
                        Navigator.pop(context);
                      },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black54,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Cancel'),
              ),
            ),
              ],
            ),
          );
        },
      ),
    );
  }
}



