import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/payment_provider.dart';

class PaypalWebviewScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final String shippingAddress;
  final String phone;
  final String province;
  final double shippingCost;
  final String paymentToken;

  const PaypalWebviewScreen({
    super.key,
    required this.cartItems,
    required this.shippingAddress,
    required this.phone,
    required this.province,
    required this.shippingCost,
    required this.paymentToken,
  });

  @override
  State<PaypalWebviewScreen> createState() => _PaypalWebviewScreenState();
}

class _PaypalWebviewScreenState extends State<PaypalWebviewScreen> {
  late WebViewController _webViewController;
  bool _isLoading = true;
  String? _error;
  bool _isConfirming = false; // Prevent multiple confirmations

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            print('🔄 WebView page started: $url');
            // Only show loading for our own URLs, not PayPal pages
            if (!url.contains('paypal.com') && !url.contains('sandbox.paypal.com')) {
              setState(() => _isLoading = true);
            }
            _handleRedirect(url);
          },
          onPageFinished: (String url) {
            print('✅ WebView page finished: $url');
            _handleRedirect(url);
            setState(() => _isLoading = false);
          },
          onWebResourceError: (WebResourceError error) {
            print('❌ WebView error: ${error.description}');
            
            // Handle cleartext (HTTP) error - common on Android 9+ for sandbox URLs
            if (error.description.contains('ERR_CLEARTEXT_NOT_PERMITTED') ||
                error.description.contains('net::ERR_') ||
                error.description.contains('Failed to load')) {
              print('⚠️ WebView cannot load URL (HTTP/sandbox limitation)');
              print('📱 This is normal for PayPal sandbox on Android 9+');
              print('💡 The payment confirmation will still work via backend');
              
              // Don't reset state - wait for redirect or manual confirmation
              // The backend confirmation should handle it
              return;
            }
            
            setState(() {
              _isLoading = false;
              _error = error.description;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url;
            print('🌐 WebView navigation request: $url');
            _handleRedirect(url);
            return NavigationDecision.navigate;
          },
        ),
      );

    // Load the PayPal approval URL
    _loadPayPalPage();
  }

  Future<void> _loadPayPalPage() async {
    try {
      final paymentProvider = context.read<PaymentProvider>();

      print('🔄 Creating PayPal order...');
      final approvalUrl = await paymentProvider.createPayPalOrder(
        token: widget.paymentToken,
        cartItems: widget.cartItems,
        shippingAddress: widget.shippingAddress,
        phone: widget.phone,
        province: widget.province,
        shippingCost: widget.shippingCost,
      );

      if (approvalUrl == null || approvalUrl.isEmpty) {
        setState(() {
          _error = paymentProvider.error ?? 'Failed to create PayPal order';
          _isLoading = false;
        });
        return;
      }

      print('✅ Order created successfully');
      print('📱 Loading approval URL: $approvalUrl');
      print('✅ PayPal Order ID has been stored: ${paymentProvider.currentPayPalOrderId}');
      
      // Ensure the order ID is stored for later confirmation
      // Do NOT call clearPayment() as it would clear the order ID!
      print('📦 PayPal Order ID stored: ${paymentProvider.currentPayPalOrderId}');

      // Load the approval URL in WebView
      await _webViewController.loadRequest(Uri.parse(approvalUrl));
    } catch (e) {
      print('❌ Error loading PayPal page: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _handleRedirect(String url) {
    print('🔍 Checking redirect: $url');
    
    // Skip if already confirming
    if (_isConfirming) {
      print('⏳ Already confirming, skipping duplicate redirect check');
      return;
    }

    // ONLY trigger on return_url redirects (after user authorizes on PayPal)
    // PayPal redirects back to your return_url with success or cancel
    if (url.startsWith('com.example.accessora://payment-success')) {
      print('✅ SUCCESS redirect detected! User authorized payment on PayPal');
      _isConfirming = true;
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _confirmPayment(url);
        }
      });
      return;
    }

    if (url.startsWith('com.example.accessora://payment-cancel')) {
      print('⚠️ CANCEL redirect detected! User cancelled on PayPal');
      _isConfirming = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext dialogContext) {
              return AlertDialog(
                title: const Row(
                  children: [
                    Icon(Icons.cancel_outlined, color: Colors.orange, size: 28),
                    SizedBox(width: 12),
                    Text('Payment Cancelled'),
                  ],
                ),
                content: const Text(
                  'You cancelled the payment. No charges were made.',
                  style: TextStyle(fontSize: 14),
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop(); // Close dialog
                      Navigator.of(context).pop(); // Close WebView
                    },
                    child: const Text('Back to Payment'),
                  ),
                ],
              );
            },
          );
        }
      });
      return;
    }

    print('📱 Regular PayPal page navigation, continuing...');
  }

  Future<void> _confirmPayment(String redirectUrl) async {
    try {
      final paymentProvider = context.read<PaymentProvider>();

      print('📝 Confirming payment...');
      print('📊 Current PayPal Order ID: ${paymentProvider.currentPayPalOrderId}');
      
      // Validate that we have the order ID
      if (paymentProvider.currentPayPalOrderId == null || 
          paymentProvider.currentPayPalOrderId!.isEmpty) {
        throw Exception('No PayPal Order ID found. Please try the payment again.');
      }

      // Confirm the payment with backend
      final confirmed = await paymentProvider.confirmPayPalPayment(
        token: widget.paymentToken,
        cartItems: widget.cartItems,
        shippingAddress: widget.shippingAddress,
        phone: widget.phone,
        province: widget.province,
        shippingCost: widget.shippingCost,
      );

      if (confirmed != null) {
        print('✅ Payment confirmed successfully!');
        
        if (mounted) {
          // Use addPostFrameCallback to defer navigation until after current frame
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              // Show success dialog - keep webview mounted
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext dialogContext) {
                  return AlertDialog(
                    title: const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 28),
                        SizedBox(width: 12),
                        Text('Payment Successful!'),
                      ],
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Your payment has been confirmed.'),
                        const SizedBox(height: 12),
                        Text(
                          'Order ID: ${confirmed['orderId']}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Amount: \$${confirmed['order']['totalPrice']}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      ElevatedButton(
                        onPressed: () {
                          // Navigate to orders - this will close the webview and dialog automatically
                          Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
                            '/orders',
                            (route) => route.isFirst,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00D9FF),
                          foregroundColor: Colors.black,
                        ),
                        child: const Text('View Orders'),
                      ),
                    ],
                  );
                },
              );
            }
          });
        }
      } else {
        throw Exception(paymentProvider.error ?? 'Failed to confirm payment');
      }
    } catch (e) {
      print('❌ Error confirming payment: $e');
      _isConfirming = false;
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 28),
                  SizedBox(width: 12),
                  Text('Payment Error'),
                ],
              ),
              content: Text(
                'Error: ${e.toString()}',
                style: const TextStyle(fontSize: 14),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(); // Close dialog
                    Navigator.of(context).pop(); // Close WebView
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Back to Payment'),
                ),
              ],
            );
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PayPal Payment'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 2,
      ),
      body: Stack(
        children: [
          if (_error != null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            )
          else
            WebViewWidget(controller: _webViewController),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(Color(0xFF00D9FF)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
