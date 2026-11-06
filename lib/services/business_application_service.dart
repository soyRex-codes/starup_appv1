/// Business Application Service
/// Handles submissions to the business services ecosystem.
///
/// Automatic Email Notifications:
/// - Applicants receive instant confirmation emails with application details
/// - Admins receive notification emails for new applications
/// - All emails are sent automatically via database triggers + Edge Functions
library;

import 'package:supabase_flutter/supabase_flutter.dart';

class BusinessApplicationService {
  static final _supabase = Supabase.instance.client;

  /// Get application by ID
  static Future<Map<String, dynamic>?> getApplicationById(
      int applicationId) async {
    try {
      final result = await _supabase
          .from('business_applications')
          .select()
          .eq('id', applicationId)
          .maybeSingle();

      return result;
    } catch (e) {
      return null;
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
    'market_research': 'Market Research',
    'patent_filing': 'Patent Filing',
    'software_audit': 'Software Audit',
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
      'software_audit': 'Comprehensive software and security audit',
    };
  }
}
