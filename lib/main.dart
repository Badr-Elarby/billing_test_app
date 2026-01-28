import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Billing Test App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SubscriptionTestScreen(),
    );
  }
}

class SubscriptionTestScreen extends StatefulWidget {
  const SubscriptionTestScreen({super.key});

  @override
  State<SubscriptionTestScreen> createState() => _SubscriptionTestScreenState();
}

class _SubscriptionTestScreenState extends State<SubscriptionTestScreen> {
  // ============================================================
  // STEP 1: Initialize InAppPurchase instance
  // ============================================================
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;

  // ============================================================
  // STEP 2: Define subscription product ID
  // TODO: Replace with your actual Google Play subscription product ID
  // ============================================================
  static const String _subscriptionProductId = 'billing_test_monthly';

  // Stream subscription for purchase updates
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  // UI state
  bool _isAvailable = false;
  bool _isLoading = false;
  String _statusMessage = 'Initializing...';
  ProductDetails? _product;
  String? _purchasedProductId;
  String? _purchasedToken;

  @override
  void initState() {
    super.initState();
    _initializeBilling();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  // ============================================================
  // STEP 3: Initialize billing and listen to purchase updates
  // ============================================================
  Future<void> _initializeBilling() async {
    // Check if in-app purchase is available on this device
    final bool available = await _inAppPurchase.isAvailable();

    setState(() {
      _isAvailable = available;
      _statusMessage = available
          ? 'Billing ready. Tap Subscribe to test.'
          : 'Billing not available on this device';
    });

    if (!available) {
      debugPrint('❌ In-app purchase not available');
      return;
    }

    // ============================================================
    // STEP 4: Listen to purchase updates stream
    // This is where we receive purchase status, productId, and purchaseToken
    // ============================================================
    _subscription = _inAppPurchase.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () {
        debugPrint('🔵 Purchase stream done');
      },
      onError: (error) {
        debugPrint('❌ Purchase stream error: $error');
        setState(() {
          _statusMessage = 'Error: $error';
        });
      },
    );

    // Query the subscription product
    await _queryProduct();
  }

  // ============================================================
  // STEP 5: Query subscription product by ID
  // ============================================================
  Future<void> _queryProduct() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Querying product...';
    });

    final ProductDetailsResponse response = await _inAppPurchase
        .queryProductDetails({_subscriptionProductId});

    if (response.error != null) {
      debugPrint('❌ Error querying products: ${response.error}');
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error querying product: ${response.error!.message}';
      });
      return;
    }

    if (response.productDetails.isEmpty) {
      debugPrint('⚠️ No products found for ID: $_subscriptionProductId');
      setState(() {
        _isLoading = false;
        _statusMessage =
            'Product not found. Check product ID in Google Play Console.';
      });
      return;
    }

    // Product found successfully
    final product = response.productDetails.first;
    debugPrint('✅ Product found: ${product.id} - ${product.title}');
    debugPrint('   Price: ${product.price}');
    debugPrint('   Description: ${product.description}');

    setState(() {
      _product = product;
      _isLoading = false;
      _statusMessage = 'Product loaded: ${product.title}';
    });
  }

  // ============================================================
  // STEP 6: Handle Subscribe button press - Start purchase flow
  // ============================================================
  Future<void> _startSubscription() async {
    if (_product == null) {
      setState(() {
        _statusMessage = 'Product not loaded. Cannot start purchase.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Starting purchase flow...';
    });

    debugPrint('🚀 Starting subscription purchase for: ${_product!.id}');

    // Create purchase param for subscription
    final PurchaseParam purchaseParam = PurchaseParam(
      productDetails: _product!,
    );

    // Start the purchase flow
    try {
      final bool success = await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );

      if (!success) {
        debugPrint('❌ Failed to start purchase flow');
        setState(() {
          _isLoading = false;
          _statusMessage = 'Failed to start purchase';
        });
      } else {
        debugPrint('✅ Purchase flow started successfully');
      }
    } catch (e) {
      debugPrint('❌ Exception starting purchase: $e');
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error: $e';
      });
    }
  }

  // ============================================================
  // STEP 7: Handle purchase updates
  // This is where we log purchaseStatus, productId, and purchaseToken
  // ============================================================
  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('📦 PURCHASE UPDATE RECEIVED');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('🔹 Purchase Status: ${purchaseDetails.status}');
      debugPrint('🔹 Product ID: ${purchaseDetails.productID}');
      debugPrint(
        '🔹 Purchase Token: ${purchaseDetails.verificationData.serverVerificationData}',
      );
      debugPrint('🔹 Transaction Date: ${purchaseDetails.transactionDate}');
      debugPrint('🔹 Purchase ID: ${purchaseDetails.purchaseID}');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      // Update UI based on purchase status
      setState(() {
        _isLoading = false;

        switch (purchaseDetails.status) {
          case PurchaseStatus.pending:
            _statusMessage = '⏳ Purchase pending...';
            debugPrint('⏳ Purchase is pending');
            break;

          case PurchaseStatus.purchased:
            _purchasedProductId = purchaseDetails.productID;
            _purchasedToken =
                purchaseDetails.verificationData.serverVerificationData;
            _statusMessage =
                '✅ Purchase successful!\nToken: ${purchaseDetails.verificationData.serverVerificationData}';
            debugPrint('✅ Purchase completed successfully');
            debugPrint(
              '💡 Use this token for backend verification and lifecycle testing',
            );
            break;

          case PurchaseStatus.error:
            _statusMessage =
                '❌ Purchase failed: ${purchaseDetails.error?.message ?? "Unknown error"}';
            debugPrint('❌ Purchase error: ${purchaseDetails.error}');
            break;

          case PurchaseStatus.restored:
            _statusMessage = '🔄 Purchase restored';
            debugPrint('🔄 Purchase restored');
            break;

          case PurchaseStatus.canceled:
            _statusMessage = '🚫 Purchase canceled by user';
            debugPrint('🚫 Purchase canceled');
            break;
        }
      });

      // ============================================================
      // STEP 8: Complete the purchase
      // Important: Always complete the purchase to acknowledge it
      // ============================================================
      if (purchaseDetails.pendingCompletePurchase) {
        _inAppPurchase.completePurchase(purchaseDetails);
        debugPrint('✅ Purchase completed and acknowledged');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Billing Test App'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // App title
              const Text(
                'Google Play Subscription Test',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Product info (if loaded)
              if (_product != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _product!.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(_product!.description),
                        const SizedBox(height: 8),
                        Text(
                          _product!.price,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Subscribe button
              ElevatedButton(
                onPressed: (_isAvailable && !_isLoading && _product != null)
                    ? _startSubscription
                    : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Subscribe', style: TextStyle(fontSize: 18)),
              ),

              const SizedBox(height: 32),

              // Status message
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _statusMessage,
                      style: const TextStyle(fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    if (_purchasedProductId != null &&
                        _purchasedToken != null) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Product ID:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SelectableText(
                        _purchasedProductId!,
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Purchase Token:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SelectableText(
                        _purchasedToken!,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Instructions
            ],
          ),
        ),
      ),
    );
  }
}
