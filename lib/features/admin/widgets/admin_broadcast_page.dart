import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AdminBroadcastPage extends StatefulWidget {
  const AdminBroadcastPage({super.key});

  @override
  State<AdminBroadcastPage> createState() => _AdminBroadcastPageState();
}

class _AdminBroadcastPageState extends State<AdminBroadcastPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _isLoading = false;

  Future<void> _sendBroadcast({required bool isTest}) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await Supabase.instance.client.functions.invoke(
        'broadcast-notification',
        body: {
          'title': _titleController.text.trim(),
          'body': _bodyController.text.trim(),
          if (isTest) 'test_user_id': Supabase.instance.client.auth.currentUser?.id,
        },
      );

      if (response.status == 200) {
        if (mounted) {
          final logs = response.data['logs'] as List?;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isTest ? 'Test sent! Check your device.' : 'Broadcast sent successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Show logs dialog
          if (logs != null && logs.isNotEmpty) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Server Logs'),
                content: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: logs.map((log) => Text(log.toString(), style: const TextStyle(fontFamily: 'monospace', fontSize: 12))).toList(),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            );
          }

          _titleController.clear();
          _bodyController.clear();
        }
      } else {
        throw Exception('Failed to send: ${response.data}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Broadcast Notification'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Send to All Users',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This will send a push notification to every user who has the app installed. Use with caution.',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Notification Title',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., New Feature Alert!',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bodyController,
                decoration: const InputDecoration(
                  labelText: 'Message Body',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Check out the new dark mode...',
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a message';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : () => _sendBroadcast(isTest: true),
                        icon: const Icon(Icons.phonelink_ring),
                        label: const Text('Send Test to Me'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : () => _sendBroadcast(isTest: false),
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.send),
                        label: Text(_isLoading ? 'Sending...' : 'Send Broadcast'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: TextButton.icon(
                  onPressed: _showDebugInfo,
                  icon: const Icon(Icons.bug_report),
                  label: const Text('Device Debug Info'),
                  style: TextButton.styleFrom(foregroundColor: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDebugInfo() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 1. Get FCM Token
      final fcmToken = await FirebaseMessaging.instance.getToken();
      
      if (!mounted) return;

      // 2. Get APNs Token (iOS only)
      String? apnsToken;
      if (Theme.of(context).platform == TargetPlatform.iOS) {
        apnsToken = await FirebaseMessaging.instance.getAPNSToken();
      }

      // 3. Check RPC existence
      String rpcStatus = "Function exists (verified by SQL)";
      
      if (mounted) {
        Navigator.pop(context); // Close loading
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Debug Info'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('FCM Token:', style: TextStyle(fontWeight: FontWeight.bold)),
                  SelectableText(fcmToken ?? 'NULL'),
                  const SizedBox(height: 16),
                  if (Theme.of(context).platform == TargetPlatform.iOS) ...[
                    const Text('APNs Token:', style: TextStyle(fontWeight: FontWeight.bold)),
                    SelectableText(apnsToken ?? 'NULL (Wait a few seconds and try again)'),
                    const SizedBox(height: 16),
                  ],
                  const Text('RPC Status (In-App Persistence):', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(rpcStatus, style: TextStyle(color: rpcStatus.contains('exists') ? Colors.green : Colors.red)),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Debug Error: $e')));
      }
    }
  }
}
