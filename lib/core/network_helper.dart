import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Network connectivity status
enum NetworkStatus {
  online,          // Connected and server reachable
  noInternet,      // No connectivity (WiFi/cellular off)
  serverUnreachable, // Connected but server unreachable
  timeout,         // Connection timeout
  unknown,         // Unable to determine
}

/// Helper class for network connectivity checks
class NetworkHelper {
  NetworkHelper._();
  
  static final Connectivity _connectivity = Connectivity();
  
  /// Quick check if device has internet connectivity
  /// Returns true if connected to WiFi or cellular
  static Future<bool> hasConnection() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      return connectivityResult.any((result) => 
        result == ConnectivityResult.wifi || 
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.ethernet
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Network check error: $e');
      return false;
    }
  }
  
  /// Detailed network status check with server reachability test
  /// Tests actual connectivity to a known endpoint
  static Future<NetworkStatus> checkDetailedStatus({
    String testHost = 'google.com',
    int port = 443,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    try {
      // First check basic connectivity
      final connectivityResult = await _connectivity.checkConnectivity();
      
      if (!connectivityResult.any((result) => 
          result == ConnectivityResult.wifi || 
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.ethernet)) {
        return NetworkStatus.noInternet;
      }
      
      // Device reports connectivity, now test actual reachability
      try {
        final result = await InternetAddress.lookup(testHost).timeout(timeout);
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          return NetworkStatus.online;
        } else {
          return NetworkStatus.serverUnreachable;
        }
      } on SocketException catch (_) {
        return NetworkStatus.serverUnreachable;
      } on TimeoutException catch (_) {
        return NetworkStatus.timeout;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Detailed network check error: $e');
      return NetworkStatus.unknown;
    }
  }
  
  /// Get user-friendly error message for network status
  static String getErrorMessage(NetworkStatus status) {
    switch (status) {
      case NetworkStatus.online:
        return 'Connected';
      case NetworkStatus.noInternet:
        return 'No internet connection detected. Please check your Wi-Fi or cellular data.';
      case NetworkStatus.serverUnreachable:
        return 'Unable to reach server. Please check your connection and try again.';
      case NetworkStatus.timeout:
        return 'Connection timeout. Please try again in a moment.';
      case NetworkStatus.unknown:
        return 'Network status unknown. Please check your connection.';
    }
  }
  
  /// Stream of connectivity changes
  /// Useful for showing connectivity status in real-time
  static Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged;
}
