import 'package:flutter/material.dart';
import 'business_services_portal.dart';

/// Page for ecosystem applications and integrations with premium glassmorphism design
class EcosystemApplicationPage extends StatefulWidget {
  const EcosystemApplicationPage({super.key});

  @override
  State<EcosystemApplicationPage> createState() =>
      _EcosystemApplicationPageState();
}

class _EcosystemApplicationPageState extends State<EcosystemApplicationPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Ecosystem Applications',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final horizontalPadding = screenWidth > 600 ? 32.0 : 20.0;

            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFF5F7FA),
                    const Color(0xFFE8EEF5),
                    const Color(0xFFF0F4F8),
                  ],
                ),
              ),
              child: ListView(
                padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding, vertical: 20),
                children: [
                  // Premium Hero Header
                  _buildHeroHeader(context, screenWidth),
                  const SizedBox(height: 32),

                  // Stats Section
                  _buildStatsSection(context, screenWidth),
                  const SizedBox(height: 40),

                  // Business Services Header
                  _buildSectionHeader(
                      context, 'Business Services', screenWidth),
                  const SizedBox(height: 20),

                  // Glassmorphism Business Services Grid
                  _buildServicesGrid(context, screenWidth),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context, double screenWidth) {
    return Container(
      padding: EdgeInsets.all(screenWidth > 600 ? 32 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
            const Color(0xFFFF9800),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: screenWidth > 600 ? 64 : 56,
                height: screenWidth > 600 ? 64 : 56,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Image.asset(
                  'lib/icons/ecosystem_application.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ecosystem Applications',
                      style: TextStyle(
                        fontSize: screenWidth > 600 ? 28 : 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Professional services to accelerate your startup journey',
                      style: TextStyle(
                        fontSize: screenWidth > 600 ? 15 : 14,
                        color: Colors.white.withOpacity(0.9),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context, double screenWidth) {
    return Row(
      children: [
        Expanded(child: _buildStatCard('--', 'Helping Founders', Icons.people)),
        const SizedBox(width: 12),
        Expanded(
            child: _buildStatCard('24hrs', 'Response Time', Icons.access_time)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('100%', 'Success Rate', Icons.verified)),
      ],
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
      BuildContext context, String title, double screenWidth) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.primary,
                const Color(0xFF4CAF50),
              ],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: screenWidth > 600 ? 24 : 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1A1A1A),
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildServicesGrid(BuildContext context, double screenWidth) {
    final gridWidth = screenWidth - (screenWidth > 600 ? 64 : 40);
    final crossAxisCount = gridWidth > 1200
        ? 3
        : gridWidth > 700
            ? 2
            : 1;

    final services = [
      _ServiceData(
        'Tax Help',
        'Professional tax assistance',
        'lib/icons/tax_help.png',
        const Color(0xFF2196F3),
        'Popular',
        [
          'Expert tax consultants',
          'Same-day filing available',
          'Audit protection included'
        ],
        'Starting at \$299',
      ),
      _ServiceData(
        'Legal',
        'Business registration & compliance',
        'lib/icons/Legal_compliant.png',
        const Color(0xFF9C27B0),
        null,
        [
          'LLC, S-Corp, C-Corp setup',
          'State compliance assistance',
          'Legal document review'
        ],
        '2-3 weeks delivery',
      ),
      _ServiceData(
        'Development',
        'App & web development',
        'lib/icons/development.png',
        const Color(0xFF00BCD4),
        'Trending',
        [
          'Mobile & web apps',
          'Custom tech solutions',
          'Ongoing support included'
        ],
        'Free consultation',
      ),
      _ServiceData(
        'Marketing',
        'Advertisement & campaigns',
        'lib/icons/marketting & adverstisement.png',
        const Color(0xFFFF5722),
        null,
        [
          'Social media campaigns',
          'SEO & content marketing',
          'ROI-focused strategies'
        ],
        'Plans from \$500/mo',
      ),
      _ServiceData(
        'Hiring',
        'Employee recruitment',
        'lib/icons/HR_Employeer_hiring.png',
        const Color(0xFF4CAF50),
        null,
        [
          'Pre-vetted candidates',
          'Technical & non-technical',
          'Fast placement guarantee'
        ],
        'No upfront costs',
      ),
      _ServiceData(
        'Investors',
        'Find funding opportunities',
        'lib/icons/investor.png',
        const Color(0xFFFFB300),
        'Popular',
        [
          'Pitch deck preparation',
          'Investor matchmaking',
          'Due diligence support'
        ],
        'Success-based fees',
      ),
      _ServiceData(
        'Consultation',
        'Strategic business advice',
        'lib/icons/consultation.png',
        const Color(0xFF673AB7),
        null,
        [
          'Growth strategy planning',
          'Operations optimization',
          'Expert mentorship'
        ],
        '1-hour free session',
      ),
      _ServiceData(
        'Market Research',
        'Product-market fit analysis',
        'lib/icons/market-research.png',
        const Color(0xFF009688),
        null,
        ['Competitor analysis', 'Customer validation', 'Market size insights'],
        '2-4 weeks turnaround',
      ),
      _ServiceData(
        'Patent Filing',
        'Protect your innovations',
        'lib/icons/patent_filing.png',
        const Color(0xFFE91E63),
        null,
        [
          'Patent search & filing',
          'IP protection strategy',
          'Trademark registration'
        ],
        'Starting at \$1,500',
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio:
            screenWidth > 600 ? 1.15 : 0.95, // Increased for small screens
      ),
      itemCount: services.length,
      itemBuilder: (context, index) {
        return _buildGlassmorphicServiceCard(
          context,
          services[index],
          index,
          screenWidth,
        );
      },
    );
  }

  Widget _buildGlassmorphicServiceCard(
    BuildContext context,
    _ServiceData service,
    int index,
    double screenWidth,
  ) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => _openBusinessService(context, service.type),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Colors.white.withOpacity(0.95),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: service.color.withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: service.color.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  // Gradient overlay
                  Positioned(
                    top: -50,
                    right: -50,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            service.color.withOpacity(0.1),
                            service.color.withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Badge
                  if (service.badge != null)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              service.color,
                              service.color.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: service.color.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          service.badge!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),

                  // Content
                  Padding(
                    padding: EdgeInsets.all(screenWidth > 600 ? 20 : 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon container
                        Container(
                          width: screenWidth > 600 ? 56 : 48,
                          height: screenWidth > 600 ? 56 : 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                service.color.withOpacity(0.15),
                                service.color.withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: service.color.withOpacity(0.2),
                              width: 1.5,
                            ),
                          ),
                          padding: EdgeInsets.all(screenWidth > 600 ? 12 : 10),
                          child: Image.asset(
                            service.iconPath,
                            fit: BoxFit.contain,
                          ),
                        ),
                        SizedBox(height: screenWidth > 600 ? 16 : 12),

                        // Title
                        Text(
                          service.title,
                          style: TextStyle(
                            fontSize: screenWidth > 600 ? 18 : 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1A1A1A),
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: screenWidth > 600 ? 6 : 4),

                        // Description
                        Text(
                          service.description,
                          style: TextStyle(
                            fontSize: screenWidth > 600 ? 13 : 11.5,
                            color: Colors.grey[600],
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: screenWidth > 600 ? 14 : 10),

                        // Features list
                        ...service.features.take(3).map((feature) => Padding(
                              padding: EdgeInsets.only(
                                  bottom: screenWidth > 600 ? 6 : 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(top: 2),
                                    child: Icon(
                                      Icons.check_circle,
                                      size: screenWidth > 600 ? 14 : 12,
                                      color: service.color,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      feature,
                                      style: TextStyle(
                                        fontSize:
                                            screenWidth > 600 ? 11.5 : 10.5,
                                        color: Colors.grey[700],
                                        height: 1.3,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            )),

                        SizedBox(height: screenWidth > 600 ? 12 : 8),

                        // Pricing/Timeline
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth > 600 ? 10 : 8,
                            vertical: screenWidth > 600 ? 6 : 5,
                          ),
                          decoration: BoxDecoration(
                            color: service.color.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: service.color.withOpacity(0.15),
                            ),
                          ),
                          child: Text(
                            service.pricing,
                            style: TextStyle(
                              fontSize: screenWidth > 600 ? 11 : 10,
                              fontWeight: FontWeight.w600,
                              color: service.color.withOpacity(0.9),
                            ),
                          ),
                        ),
                        SizedBox(height: screenWidth > 600 ? 12 : 8),

                        // Action button/arrow
                        Row(
                          children: [
                            Text(
                              'Get Started',
                              style: TextStyle(
                                fontSize: screenWidth > 600 ? 13 : 12,
                                fontWeight: FontWeight.w600,
                                color: service.color,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward,
                              size: screenWidth > 600 ? 16 : 14,
                              color: service.color,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openBusinessService(BuildContext context, BusinessServiceType type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BusinessServicesPortal(initialService: type),
      ),
    );
  }
}

// Service data model
class _ServiceData {
  final String title;
  final String description;
  final String iconPath;
  final Color color;
  final String? badge;
  final List<String> features;
  final String pricing;

  _ServiceData(
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
      case 'Tax Help':
        return BusinessServiceType.taxHelp;
      case 'Legal':
        return BusinessServiceType.businessRegistration;
      case 'Development':
        return BusinessServiceType.appDevelopment;
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
      default:
        return BusinessServiceType.taxHelp;
    }
  }
}
