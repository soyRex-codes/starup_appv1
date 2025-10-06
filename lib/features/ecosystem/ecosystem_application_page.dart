import 'package:flutter/material.dart';
import 'business_services_portal.dart';

/// Page for ecosystem applications and integrations
class EcosystemApplicationPage extends StatefulWidget {
  const EcosystemApplicationPage({super.key});

  @override
  State<EcosystemApplicationPage> createState() =>
      _EcosystemApplicationPageState();
}

class _EcosystemApplicationPageState extends State<EcosystemApplicationPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ecosystem Applications'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        automaticallyImplyLeading: false, // Remove back button
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final horizontalPadding = screenWidth > 600 ? 24.0 : 16.0;

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).colorScheme.surface,
                  Theme.of(context).colorScheme.surface.withOpacity(0.8),
                ],
              ),
            ),
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16),
              children: [
                // Header Section
                Container(
                  padding: EdgeInsets.all(screenWidth > 600 ? 24 : 20),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: screenWidth > 600 ? 56 : 48,
                            height: screenWidth > 600 ? 56 : 48,
                            margin: const EdgeInsets.only(right: 16),
                            child: Image.asset(
                              'lib/icons/ecosystem_application.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ecosystem Applications',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color:
                                            Theme.of(context).colorScheme.primary,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Discover and integrate powerful tools for your startup',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.7),
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Business Services Section
                Container(
                  padding: EdgeInsets.all(screenWidth > 600 ? 24 : 20),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF4CAF50).withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: screenWidth > 600 ? 56 : 48,
                            height: screenWidth > 600 ? 56 : 48,
                            margin: const EdgeInsets.only(right: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.business_center,
                              color: const Color(0xFF4CAF50),
                              size: screenWidth > 600 ? 32 : 28,
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Business Services',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF4CAF50),
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Professional services to help grow your business',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.7),
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Business Services Grid
                      LayoutBuilder(
                        builder: (context, constraints) {
                          // Responsive grid based on screen width
                          final gridWidth = constraints.maxWidth;
                          final crossAxisCount = gridWidth > 1200
                              ? 4
                              : gridWidth > 900
                                  ? 3
                                  : gridWidth > 600
                                      ? 2
                                      : 1;
                          final childAspectRatio = gridWidth > 600 ? 1.2 : 1.4;

                          return GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: gridWidth > 600 ? 16 : 8,
                            mainAxisSpacing: gridWidth > 600 ? 16 : 8,
                            childAspectRatio: childAspectRatio,
                            children: [
                              _buildBusinessServiceCard(
                                context,
                                'Tax Help',
                                'Professional tax assistance',
                                Icons.receipt_long,
                                () => _openBusinessService(
                                    context, BusinessServiceType.taxHelp),
                                gridWidth,
                              ),
                              _buildBusinessServiceCard(
                                context,
                                'Legal',
                                'Business registration & compliance',
                                Icons.business,
                                () => _openBusinessService(
                                    context, BusinessServiceType.businessRegistration),
                                gridWidth,
                              ),
                              _buildBusinessServiceCard(
                                context,
                                'Development',
                                'App & web development',
                                Icons.code,
                                () => _openBusinessService(
                                    context, BusinessServiceType.appDevelopment),
                                gridWidth,
                              ),
                              _buildBusinessServiceCard(
                                context,
                                'Marketing',
                                'Advertisement & campaigns',
                                Icons.campaign,
                                () => _openBusinessService(
                                    context, BusinessServiceType.marketing),
                                gridWidth,
                              ),
                              _buildBusinessServiceCard(
                                context,
                                'Hiring',
                                'Employee recruitment',
                                Icons.person_add,
                                () => _openBusinessService(
                                    context, BusinessServiceType.employeeHiring),
                                gridWidth,
                              ),
                              _buildBusinessServiceCard(
                                context,
                                'Investors',
                                'Find funding opportunities',
                                Icons.trending_up,
                                () => _openBusinessService(
                                    context, BusinessServiceType.investorFinding),
                                gridWidth,
                              ),
                              _buildBusinessServiceCard(
                                context,
                                'Consultation',
                                'Strategic business advice',
                                Icons.lightbulb,
                                () => _openBusinessService(
                                    context, BusinessServiceType.businessConsultation),
                                gridWidth,
                              ),
                              _buildBusinessServiceCard(
                                context,
                                'Market Research',
                                'Product-market fit analysis',
                                Icons.analytics,
                                () => _openBusinessService(
                                    context, BusinessServiceType.marketResearch),
                                gridWidth,
                              ),
                              _buildBusinessServiceCard(
                                context,
                                'Patent Filing',
                                'Protect your innovations',
                                Icons.verified_user,
                                () => _openBusinessService(
                                    context, BusinessServiceType.patentFiling),
                                gridWidth,
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _openBusinessService(
      BuildContext context, BusinessServiceType serviceType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            BusinessServicesPortal(initialService: serviceType),
      ),
    );
  }

  Widget _buildBusinessServiceCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    VoidCallback onTap,
    double screenWidth,
  ) {
    final isLargeScreen = screenWidth > 600;
    final padding = isLargeScreen ? 16.0 : 12.0;
    final iconSize = isLargeScreen ? 20.0 : 18.0;
    final titleFontSize = isLargeScreen ? 14.0 : 13.0;
    final descriptionFontSize = isLargeScreen ? 12.0 : 11.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFF4CAF50).withOpacity(0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4CAF50).withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: iconSize + 8,
              height: iconSize + 8,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF4CAF50),
                size: iconSize,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: titleFontSize,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Expanded(
              child: Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7),
                      fontSize: descriptionFontSize,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
