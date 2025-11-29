import 'package:flutter/material.dart';
import 'business_services_portal.dart';

class ServiceFeature {
  final String title;
  final String description;

  const ServiceFeature(this.title, this.description);
}

class EcosystemServiceData {
  final String title;
  final String description;
  final String iconPath;
  final Color color;
  final String? badge;
  final List<ServiceFeature> features;
  final String pricing;

  EcosystemServiceData(
    this.title,
    this.description,
    this.iconPath,
    this.color,
    this.badge,
    this.features,
    this.pricing,
  );

  BusinessServiceType get type {
    switch (title) {
      case 'Software Development':
        return BusinessServiceType.appDevelopment;
      case 'Software Audit':
        return BusinessServiceType.softwareAudit;
      case 'Marketing':
        return BusinessServiceType.marketing;
      case 'Hiring':
        return BusinessServiceType.employeeHiring;
      case 'Investors':
        return BusinessServiceType.investorFinding;
      case 'Consultation':
        return BusinessServiceType.businessConsultation;
      case 'Market Research':
        return BusinessServiceType.marketResearch;
      case 'Patent Filing':
        return BusinessServiceType.patentFiling;
      case 'Tax Help':
        return BusinessServiceType.taxHelp;
      case 'Legal':
        return BusinessServiceType.businessRegistration;
      default:
        return BusinessServiceType.taxHelp;
    }
  }
}

