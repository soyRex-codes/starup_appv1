import 'package:flutter/material.dart';
import 'business_services_portal.dart';
import 'ecosystem_service_model.dart';
import 'ecosystem_guide_page.dart';

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
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
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
                  // Vibrant description banner with platform colors
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFFF6B35), // Vibrant orange
                          Color(0xFFFF8C42), // Medium orange
                          Color(0xFFFFB347), // Golden orange
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF8C42).withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.4),
                              width: 2,
                            ),
                          ),
                          child: Image.asset(
                            'lib/icons/ecosystem_application.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Text(
                            'Professional services to accelerate your startup journey',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                              shadows: [
                                Shadow(
                                  color: Color(0x40000000),
                                  offset: Offset(0, 1),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Enhanced Stats Section (moved to top, more prominent)
                  _buildStatsSection(context, screenWidth),
                  const SizedBox(height: 24),

                  // Prominent Guide Button
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 24),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const EcosystemGuidePage()),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF9800).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFFF9800).withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.menu_book_rounded,
                                color: Color(0xFFE65100),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Flexible(
                                child: Text(
                                  'How it all works',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFE65100),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                color: Color(0xFFE65100),
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

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

  Widget _buildStatsSection(BuildContext context, double screenWidth) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(child: _buildCompactStatItem('Ideas to Life', Icons.lightbulb_outline)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: VerticalDivider(color: Colors.grey.withValues(alpha: 0.2), thickness: 1),
            ),
            Expanded(child: _buildCompactStatItem('24/7 Support', Icons.access_time)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: VerticalDivider(color: Colors.grey.withValues(alpha: 0.2), thickness: 1),
            ),
            Expanded(child: _buildCompactStatItem('100% Success', Icons.verified_user_outlined)),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactStatItem(String label, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFF9800).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: const Color(0xFFFF9800),
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
            height: 1.2,
          ),
          maxLines: 2,
        ),
      ],
    );
  }



  Widget _buildSectionHeader(
      BuildContext context, String title, double screenWidth) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
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
                    const Color(0xFFFF9800), // Match orange theme
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

    // Use shared data from ecosystem_service_model.dart
    final services = ecosystemServices;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio:
            screenWidth > 600 ? 0.9 : 0.75, // Taller cards for more content
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
    EcosystemServiceData service,
    int index,
    double screenWidth,
  ) {
    // ... (rest of the method remains the same, just updated type signature)
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
        cursor: service.badge == 'Coming Soon'
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        child: GestureDetector(
          onTap: service.badge == 'Coming Soon'
              ? null
              : () => _openBusinessService(context, service.type),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Colors.white.withValues(alpha: 0.95),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: service.color.withValues(alpha: 0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: service.color.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
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
                            service.color.withValues(alpha: 0.1),
                            service.color.withValues(alpha: 0.0),
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
                              service.color.withValues(alpha: 0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: service.color.withValues(alpha: 0.3),
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
                                service.color.withValues(alpha: 0.15),
                                service.color.withValues(alpha: 0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: service.color.withValues(alpha: 0.2),
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
                          maxLines: 2,
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
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: screenWidth > 600 ? 14 : 10),

                        // Features list
                        ...service.features.take(5).map((feature) => Padding(
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
                                      feature.title,
                                      style: TextStyle(
                                        fontSize:
                                            screenWidth > 600 ? 11.5 : 10.5,
                                        color: Colors.grey[700],
                                        height: 1.3,
                                      ),
                                      maxLines: 3,
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
                            color: service.color.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: service.color.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Text(
                            service.pricing,
                            style: TextStyle(
                              fontSize: screenWidth > 600 ? 11 : 10,
                              fontWeight: FontWeight.w600,
                              color: service.color.withValues(alpha: 0.9),
                            ),
                          ),
                        ),
                        SizedBox(height: screenWidth > 600 ? 12 : 8),

                        // Action button/arrow
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: service.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Get Started',
                                style: TextStyle(
                                  fontSize: screenWidth > 600 ? 12 : 11,
                                  fontWeight: FontWeight.w700,
                                  color: service.color,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: screenWidth > 600 ? 16 : 14,
                                color: service.color,
                              ),
                            ],
                          ),
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
