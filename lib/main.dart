import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

void main() {
  print("main: started");
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
  print("main: runApp called");
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    print("MyApp.build: called");
    return MaterialApp(
      debugShowCheckedModeBanner: false,
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
  State<SubscriptionTestScreen> createState() =>
      _SubscriptionTestScreenState();
}

class _SubscriptionTestScreenState extends State<SubscriptionTestScreen> {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;

  /// 🔥 PRODUCT IDS
  /// لازم يكونوا مطابقين 100% للي هتكتبهم في كل Store

  static const String _androidProductId =
      'billing_test_monthly'; // ✅ Google Play product id

  static const String _iosProductId =
      'billing_test_monthly_ios'; // ✅ App Store product id

  late final String _subscriptionProductId;

  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool _isAvailable = false;
  bool _isLoading = false;
  String _statusMessage = 'Initializing...';

  ProductDetails? _product;

  /// Android → purchaseToken
  /// iOS → receipt (base64)
  String? _purchasedProductId;
  String? _purchasePayload;

  @override
  void initState() {
    super.initState();
    print("SubscriptionTestScreen.initState: called");

    /// Detect platform automatically
    _subscriptionProductId =
        Platform.isIOS ? _iosProductId : _androidProductId;
    print("SubscriptionTestScreen.initState: platform detected as ${Platform.operatingSystem}");

    _initializeBilling();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeBilling() async {
    print("_initializeBilling: called");
    try {
      final available = await _inAppPurchase.isAvailable();
      print("_initializeBilling: isAvailable() returned $available");

      setState(() {
        _isAvailable = available;
        _statusMessage =
            available ? 'Billing ready ✅' : 'Billing not available ❌';
      });

      if (!available) {
        print("_initializeBilling: billing not available, returning");
        return;
      }

      _subscription = _inAppPurchase.purchaseStream.listen(
        _onPurchaseUpdate,
        onDone: () {
          print("_initializeBilling: purchaseStream onDone");
          _subscription?.cancel();
        },
        onError: (error) {
          print("_initializeBilling: purchaseStream onError: $error");
          setState(() {
            _statusMessage = 'Purchase error: $error';
          });
        },
      );
      print("_initializeBilling: purchaseStream listener set up");

      await _queryProduct();
    } catch (e) {
      print("_initializeBilling: caught error: $e");
      setState(() {
        _statusMessage = 'Initialization error: $e';
      });
    }
  }

  Future<void> _queryProduct() async {
    print("_queryProduct: called");
    setState(() {
      _isLoading = true;
      _statusMessage = 'Querying product...';
    });

    try {
      final response =
          await _inAppPurchase.queryProductDetails({_subscriptionProductId});
      print("_queryProduct: queryProductDetails returned");

      if (response.error != null) {
        print("_queryProduct: queryProductDetails error: ${response.error}");
        setState(() {
          _isLoading = false;
          _statusMessage = 'Error querying product: ${response.error!.message}';
        });
        return;
      }

      if (response.notFoundIDs.isNotEmpty) {
        print("_queryProduct: product not found: ${response.notFoundIDs}");
        setState(() {
          _isLoading = false;
          _statusMessage =
              'Product not found ⚠️ Check Store configuration.';
        });
        return;
      }

      print("_queryProduct: product found: ${response.productDetails.first.id}");
      setState(() {
        _product = response.productDetails.first;
        _isLoading = false;
        _statusMessage = 'Product loaded successfully 🎉';
      });
    } catch (e) {
      print("_queryProduct: caught error: $e");
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error querying product: $e';
      });
    }
  }

  Future<void> _startSubscription() async {
    if (_product == null) return;

    setState(() {
      _isLoading = true;
      _statusMessage = 'Starting purchase flow...';
    });

    final purchaseParam = PurchaseParam(
      productDetails: _product!,
    );

    /// ✔️ Correct for subscriptions in this plugin
    await _inAppPurchase.buyNonConsumable(
      purchaseParam: purchaseParam,
    );
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    print("_onPurchaseUpdate: called with ${purchases.length} purchases");
    for (final purchase in purchases) {
      print("_onPurchaseUpdate: processing purchase with status ${purchase.status}");
      if (purchase.status == PurchaseStatus.pending) {
        setState(() {
          _statusMessage = 'Purchase pending...';
        });
      }

      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        _purchasedProductId = purchase.productID;

        /// 🔥 IMPORTANT
        /// Android → purchaseToken
        /// iOS → receipt
        _purchasePayload =
            purchase.verificationData.serverVerificationData;

        setState(() {
          _statusMessage = 'Purchase successful 🎉';
          _isLoading = false;
        });
      }

      if (purchase.status == PurchaseStatus.error) {
        print("_onPurchaseUpdate: purchase error: ${purchase.error}");
        setState(() {
          _statusMessage =
              'Purchase failed: ${purchase.error?.message}';
          _isLoading = false;
        });
      }

      /// VERY IMPORTANT — Apple ممكن ترفض build لو نسيتها
      if (purchase.pendingCompletePurchase) {
        print("_onPurchaseUpdate: completing purchase");
        _inAppPurchase.completePurchase(purchase);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print("SubscriptionTestScreen.build: called");
    return Scaffold(
      appBar: AppBar(
        title: const Text('Billing Test App'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Subscription Test',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            if (_product != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _product!.title,
                        style:
                            const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(_product!.description),
                      const SizedBox(height: 8),
                      Text(
                        _product!.price,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed:
                  (_isAvailable && !_isLoading && _product != null)
                      ? _startSubscription
                      : null,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Subscribe'),
            ),

            const SizedBox(height: 24),

            Card(
              color: Colors.grey.shade100,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_statusMessage),

                    if (_purchasedProductId != null) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Product ID:',
                        style:
                            TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SelectableText(_purchasedProductId!),
                    ],

                    if (_purchasePayload != null) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Purchase Token / Receipt:',
                        style:
                            TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SelectableText(
                        _purchasePayload!,
                        maxLines: null,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
