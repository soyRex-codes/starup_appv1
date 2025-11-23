import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Apple In-App Purchase Service
/// Handles premium subscription purchases on iOS using StoreKit
///
/// Product IDs (must match App Store Connect):
/// - com.foundervers.mobile.premium.monthly
/// - com.foundervers.mobile.premium.annual
class IAPService {
  static final IAPService _instance = IAPService._internal();
  factory IAPService() => _instance;
  IAPService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;
  final _supabase = Supabase.instance.client;

  // Product IDs - MUST match exactly with App Store Connect
  static const String monthlyProductId =
      'com.foundervers.mobile.premium.monthly';
  static const String annualProductId = 'com.foundervers.mobile.premium.annual';

  // Pricing (for display purposes)
  static const double monthlyPrice = 19.99;
  static const double annualPrice = 167.99;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  List<ProductDetails> _products = [];
  List<String> _notFoundIds = [];
  String? _lastError;
  bool _isAvailable = false;
  bool _isInitialized = false;

  // Diagnostics getters
  List<String> get notFoundIds => _notFoundIds;
  String? get lastError => _lastError;
  bool get isAvailable => _isAvailable;
  bool get isInitialized => _isInitialized;

  /// Initialize IAP service
  /// Returns true if IAP is available on this device
  Future<bool> initialize() async {
    if (_isInitialized) return _isAvailable;

    try {
      if (!Platform.isIOS) {
        debugPrint('⚠️ IAP: Not on iOS, skipping initialization');
        return false;
      }

      _isAvailable = await _iap.isAvailable();

      if (!_isAvailable) {
        debugPrint('⚠️ IAP: Not available on this device');
        return false;
      }

      debugPrint('✅ IAP: Service available');

      // Load products from App Store
      await _loadProducts();

      // Listen to purchase updates
      _purchaseSubscription = _iap.purchaseStream.listen(
        _handlePurchaseUpdates,
        onError: (error) {
          debugPrint('❌ IAP: Purchase stream error: $error');
        },
        onDone: () {
          debugPrint('🔵 IAP: Purchase stream closed');
        },
      );

      _isInitialized = true;
      return true;
      _isInitialized = true;
      return true;
    } catch (e) {
      _lastError = 'Initialization failed: $e';
      debugPrint('❌ IAP: $_lastError');
      return false;
    }
  }

