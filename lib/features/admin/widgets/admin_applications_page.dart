import 'package:flutter/material.dart';
import '../services/admin_service.dart';

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
      setState(() {
        _applications = applications;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading applications: $e')),
        );
      }
    }
  }

  Future<void> _updateApplicationStatus(int applicationId, String newStatus) async {
    try {
      await AdminService.updateApplicationStatus(applicationId, newStatus, null);
      await _loadApplications(); // Refresh the list
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Application status updated to $newStatus')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e')),
        );
      }
    }
  }

  Future<void> _assignApplication(int applicationId) async {
    final assignedToController = TextEditingController();

    final assignedTo = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign Application'),
        content: TextField(
          controller: assignedToController,
          decoration: const InputDecoration(
            labelText: 'Assign to',
            hintText: 'Enter service provider name...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, assignedToController.text),
            child: const Text('Assign'),
          ),
        ],
      ),
    );

    if (assignedTo != null && assignedTo.isNotEmpty) {
      try {
        await AdminService.assignApplication(applicationId, assignedTo);
        await _loadApplications();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Application assigned to $assignedTo')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error assigning application: $e')),
          );
        }
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    value: status,
                    items: ['pending', 'reviewed', 'assigned', 'completed']
                        .map((status) => DropdownMenuItem(
                              value: status,
                              child: Text(status.toUpperCase()),
                            ))
                        .toList(),
                    onChanged: (newStatus) {
                      if (newStatus != null) {
                        _updateApplicationStatus(application['id'], newStatus);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _assignApplication(application['id']),
                  child: const Text('Assign'),
                ),
              ],
            ),
          ],
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
                        value: _selectedStatus,
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All Statuses')),
                          const DropdownMenuItem(value: 'pending', child: Text('Pending')),
                          const DropdownMenuItem(value: 'reviewed', child: Text('Reviewed')),
                          const DropdownMenuItem(value: 'assigned', child: Text('Assigned')),
                          const DropdownMenuItem(value: 'completed', child: Text('Completed')),
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
                        value: _selectedServiceType,
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All Services')),
                          const DropdownMenuItem(value: 'tax_help', child: Text('Tax Help')),
                          const DropdownMenuItem(value: 'business_registration', child: Text('Business Registration')),
                          const DropdownMenuItem(value: 'legal_services', child: Text('Legal Services')),
                          const DropdownMenuItem(value: 'accounting', child: Text('Accounting')),
                          const DropdownMenuItem(value: 'marketing', child: Text('Marketing')),
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