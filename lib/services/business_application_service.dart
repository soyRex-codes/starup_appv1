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

  /// Save application as DRAFT before payment
  /// Returns application_id for payment processing
  static Future<Map<String, dynamic>> saveDraftApplication({
    required String serviceType,
    required String applicantName,
    required String applicantEmail,
    required Map<String, dynamic> formData,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;

      final result = await _supabase
          .from('business_applications')
          .insert({
            'service_type': serviceType,
            'applicant_id': userId,
            'applicant_name': applicantName,
            'applicant_email': applicantEmail,
            'form_data': formData,
            'status': 'draft',
            'payment_status': 'pending',
          })
          .select()
          .single();

      return {
        'success': true,
        'application_id': result['id'],
        'message': 'Application saved as draft',
        'data': result,
      };
    } on PostgrestException catch (e) {
      return {
        'success': false,
        'message': 'Failed to save draft: ${e.message}',
        'error': e.toString(),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred',
        'error': e.toString(),
      };
    }
  }

  /// Submit a business service application
  ///
  /// The database triggers will automatically:
  /// 1. Send a confirmation email to the applicant
  /// 2. Send a notification email to the admin team
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
      // This will automatically trigger both email notifications
      final result = await _supabase
          .from('business_applications')
          .insert({
            'service_type': serviceType,
            'applicant_id': userId, // Null if not authenticated
            'applicant_name': applicantName,
            'applicant_email': applicantEmail,
            'form_data': formData,
            'status': 'paid', // Start as paid after payment
            'payment_status': 'completed',
          })
          .select()
          .single();

      // 2. Trigger confirmation email explicitly (Client-Side Orchestration)
      // We do this here instead of DB trigger for better reliability and debugging
      /* 
      // Email notification temporarily disabled by user request (2025-11-23)
      // Relying on in-app "My Applications" page for status tracking.
      try {
        await _supabase.functions.invoke(
          'send-application-confirmation',
          body: {
            'applicant_name': applicantName,
            'applicant_email': applicantEmail,
            'service_type': serviceType,
            'service_type_display': getServiceTypeName(serviceType),
            'application_id': result['id'],
            'business_name': formData['business_name'],
          },
        );
      } catch (emailError) {
        // Log but don't fail the submission if email fails
        if (kDebugMode) debugPrint('Failed to send confirmation email: $emailError');
      }
      */

      return {
        'success': true,
        'application_id': result['id'],
        'message':
            'Application submitted successfully! You can track it in "My Business Applications".',
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

  /// Mark application as paid after successful payment
  /// Updates application status and payment info
  static Future<Map<String, dynamic>> markApplicationAsPaid({
    required int applicationId,
    required String paymentId,
  }) async {
    try {
      final result = await _supabase
          .from('business_applications')
          .update({
            'status': 'paid',
            'payment_status': 'completed',
            'payment_id': paymentId,
            'paid_at': DateTime.now().toIso8601String(),
          })
          .eq('id', applicationId)
          .select()
          .single();

      return {
        'success': true,
        'message': 'Application marked as paid',
        'data': result,
      };
    } on PostgrestException catch (e) {
      return {
        'success': false,
        'message': 'Failed to update application: ${e.message}',
        'error': e.toString(),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred',
        'error': e.toString(),
      };
    }
  }

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
