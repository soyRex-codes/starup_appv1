/// Business Application Service
/// Handles submissions to the business services ecosystem.
/// Email notifications are automatically sent via database triggers.
library;

import 'package:supabase_flutter/supabase_flutter.dart';

class BusinessApplicationService {
  static final _supabase = Supabase.instance.client;

  /// Submit a business service application
  ///
  /// The database trigger will automatically send an email notification
  /// to the admin when this application is inserted.
  static Future<Map<String, dynamic>> submitApplication({
    required String serviceType,
    required String applicantName,
    required String applicantEmail,
    required Map<String, dynamic> formData,
  }) async {
    try {
      // Get current user ID if authenticated
      final userId = _supabase.auth.currentUser?.id;

      // Insert the application into the database
      // This will automatically trigger an email notification to admin
      final result = await _supabase
          .from('business_applications')
          .insert({
            'service_type': serviceType,
            'applicant_id': userId, // Null if not authenticated
            'applicant_name': applicantName,
            'applicant_email': applicantEmail,
            'form_data': formData,
            'status': 'pending',
          })
          .select()
          .single();

      return {
        'success': true,
        'application_id': result['id'],
        'message':
            'Application submitted successfully! Our team will contact you within 24-48 hours.',
        'data': result,
      };
    } on PostgrestException catch (e) {
      return {
        'success': false,
        'message': 'Database error: ${e.message}',
        'error': e.toString(),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred. Please try again.',
        'error': e.toString(),
      };
    }
  }

  /// Get applications for the current user
  static Future<List<Map<String, dynamic>>> getUserApplications() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final result = await _supabase
          .from('business_applications')
          .select('*')
          .eq('applicant_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      rethrow;
    }
  }

  /// Get all applications (admin only)
  static Future<Map<String, dynamic>> getAllApplications() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return {
          'success': false,
          'message': 'User not authenticated',
          'error': 'Authentication required',
        };
      }

      // Check if user has admin role
      final userProfile = await _supabase
          .from('user_profiles') // Adjust table name as needed
          .select('role')
          .eq('id', userId)
          .single();

      if (userProfile['role'] != 'admin') {
        return {
          'success': false,
          'message': 'Insufficient permissions',
          'error': 'Admin access required',
        };
      }

      final result = await _supabase
          .from('business_applications')
          .select('*')
          .order('created_at', ascending: false);

      return {
        'success': true,
        'data': List<Map<String, dynamic>>.from(result),
      };
    } on PostgrestException catch (e) {
      return {
        'success': false,
        'message': 'Database error: ${e.message}',
        'error': e.toString(),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred. Please try again.',
        'error': e.toString(),
      };
    }
  }

  /// Update application status (admin only)
  static Future<Map<String, dynamic>> updateApplicationStatus({
    required int applicationId,
    required String status,
    String? assignedTo,
    String? adminNotes,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return {
          'success': false,
          'message': 'User not authenticated',
          'error': 'Authentication required',
        };
      }

      // Check if user has admin role
      final userProfile = await _supabase
          .from('user_profiles') // Adjust table name as needed
          .select('role')
          .eq('id', userId)
          .single();

      if (userProfile['role'] != 'admin') {
        return {
          'success': false,
          'message': 'Insufficient permissions',
          'error': 'Admin access required',
        };
      }

      final updateData = <String, dynamic>{
        'status': status,
      };

      if (assignedTo != null) updateData['assigned_to'] = assignedTo;
      if (adminNotes != null) updateData['admin_notes'] = adminNotes;

      final result = await _supabase
          .from('business_applications')
          .update(updateData)
          .eq('id', applicationId)
          .select()
          .single();

      return {
        'success': true,
        'message': 'Application status updated successfully',
        'data': result,
      };
    } on PostgrestException catch (e) {
      return {
        'success': false,
        'message': 'Database error: ${e.message}',
        'error': e.toString(),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred. Please try again.',
        'error': e.toString(),
      };
    }
  }

  /// Service type display names
  static const Map<String, String> serviceTypeNames = {
    'tax_help': 'Tax Help',
    'business_registration': 'Business Registration',
    'app_development': 'App Development',
    'marketing': 'Marketing',
    'employee_hiring': 'Employee Hiring',
    'investor_finding': 'Investor Finding',
    'business_consultation': 'Business Consultation',
  };

  /// Get display name for service type
  static String getServiceTypeName(String serviceType) {
    return serviceTypeNames[serviceType] ?? serviceType;
  }

  /// Status display names
  static const Map<String, String> statusNames = {
    'pending': 'Pending Review',
    'reviewed': 'Under Review',
    'assigned': 'Assigned to Provider',
    'completed': 'Completed',
  };

  /// Get display name for status
  static String getStatusName(String status) {
    return statusNames[status] ?? status;
  }

  /// Get all available service types
  static List<String> getServiceTypes() {
    return serviceTypeNames.keys.toList();
  }

  /// Get service type descriptions
  static Map<String, String> getServiceDescriptions() {
    return {
      'tax_help': 'Get professional help with tax preparation and planning',
      'business_registration':
          'Register your business and get legal documentation',
      'app_development': 'Build mobile or web applications for your business',
      'marketing': 'Create marketing strategies and campaigns',
      'employee_hiring': 'Find and hire qualified employees',
      'investor_finding': 'Connect with potential investors for funding',
      'business_consultation': 'Get expert advice on business operations',
    };
  }
}