  /// Load product details from App Store
  Future<void> _loadProducts() async {
    try {
      final productIds = {monthlyProductId, annualProductId};

      debugPrint('🔍 IAP: Fetching products: $productIds');

      final response = await _iap.queryProductDetails(productIds);

      if (response.error != null) {
        _lastError = 'Product query error: ${response.error}';
        debugPrint('❌ IAP: $_lastError');
        return;
      }

      _notFoundIds = response.notFoundIDs;
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('⚠️ IAP: Products not found: ${response.notFoundIDs}');
      }

      _products = response.productDetails;

      debugPrint('✅ IAP: Loaded ${_products.length} products');
      for (var product in _products) {
        debugPrint('   📦 ${product.id}: ${product.title} - ${product.price}');
      }
    } catch (e) {
      _lastError = 'Failed to load products: $e';
      debugPrint('❌ IAP: $_lastError');
    }
  }

  /// Get available products
  List<ProductDetails> get products => _products;

  /// Get monthly subscription product
  ProductDetails? get monthlyProduct =>
      _products.firstWhere((p) => p.id == monthlyProductId,
          orElse: () => _products.first);

  /// Get annual subscription product
  ProductDetails? get annualProduct =>
      _products.firstWhere((p) => p.id == annualProductId,
          orElse: () => _products.first);

  /// Purchase a subscription
  Future<Map<String, dynamic>> purchaseSubscription({
    required bool isAnnual,
    required String userId,
  }) async {
    try {
      if (!_isAvailable) {
        return {
          'success': false,
          'message': 'In-App Purchase is not available on this device',
        };
      }

      if (_products.isEmpty) {
        await _loadProducts();
        if (_products.isEmpty) {
          return {
            'success': false,
            'message': 'No subscription products available',
          };
        }
      }

      final product = isAnnual ? annualProduct : monthlyProduct;

      if (product == null) {
        return {
          'success': false,
          'message': 'Subscription product not found',
        };
      }

      debugPrint('🛒 IAP: Starting purchase for ${product.id}');
      debugPrint('👤 User ID: $userId');

      // Create purchase param
      final purchaseParam = PurchaseParam(
        productDetails: product,
        applicationUserName: userId, // Link purchase to user
      );

      // Initiate purchase flow
      final bool purchaseStarted = await _iap.buyNonConsumable(
        purchaseParam: purchaseParam,
      );

      if (!purchaseStarted) {
        return {
          'success': false,
          'message': 'Failed to start purchase flow',
        };
      }

      // Purchase flow started, user will see Apple payment sheet
      // Result will be delivered via _handlePurchaseUpdates
      return {
        'success': true,
        'message': 'Purchase flow started',
        'pending': true,
      };
    } catch (e) {
      debugPrint('❌ IAP: Purchase error: $e');
      return {
        'success': false,
        'message': 'Purchase failed: ${e.toString()}',
      };
    }
  }

  /// Handle purchase updates from Apple
  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (var purchase in purchases) {
      debugPrint('🔔 IAP: Purchase update - Status: ${purchase.status}');

      if (purchase.status == PurchaseStatus.pending) {
        debugPrint('⏳ IAP: Purchase pending...');
      } else if (purchase.status == PurchaseStatus.error) {
        debugPrint('❌ IAP: Purchase error: ${purchase.error}');
        // Complete the purchase to remove from queue
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
      } else if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        // Verify and activate subscription
        await _verifyAndActivatePurchase(purchase);

        // Complete the purchase
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
      } else if (purchase.status == PurchaseStatus.canceled) {
        debugPrint('🚫 IAP: Purchase canceled by user');
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
      }
    }
  }

  /// Verify purchase with Apple and activate premium subscription
  Future<void> _verifyAndActivatePurchase(PurchaseDetails purchase) async {
    try {
      debugPrint('🔐 IAP: Verifying purchase: ${purchase.productID}');

      final userId = _supabase.auth.currentUser?.id;

      if (userId == null) {
        debugPrint('❌ IAP: No user ID available');
        return;
      }

      // Determine subscription type from product ID
      final isAnnual = purchase.productID == annualProductId;
      final subscriptionType = isAnnual ? 'annual' : 'monthly';

      // Calculate expiration date
      final expiresAt = DateTime.now().add(
        Duration(days: isAnnual ? 365 : 30),
      );

      // Call Supabase Edge Function to verify receipt and activate
      debugPrint('📡 IAP: Calling verification Edge Function');

      final response = await _supabase.functions.invoke(
        'verify-apple-purchase',
        body: {
          'userId': userId,
          'productId': purchase.productID,
          'transactionId': purchase.purchaseID,
          'verificationData': purchase.verificationData.serverVerificationData,
          'subscriptionType': subscriptionType,
          'expiresAt': expiresAt.toIso8601String(),
        },
      );

      if (response.status == 200) {
        debugPrint('✅ IAP: Purchase verified and activated');
      } else {
        debugPrint('❌ IAP: Verification failed: ${response.data}');
      }
    } catch (e) {
      debugPrint('❌ IAP: Verification error: $e');
    }
  }

  /// Restore previous purchases
  Future<Map<String, dynamic>> restorePurchases() async {
    try {
      if (!_isAvailable) {
        return {
          'success': false,
          'message': 'In-App Purchase is not available',
        };
      }

      debugPrint('🔄 IAP: Restoring purchases...');

      await _iap.restorePurchases();

      // Restored purchases will be delivered via _handlePurchaseUpdates
      return {
        'success': true,
        'message': 'Restore initiated',
      };
    } catch (e) {
      debugPrint('❌ IAP: Restore failed: $e');
      return {
        'success': false,
        'message': 'Restore failed: ${e.toString()}',
      };
    }
  }

  /// Dispose resources
  void dispose() {
    _purchaseSubscription?.cancel();
  }
}
