import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Offline error page shown when device has no internet connection
class OfflineErrorPage extends StatelessWidget {
  const OfflineErrorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wifi_off,
                size: 100,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 32),
              Text(
                'No Internet Connection',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Please connect to the internet and try again.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              ElevatedButton.icon(
                onPressed: () async {
                  // Check connectivity and retry
                  final connectivity = Connectivity();
                  final result = await connectivity.checkConnectivity();
                  
                  if (!result.contains(ConnectivityResult.none)) {
                    // Connection restored, restart app
                    if (context.mounted) {
                      // Force app restart by navigating to root
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/',
                        (route) => false,
                      );
                    }
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Still no internet connection. Please check your network settings.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
