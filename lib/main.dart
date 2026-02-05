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
  /// لازم يكونوا مطابقين 100% للي في App Store Connect / Google Play Console
  static const String _androidProductId = 'billing_test_monthly';
  static const String _iosProductId = 'billing_test_monthly_ios';

  late final String _subscriptionProductId;

  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool _isAvailable = false;
  bool _isLoading = false;
  String _statusMessage = 'Initializing...';
  String? _detailedDiagnostics; // ✅ للتشخيص المفصّل

  ProductDetails? _product;

  String? _purchasedProductId;
  String? _purchasePayload;

  @override
  void initState() {
    super.initState();
    print("SubscriptionTestScreen.initState: called");

    _subscriptionProductId =
        Platform.isIOS ? _iosProductId : _androidProductId;
    print(
        "SubscriptionTestScreen.initState: platform=${Platform.operatingSystem}, productId=$_subscriptionProductId");

    _initializeBilling();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  /// ✅ محسّنة: الـ listener بيتعمل قبل الـ query
  Future<void> _initializeBilling() async {
    print("_initializeBilling: called");
    
    setState(() {
      _isLoading = true;
      _statusMessage = 'Checking billing availability...';
    });

    try {
      // ✅ 1. تأكد إن الـ billing متاح
      final available = await _inAppPurchase.isAvailable();
      print("_initializeBilling: isAvailable()=$available");

      if (!available) {
        print("_initializeBilling: billing NOT available");
        setState(() {
          _isAvailable = false;
          _isLoading = false;
          _statusMessage = 'Billing not available ❌';
          _detailedDiagnostics = Platform.isIOS
              ? 'Check: Device is signed into Sandbox Apple ID?\nSettings → Developer → Sandbox Account'
              : 'Check: Google Play services installed?';
        });
        return;
      }

      // ✅ 2. ابدأ الاستماع للـ purchases قبل الـ query (best practice)
      _subscription = _inAppPurchase.purchaseStream.listen(
        _onPurchaseUpdate,
        onDone: () {
          print("_initializeBilling: purchaseStream onDone");
        },
        onError: (error) {
          print("_initializeBilling: purchaseStream error=$error");
          setState(() {
            _statusMessage = 'Purchase stream error ⚠️';
            _detailedDiagnostics = error.toString();
          });
        },
      );
      print("_initializeBilling: purchaseStream listener attached");

      setState(() {
        _isAvailable = true;
        _statusMessage = 'Billing ready ✅ Querying product...';
      });

      // ✅ 3. استعلم عن المنتج
      await _queryProduct();
      
    } catch (e, stackTrace) {
      print("_initializeBilling: EXCEPTION=$e");
      print("_initializeBilling: stackTrace=$stackTrace");
      setState(() {
        _isLoading = false;
        _statusMessage = 'Initialization error ❌';
        _detailedDiagnostics = e.toString();
      });
    }
  }

  /// ✅ محسّنة: diagnostics مفصّلة لكل حالة
  Future<void> _queryProduct() async {
    print("_queryProduct: querying productId=$_subscriptionProductId");
    
    setState(() {
      _isLoading = true;
      _statusMessage = 'Querying product from store...';
      _detailedDiagnostics = null;
    });

    try {
      final response =
          await _inAppPurchase.queryProductDetails({_subscriptionProductId});
      print("_queryProduct: query completed");

      // ✅ Case 1: Platform error
      if (response.error != null) {
        final errorMsg = response.error!.message;
        final errorCode = response.error!.code;
        print("_queryProduct: ERROR code=$errorCode, message=$errorMsg");
        
        setState(() {
          _isLoading = false;
          _statusMessage = 'Query failed ❌';
          _detailedDiagnostics = 'Error code: $errorCode\n'
              'Message: $errorMsg\n\n'
              '${Platform.isIOS ? 'iOS troubleshooting:\n'
                  '• Check device is signed into Sandbox account\n'
                  '• Settings → App Store → Sign Out\n'
                  '• Settings → Developer → Sandbox Account → Sign In\n'
                  '• Wait 30-60 min after creating product in App Store Connect'
                  : 'Android troubleshooting:\n'
                  '• Check product exists in Google Play Console\n'
                  '• Product must be Active\n'
                  '• Check license testing account'}';
        });
        return;
      }

      // ✅ Case 2: Product ID not found
      if (response.notFoundIDs.isNotEmpty) {
        print("_queryProduct: NOT FOUND ids=${response.notFoundIDs}");
        
        setState(() {
          _isLoading = false;
          _statusMessage = 'Product NOT FOUND ⚠️';
          _detailedDiagnostics = 'Missing product IDs: ${response.notFoundIDs.join(", ")}\n\n'
              'Expected: $_subscriptionProductId\n\n'
              '${Platform.isIOS ? 'iOS checks:\n'
                  '✓ Product ID exact match in App Store Connect?\n'
                  '✓ Product has price + localization?\n'
                  '✓ Product is "Ready to Submit" or approved?\n'
                  '✓ Same Bundle ID (com.smartapps.billingtest)?\n'
                  '✓ Device signed into Sandbox account?\n'
                  '✓ Waited 30-60 min after product creation?'
                  : 'Android checks:\n'
                  '✓ Product ID exact match in Play Console?\n'
                  '✓ Product is Active (not Draft)?\n'
                  '✓ App is published (internal test track OK)?\n'
                  '✓ License tester account configured?'}';
        });
        return;
      }

      // ✅ Case 3: Empty response (shouldn't happen but handle it)
      if (response.productDetails.isEmpty) {
        print("_queryProduct: EMPTY productDetails (unexpected)");
        
        setState(() {
          _isLoading = false;
          _statusMessage = 'No products returned ⚠️';
          _detailedDiagnostics = 'Query returned empty.\n'
              'Check store configuration and propagation time.';
        });
        return;
      }

      // ✅ Case 4: SUCCESS!
      final product = response.productDetails.first;
      print("_queryProduct: SUCCESS id=${product.id}, "
          "price=${product.price}, title=${product.title}");
      
      setState(() {
        _product = product;
        _isLoading = false;
        _statusMessage = 'Product loaded successfully 🎉';
        _detailedDiagnostics = 'ID: ${product.id}\n'
            'Title: ${product.title}\n'
            'Price: ${product.price}\n'
            'Description: ${product.description}';
      });
      
    } catch (e, stackTrace) {
      print("_queryProduct: EXCEPTION=$e");
      print("_queryProduct: stackTrace=$stackTrace");
      
      setState(() {
        _isLoading = false;
        _statusMessage = 'Query error ❌';
        _detailedDiagnostics = e.toString();
      });
    }
  }

  Future<void> _startSubscription() async {
    if (_product == null) {
      print("_startSubscription: product is null, aborting");
      return;
    }

    print("_startSubscription: starting purchase for ${_product!.id}");
    
    setState(() {
      _isLoading = true;
      _statusMessage = 'Starting purchase flow...';
      _detailedDiagnostics = null;
    });

    try {
      final purchaseParam = PurchaseParam(productDetails: _product!);

      // ✅ buyNonConsumable صح للـ subscriptions في الـ plugin ده
      final result = await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );
      
      print("_startSubscription: buyNonConsumable returned=$result");
      
      if (!result) {
        print("_startSubscription: purchase initiation failed");
        setState(() {
          _isLoading = false;
          _statusMessage = 'Failed to start purchase ❌';
          _detailedDiagnostics = 'Platform rejected purchase request.\n'
              'Check payment method configuration.';
        });
      }
      
    } catch (e, stackTrace) {
      print("_startSubscription: EXCEPTION=$e");
      print("_startSubscription: stackTrace=$stackTrace");
      
      setState(() {
        _isLoading = false;
        _statusMessage = 'Purchase error ❌';
        _detailedDiagnostics = e.toString();
      });
    }
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    print("_onPurchaseUpdate: received ${purchases.length} purchase(s)");
    
    for (final purchase in purchases) {
      print("_onPurchaseUpdate: processing productId=${purchase.productID}, "
          "status=${purchase.status}");

      // ✅ Pending
      if (purchase.status == PurchaseStatus.pending) {
        setState(() {
          _statusMessage = 'Purchase pending... ⏳';
          _detailedDiagnostics = 'Waiting for payment confirmation.';
        });
      }

      // ✅ Purchased or Restored
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        print("_onPurchaseUpdate: SUCCESS for ${purchase.productID}");
        
        _purchasedProductId = purchase.productID;
        _purchasePayload = purchase.verificationData.serverVerificationData;

        setState(() {
          _statusMessage = purchase.status == PurchaseStatus.purchased
              ? 'Purchase successful! 🎉'
              : 'Subscription restored! 🎉';
          _isLoading = false;
          _detailedDiagnostics = 'Product: ${purchase.productID}\n'
              'Transaction ID: ${purchase.purchaseID ?? "N/A"}\n'
              'Payload available for server verification ✓';
        });
      }

      // ✅ Error
      if (purchase.status == PurchaseStatus.error) {
        final errorCode = purchase.error?.code ?? 'unknown';
        final errorMsg = purchase.error?.message ?? 'Unknown error';
        print("_onPurchaseUpdate: ERROR code=$errorCode, message=$errorMsg");
        
        setState(() {
          _statusMessage = 'Purchase failed ❌';
          _isLoading = false;
          _detailedDiagnostics = 'Error code: $errorCode\n'
              'Message: $errorMsg\n\n'
              '${errorCode == 'storekit_user_cancelled' || errorCode == '1' 
                  ? 'User cancelled the purchase.' 
                  : 'Check payment method or store configuration.'}';
        });
      }

      // ✅ Canceled
      if (purchase.status == PurchaseStatus.canceled) {
        print("_onPurchaseUpdate: CANCELED");
        setState(() {
          _statusMessage = 'Purchase canceled by user';
          _isLoading = false;
        });
      }

      // ✅ CRITICAL: Complete the purchase (Apple يرفض الـ build لو ناسيها)
      if (purchase.pendingCompletePurchase) {
        print("_onPurchaseUpdate: completing purchase for ${purchase.productID}");
        _inAppPurchase.completePurchase(purchase);
      }
    }
  }

  /// ✅ زرار Retry للـ query
  void _retryQuery() {
    print("_retryQuery: manual retry triggered");
    _queryProduct();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Billing Test App'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ✅ Header
            Text(
              'Subscription Test',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              Platform.isIOS ? 'iOS (TestFlight)' : 'Android',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              'Product ID: $_subscriptionProductId',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 24),

            // ✅ Product Card
            if (_product != null)
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _product!.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(_product!.description),
                      const SizedBox(height: 12),
                      Text(
                        _product!.price,
                        style: const TextStyle(
                          fontSize: 24,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // ✅ Subscribe Button
            ElevatedButton(
              onPressed: (_isAvailable && !_isLoading && _product != null)
                  ? _startSubscription
                  : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Subscribe Now',
                      style: TextStyle(fontSize: 16),
                    ),
            ),

            // ✅ Retry Button (لو الـ query فشل)
            if (!_isLoading && _product == null && _isAvailable) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _retryQuery,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry Query'),
              ),
            ],

            const SizedBox(height: 24),

            // ✅ Status Card
            Card(
              color: Colors.grey.shade100,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getStatusIcon(),
                          color: _getStatusColor(),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _statusMessage,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    // ✅ Detailed Diagnostics
                    if (_detailedDiagnostics != null) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      const Text(
                        'Details:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        _detailedDiagnostics!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],

                    // ✅ Purchase Info
                    if (_purchasedProductId != null) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      const Text(
                        'Purchased Product:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        _purchasedProductId!,
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ],

                    if (_purchasePayload != null) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Verification Data:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: SelectableText(
                          _purchasePayload!,
                          style: const TextStyle(
                            fontSize: 10,
                            fontFamily: 'monospace',
                          ),
                          maxLines: 5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '💡 Send this to your backend for verification',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
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

  /// ✅ Helper: Status icon
  IconData _getStatusIcon() {
    if (_statusMessage.contains('🎉')) return Icons.check_circle;
    if (_statusMessage.contains('❌')) return Icons.error;
    if (_statusMessage.contains('⚠️')) return Icons.warning;
    if (_statusMessage.contains('⏳')) return Icons.hourglass_empty;
    if (_isLoading) return Icons.sync;
    return Icons.info;
  }

  /// ✅ Helper: Status color
  Color _getStatusColor() {
    if (_statusMessage.contains('🎉')) return Colors.green;
    if (_statusMessage.contains('❌')) return Colors.red;
    if (_statusMessage.contains('⚠️')) return Colors.orange;
    if (_isLoading) return Colors.blue;
    return Colors.grey;
  }
}

