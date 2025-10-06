/// Global app constants for the mobile client.
class AppConstants {
  AppConstants._();

  // Supabase Storage
  static const String storageBucket = 'startupbuilder';
  static const String applicationsBucket = 'applications';

  // Industry categories (mapped to posts.category)
  static const List<String> industryCategories = <String>[
    'technology',
    'healthcare',
    'finance',
    'education',
    'entertainment',
    'other',
  ];

  // Post goal enum values (posts.post_goal) kept consistent with DB free text used by web
  static const List<String> postGoals = <String>[
    'funding',
    'team',
    'skills',
    'partnership',
    'mentorship',
    'feedback',
    'other',
  ];

  static String goalLabel(String goal, {String? customDescription}) {
    switch (goal) {
      case 'funding':
        return 'Looking for Funding';
      case 'team':
        return 'Looking for Team Members';
      case 'skills':
        return 'Looking for Skills';
      case 'partnership':
        return 'Seeking Partnership';
      case 'mentorship':
        return 'Seeking Mentorship';
      case 'feedback':
        return 'Looking for Feedback';
      case 'other':
        return customDescription?.isNotEmpty == true
            ? customDescription!.trim()
            : 'Open to Opportunities';
      default:
        return goal;
    }
  }

  // Admin emails (keep in sync with DB policies)
  static const List<String> adminEmails = <String>[
    'foundervers@gmail.com',
    'startupbuilder0213@gmail.com',
  ];
}
