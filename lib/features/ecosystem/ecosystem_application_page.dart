import 'package:flutter/material.dart';
import 'ecosystem_service_model.dart';

/// A lightweight preview of the services Terai may add in the future.
/// Cards are deliberately informational and have no navigation or purchase flow.
class EcosystemApplicationPage extends StatelessWidget {
  const EcosystemApplicationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                    child: _HeroPanel(),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 4, 24, 18),
                    child: Row(children: [
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text('Ecosystem',
                                style:
                                    Theme.of(context).textTheme.headlineMedium),
                            const SizedBox(height: 6),
                            Text(
                                'Services we are thoughtfully preparing for the Terai community.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.color)),
                          ])),
                      const _StatusPill(),
                    ]),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
              sliver: SliverLayoutBuilder(builder: (context, constraints) {
                final width = constraints.crossAxisExtent;
                final columns = width >= 1050
                    ? 3
                    : width >= 640
                        ? 2
                        : 1;
                return SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    mainAxisExtent: 238,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _ServiceCard(
                        service: ecosystemServices[index], index: index),
                    childCount: ecosystemServices.length,
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(builder: (context, constraints) {
      final compact = constraints.maxWidth < 680;
      final copy = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(99)),
            child: const Text('COMING SOON',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1)),
          ),
          const SizedBox(height: 18),
          Text('Tools and services for people who build.',
              style: theme.textTheme.headlineLarge
                  ?.copyWith(color: Colors.white, fontSize: compact ? 30 : 40)),
          const SizedBox(height: 12),
          Text(
              'We are keeping Terai focused on finding the right people first. The wider ecosystem will arrive only when it adds real value.',
              style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.88), height: 1.5)),
        ],
      );
      return Container(
        padding: EdgeInsets.all(compact ? 24 : 38),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF18243B), Color(0xFF263B5D)]),
          borderRadius: BorderRadius.circular(compact ? 24 : 28),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF172033).withValues(alpha: 0.18),
                blurRadius: 30,
                offset: const Offset(0, 14))
          ],
        ),
        child: compact
            ? copy
            : Row(children: [
                Expanded(flex: 3, child: copy),
                const SizedBox(width: 48),
                Expanded(child: _HeroMark())
              ]),
      );
    });
  }
}

class _HeroMark extends StatelessWidget {
  const _HeroMark();
  @override
  Widget build(BuildContext context) => Container(
        height: 166,
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12))),
        child: const Center(
            child: Icon(Icons.hub_rounded, color: Color(0xFFFFA17D), size: 72)),
      );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(99)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.schedule_rounded,
              size: 16, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 6),
          Text('In development',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700))
        ]),
      );
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.service, required this.index});
  final EcosystemServiceData service;
  final int index;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 280 + index * 45),
      curve: Curves.easeOutCubic,
      builder: (_, value, child) => Opacity(
          opacity: value,
          child: Transform.translate(
              offset: Offset(0, 12 * (1 - value)), child: child)),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                  width: 48,
                  height: 48,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: service.color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(14)),
                  child: Image.asset(service.iconPath, fit: BoxFit.contain)),
              const Spacer(),
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(99)),
                  child: Text('Coming soon',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary))),
            ]),
            const SizedBox(height: 18),
            Text(service.title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 7),
            Text(service.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.textTheme.bodySmall?.color)),
            const Spacer(),
            Row(
                children: service.features
                    .take(2)
                    .map((feature) => Expanded(
                        child: Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Row(children: [
                              Icon(Icons.check_circle_outline_rounded,
                                  color: service.color, size: 15),
                              const SizedBox(width: 5),
                              Expanded(
                                  child: Text(feature.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodySmall))
                            ]))))
                    .toList()),
          ]),
        ),
      ),
    );
  }
}
