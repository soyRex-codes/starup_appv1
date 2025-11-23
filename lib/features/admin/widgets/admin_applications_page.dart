import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import 'application_detail_page.dart';
import '../../../services/business_application_service.dart';

class AdminApplicationsPage extends StatefulWidget {
  const AdminApplicationsPage({super.key});

  @override
  State<AdminApplicationsPage> createState() => _AdminApplicationsPageState();
}

class _AdminApplicationsPageState extends State<AdminApplicationsPage> {
  List<Map<String, dynamic>> _applications = [];
  bool _loading = true;
  String? _selectedStatus;
  String? _selectedServiceType;
  final _searchController = TextEditingController();

  // Valid status values
  static const List<String> validStatuses = [
    'pending',
    'paid',
    'reviewed',
    'assigned',
    'completed',
  ];

  // Get validated status value for dropdown
  String? get _validatedStatus {
    if (_selectedStatus == null) return null;
    return validStatuses.contains(_selectedStatus) ? _selectedStatus : null;
  }

  // Get validated service type value for dropdown
  String? get _validatedServiceType {
    if (_selectedServiceType == null) return null;
    return BusinessApplicationService.serviceTypeNames
            .containsKey(_selectedServiceType)
        ? _selectedServiceType
        : null;
  }

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadApplications() async {
    try {
      final applications = await AdminService.getAllApplications(
        status: _selectedStatus,
        serviceType: _selectedServiceType,
      );
      if (mounted) {
        setState(() {
          _applications = applications;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading applications: $e')),
        );
      }
    }
  }

  Future<void> _deleteApplication(int applicationId, String serviceType) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Application'),
        content: Text(
          'Are you sure you want to delete this ${serviceType.replaceAll('_', ' ')} application?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await AdminService.deleteApplication(applicationId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Application deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadApplications(); // Reload list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting application: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildApplicationCard(Map<String, dynamic> application) {
    final status = application['status'] as String;
    final serviceType = application['service_type'] as String;
    final applicantName = application['applicant_name'] as String;
    final applicantEmail = application['applicant_email'] as String;
    final createdAt = DateTime.parse(application['created_at']);
    final assignedTo = application['assigned_to'];

    Color statusColor;
    switch (status) {
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'paid':
        statusColor = Colors.green;
        break;
      case 'reviewed':
        statusColor = Colors.blue;
        break;
      case 'assigned':
        statusColor = Colors.purple;
        break;
      case 'completed':
        statusColor = Colors.green;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ApplicationDetailPage(
                application: application,
                onUpdate: _loadApplications,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          serviceType.replaceAll('_', ' ').toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          applicantName,
                          style: const TextStyle(fontSize: 14),
                        ),
                        Text(
                          applicantEmail,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Submitted: ${createdAt.toString().split('T')[0]}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              if (assignedTo != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Assigned to: $assignedTo',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Delete button
                  OutlinedButton.icon(
                    onPressed: () => _deleteApplication(
                      application['id'] as int,
                      serviceType,
                    ),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  // View icon
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Applications'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: Column(
        children: [
          // Filters
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                        ),
                        initialValue: _validatedStatus,
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('All Statuses')),
                          const DropdownMenuItem(
                              value: 'pending', child: Text('Pending')),
                          const DropdownMenuItem(
                              value: 'paid', child: Text('Paid')),
                          const DropdownMenuItem(
                              value: 'reviewed', child: Text('Reviewed')),
                          const DropdownMenuItem(
                              value: 'assigned', child: Text('Assigned')),
                          const DropdownMenuItem(
                              value: 'completed', child: Text('Completed')),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedStatus = value);
                          _loadApplications();
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Service Type',
                          border: OutlineInputBorder(),
                        ),
                        initialValue: _validatedServiceType,
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('All Services')),
                          // Dynamically generate dropdown items from service types
                          ...BusinessApplicationService.serviceTypeNames.entries
                              .map((entry) => DropdownMenuItem(
                                    value: entry.key,
                                    child: Text(entry.value),
                                  ))
                              ,
                        ],
                        onChanged: (value) {
                          setState(() => _selectedServiceType = value);
                          _loadApplications();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          labelText: 'Search applications...',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (value) {
                          // TODO: Implement search functionality
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _loadApplications,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Applications List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _applications.isEmpty
                    ? const Center(
                        child: Text('No applications found'),
                      )
                    : ListView.builder(
                        itemCount: _applications.length,
                        itemBuilder: (context, index) {
                          return _buildApplicationCard(_applications[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
