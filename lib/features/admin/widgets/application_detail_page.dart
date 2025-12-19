import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/admin_service.dart';

class ApplicationDetailPage extends StatefulWidget {
  final Map<String, dynamic> application;
  final VoidCallback onUpdate;

  const ApplicationDetailPage({
    super.key,
    required this.application,
    required this.onUpdate,
  });

  @override
  State<ApplicationDetailPage> createState() => _ApplicationDetailPageState();
}

class _ApplicationDetailPageState extends State<ApplicationDetailPage> {
  static const List<String> _statusOptions = [
    'pending',
    'paid',
    'reviewed',
    'assigned',
    'completed',
  ];

  late String _currentStatus;
  final _adminNotesController = TextEditingController();
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    final initialStatus = widget.application['status']?.toString() ?? 'pending';
    _currentStatus =
        _statusOptions.contains(initialStatus) ? initialStatus : 'pending';
    _adminNotesController.text =
        widget.application['admin_notes']?.toString() ?? '';
  }

  @override
  void dispose() {
    _adminNotesController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'paid':
        return Colors.green;
      case 'reviewed':
        return Colors.blue;
      case 'assigned':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatFieldLabel(String key) {
    // Convert snake_case to Title Case
    return key
        .split('_')
        .map((word) =>
            word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _updating = true);
    try {
      await AdminService.updateApplicationStatus(
        widget.application['id'],
        newStatus,
        _adminNotesController.text.isEmpty ? null : _adminNotesController.text,
      );
      setState(() => _currentStatus = newStatus);
      widget.onUpdate();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated to $newStatus')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _updating = false);
    }
  }

  Future<void> _saveAdminNotes() async {
    setState(() => _updating = true);
    try {
      await AdminService.updateApplicationStatus(
        widget.application['id'],
        _currentStatus,
        _adminNotesController.text,
      );
      widget.onUpdate();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notes saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _updating = false);
    }
  }

  Future<void> _assignApplication() async {
    final assignedToController = TextEditingController();
    assignedToController.text =
        widget.application['assigned_to']?.toString() ?? '';

    final assignedTo = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign Application'),
        content: TextField(
          controller: assignedToController,
          decoration: const InputDecoration(
            labelText: 'Assign to',
            hintText: 'Enter service provider name...',
            border: OutlineInputBorder(),
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
      setState(() => _updating = true);
      try {
        await AdminService.assignApplication(
            widget.application['id'], assignedTo);
        widget.onUpdate();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Assigned to $assignedTo')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        setState(() => _updating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final serviceType = widget.application['service_type'] as String;
    final applicantName = widget.application['applicant_name'] as String;
    final applicantEmail = widget.application['applicant_email'] as String;
    final createdAt = DateTime.parse(widget.application['created_at']);
    final assignedTo = widget.application['assigned_to'];
    final formData =
        widget.application['form_data'] as Map<String, dynamic>? ?? {};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Application Details'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor(_currentStatus).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _getStatusColor(_currentStatus)),
            ),
            child: Text(
              _currentStatus.toUpperCase(),
              style: TextStyle(
                color: _getStatusColor(_currentStatus),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
      body: _updating
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Service Type Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          serviceType.replaceAll('_', ' ').toUpperCase(),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Application ID: ${widget.application['id']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimary
                                .withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Applicant Information
                  _buildSection(
                    'Applicant Information',
                    Icons.person,
                    [
                      _buildInfoRow('Name', applicantName),
                      _buildInfoRow('Email', applicantEmail),
                      _buildInfoRow(
                          'Submitted', createdAt.toString().split('T')[0]),
                      if (assignedTo != null)
                        _buildInfoRow('Assigned To', assignedTo),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Form Data (excluding files)
                  if (formData.isNotEmpty) ...[
                    _buildSection(
                      'Application Details',
                      Icons.description,
                      formData.entries.where((entry) {
                        // Exclude file fields (they'll be shown separately)
                        return !_isFileField(entry.key, entry.value);
                      }).map((entry) {
                        final value = entry.value;
                        String displayValue;

                        if (value is List) {
                          displayValue = value.join(', ');
                        } else if (value is Map) {
                          displayValue = value.toString();
                        } else {
                          displayValue = value?.toString() ?? 'N/A';
                        }

                        return _buildInfoRow(
                          _formatFieldLabel(entry.key),
                          displayValue,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Uploaded Files Section
                  if (_hasUploadedFiles(formData)) ...[
                    _buildFilesSection(formData),
                    const SizedBox(height: 20),
                  ],

                  // Admin Actions Section
                  _buildSection(
                    'Admin Actions',
                    Icons.admin_panel_settings,
                    [
                      // Status Dropdown
                      const Text(
                        'Update Status',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _currentStatus,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: _statusOptions
                            .map((status) => DropdownMenuItem(
                                  value: status,
                                  child: Text(status.toUpperCase()),
                                ))
                            .toList(),
                        onChanged: (newStatus) {
                          if (newStatus != null &&
                              newStatus != _currentStatus) {
                            _updateStatus(newStatus);
                          }
                        },
                      ),

                      const SizedBox(height: 16),

                      // Assign Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _assignApplication,
                          icon: const Icon(Icons.person_add),
                          label: Text(assignedTo != null
                              ? 'Reassign Application'
                              : 'Assign to Provider'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Admin Notes
                      const Text(
                        'Admin Notes',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _adminNotesController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Add notes about this application...',
                          contentPadding: EdgeInsets.all(12),
                        ),
                        maxLines: 4,
                      ),

                      const SizedBox(height: 12),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _saveAdminNotes,
                          icon: const Icon(Icons.save),
                          label: const Text('Save Notes'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.secondary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon,
                  size: 20, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to check if a field contains file data
  bool _isFileField(String key, dynamic value) {
    // Check if key contains common file field patterns
    if (key.toLowerCase().contains('_files') ||
        key.toLowerCase().contains('documents') ||
        key.toLowerCase().contains('attachments')) {
      return true;
    }

    // Check if value is a List of Maps with file properties
    if (value is List && value.isNotEmpty) {
      final firstItem = value[0];
      if (firstItem is Map &&
          (firstItem.containsKey('url') ||
              firstItem.containsKey('name') ||
              firstItem.containsKey('size'))) {
        return true;
      }
    }

    return false;
  }

  // Check if there are any uploaded files in the form data
  bool _hasUploadedFiles(Map<String, dynamic> formData) {
    return formData.entries
        .any((entry) => _isFileField(entry.key, entry.value));
  }

  // Build the files section
  Widget _buildFilesSection(Map<String, dynamic> formData) {
    final fileEntries = formData.entries
        .where((entry) => _isFileField(entry.key, entry.value))
        .toList();

    if (fileEntries.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildSection(
      'Uploaded Files',
      Icons.attach_file,
      fileEntries.expand((entry) {
        final files = entry.value;
        final fieldLabel = _formatFieldLabel(entry.key);

        if (files is List && files.isNotEmpty) {
          return files.map((file) {
            if (file is Map) {
              return _buildFileCard(file, fieldLabel);
            }
            return const SizedBox.shrink();
          }).toList();
        }
        return [const SizedBox.shrink()];
      }).toList(),
    );
  }

  // Build individual file card
  Widget _buildFileCard(Map<dynamic, dynamic> file, String category) {
    final fileName = file['name']?.toString() ?? 'Unknown File';
    final fileUrl = file['url']?.toString() ?? '';
    final fileSize =
        file['size_formatted']?.toString() ?? file['size']?.toString() ?? '';
    final fileType = file['type']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          // File icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getFileIcon(fileType),
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          // File info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  category,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
                ),
                if (fileSize.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    fileSize,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Download/View button
          if (fileUrl.isNotEmpty)
            IconButton(
              onPressed: () => _openFile(fileUrl),
              icon: const Icon(Icons.open_in_new),
              tooltip: 'Open file',
              color: Theme.of(context).colorScheme.primary,
            ),
        ],
      ),
    );
  }

  // Get appropriate icon based on file type
  IconData _getFileIcon(String fileType) {
    final type = fileType.toLowerCase();
    if (type.contains('pdf')) return Icons.picture_as_pdf;
    if (type.contains('image') ||
        type.contains('jpg') ||
        type.contains('png')) {
      return Icons.image;
    }
    if (type.contains('doc') || type.contains('word')) return Icons.description;
    if (type.contains('sheet') || type.contains('excel')) {
      return Icons.table_chart;
    }
    if (type.contains('zip') || type.contains('rar')) return Icons.folder_zip;
    return Icons.insert_drive_file;
  }

  // Open file in browser
  Future<void> _openFile(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open file'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