final List<EcosystemServiceData> ecosystemServices = [
  EcosystemServiceData(
    'Consultation',
    'Strategic business & technical advice',
    'lib/icons/consultation.png',
    const Color(0xFF673AB7),
    null,
    [
      ServiceFeature(
        'CTO for a Day',
        'Get a dedicated Chief Technology Officer for one day to audit your tech stack, review your code architecture, and build a scalable technical roadmap. Perfect for non-technical founders needing expert validation.',
      ),
      ServiceFeature(
        'Roast My App Landing Page',
        'A brutal, honest, and conversion-focused review of your landing page. We identify friction points, confusing copy, and design flaws that are killing your signup rate.',
      ),
      ServiceFeature(
        'Strategic Business Advice',
        'One-on-one sessions with experienced founders to refine your go-to-market strategy, pricing models, and operational efficiency.',
      ),
      ServiceFeature(
        'Product Reality Check',
        'Unbiased feasibility analysis of your product idea. We assess technical complexity, estimated development costs, and potential market blockers before you invest.',
      ),
      ServiceFeature(
        'Business Model Validation',
        'Stress-testing your revenue streams and unit economics to ensure your startup is built on a sustainable financial foundation.',
      ),
    ],
    '1 Free consultation on Application submission',
  ),
  EcosystemServiceData(
    'Market Research',
    'Product-market fit analysis',
    'lib/icons/market-research.png',
    const Color(0xFF009688),
    null,
    [
      ServiceFeature(
        'Competitor Analysis',
        'Deep dive into your top 5 competitors. We analyze their features, pricing, weaknesses, and customer reviews to find your competitive edge.',
      ),
      ServiceFeature(
        'Product-Market Fit Analysis',
        'Data-driven assessment of whether your product satisfies a strong market demand. Includes surveys and trend analysis.',
      ),
      ServiceFeature(
        'Market Size Insights',
        'TAM, SAM, and SOM calculations backed by industry reports to help you understand the true potential of your market.',
      ),
      ServiceFeature(
        'Customer Validation',
        'Direct interviews and feedback loops with potential users to validate your problem-solution fit before writing a single line of code.',
      ),
    ],
    '2-4 weeks turnaround - depending on the product',
  ),
  EcosystemServiceData(
    'Software Development',
    'Mobile, Web & Desktop Apps Development',
    'lib/icons/development.png',
    const Color(0xFF00BCD4),
    'Trending',
    [
      ServiceFeature(
        'UI/UX Design',
        'World-class interface design focused on user retention. We create high-fidelity mockups and interactive prototypes.',
      ),
      ServiceFeature(
        'MVP Development',
        'Rapid build of your Minimum Viable Product. We focus on core features to get you to market and testing with real users in weeks, not months.',
      ),
      ServiceFeature(
        'Mobile Apps (iOS & Android)',
        'Native or Cross-platform (Flutter/React Native) mobile applications published directly to the App Store and Google Play.',
      ),
      ServiceFeature(
        'Web Applications',
        'Scalable, responsive web apps built with modern frameworks (React, Vue, Flutter Web) that work perfectly on any device.',
      ),
      ServiceFeature(
        'Cloud Infrastructure',
        'Secure setup of your backend on AWS, Google Cloud, or Azure. Includes database design, API development, and auto-scaling configuration.',
      ),
      ServiceFeature(
        'App Store Submission',
        'We handle the entire complex submission process, including screenshots, privacy policies, and resolving rejection issues from Apple/Google.',
      ),
    ],
    '1 Free consultation on Application submission',
  ),
  EcosystemServiceData(
    'Hiring',
    'Employee recruitment',
    'lib/icons/HR_Employeer_hiring.png',
    const Color(0xFF4CAF50),
    null,
    [
      ServiceFeature(
        'Pre-vetted Candidates',
        'Access our pool of top 1% talent who have already passed rigorous technical and behavioral assessments.',
      ),
      ServiceFeature(
        'Technical & Non-technical',
        'Whether you need a Senior React Developer or a Head of Sales, we find the right fit for your startup culture.',
      ),
      ServiceFeature(
        'Replacement Guarantee',
        'If a hire doesn\'t work out within the first 90 days, we find a replacement completely free of charge.',
      ),
    ],
    'One-time set Fees depending on filed',
  ),
  EcosystemServiceData(
    'Marketing',
    'Advertisement, campaigns, & Reviews',
    'lib/icons/marketting & adverstisement.png',
    const Color(0xFFFF5722),
    null,
    [
      ServiceFeature(
        'Product Explainer Videos',
        'High-quality animated or live-action videos that explain your product\'s value proposition in under 60 seconds.',
      ),
      ServiceFeature(
        'Logo & Brand Identity',
        'Complete rebranding packages including logo design, color palettes, typography, and brand voice guidelines.',
      ),
      ServiceFeature(
        'Social Media Campaigns',
        'Targeted ad campaigns on LinkedIn, Twitter, and Instagram designed to drive low-cost user acquisition.',
      ),
    ],
    'One-time set Fees depending on complexity',
  ),
  EcosystemServiceData(
    'Investors',
    'Find funding opportunities',
    'lib/icons/investor.png',
    const Color(0xFFFFB300),
    'Popular',
    [
      ServiceFeature(
        'Pitch Deck Polish',
        'We refine your story, design, and financial projections to make your pitch deck irresistible to VCs and Angels.',
      ),
      ServiceFeature(
        'Investor Matchmaking',
        'Direct introductions to our network of 500+ investors who are actively looking for startups in your specific industry and stage.',
      ),
      ServiceFeature(
        'Due Diligence Support',
        'We prepare your data room and coach you through the grueling due diligence process to ensure you close the deal.',
      ),
    ],
    'Success-based commission',
  ),
  EcosystemServiceData(
    'Software Audit',
    'Software audit & security',
    'lib/icons/development.png',
    const Color(0xFF00BCD4),
    'Trending',
    [
      ServiceFeature(
        'Code Quality Audit',
        'Comprehensive review of your codebase to identify technical debt, anti-patterns, and scalability bottlenecks before they crash your production.',
      ),
      ServiceFeature(
        'Security Vulnerability Scan',
        'Penetration testing and automated scanning to find security holes (OWASP Top 10) that could expose your user data.',
      ),
      ServiceFeature(
        'Performance Optimization',
        'Deep profiling of your application to find slow queries, memory leaks, and rendering issues, resulting in a faster, smoother user experience.',
      ),
    ],
    '1 Free consultation on Application submission',
  ),
  EcosystemServiceData(
    'Patent Filing',
    'Protect your innovations',
    'lib/icons/patent_filing.png',
    const Color(0xFFE91E63),
    'Coming Soon',
    [
      'Patent Search',
      'Provisional Patent Filing',
      'Trademark Registration'
    ].map((e) => ServiceFeature(e, 'Detailed description coming soon...')).toList(),
    'One-time set Fees depending on complexity',
  ),
  EcosystemServiceData(
    'Legal',
    'Business registration & compliance',
    'lib/icons/Legal_compliant.png',
    const Color(0xFF9C27B0),
    'Coming Soon',
    [
      'Entity Formation (LLC/C-Corp)',
      'Operating Agreements',
      'Contract Review'
    ].map((e) => ServiceFeature(e, 'Detailed description coming soon...')).toList(),
    '1 Free consultation on Application submission',
  ),
  EcosystemServiceData(
    'Tax Help',
    'Professional tax assistance',
    'lib/icons/tax_help.png',
    const Color(0xFF2196F3),
    'Coming Soon',
    [
      'R&D Tax Credits',
      'Annual Filing',
      'Bookkeeping Setup'
    ].map((e) => ServiceFeature(e, 'Detailed description coming soon...')).toList(),
    '1 Free consultation on Application submission',
  )
];
