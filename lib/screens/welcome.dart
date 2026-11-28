import 'package:flutter/material.dart';

import '../app_state.dart';
import '../config.dart';
import '../theme.dart';
import '../widgets/travel_illustration.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints:
                    BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: const BoxDecoration(
                              color: HopColors.sage,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                                Icons.directions_car_filled_rounded,
                                color: Colors.white,
                                size: 28),
                          ),
                          const SizedBox(width: 12),
                          Text('HopAlong',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(fontSize: 32)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const TravelIllustration(height: 200),
                      Text('Travel together,\narrive smiling.',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(fontSize: 30, height: 1.15)),
                      const SizedBox(height: 10),
                      Text(
                        'A friendly community for sharing rides with people '
                        'going your way. No taxis, no surge — just neighbours '
                        'hopping along.',
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(color: HopColors.inkSoft),
                      ),
                      const SizedBox(height: 28),
                      _ModeCard(
                        icon: Icons.search_rounded,
                        title: 'Find a ride',
                        subtitle: 'Member · Join rides posted by others',
                        color: HopColors.sage,
                        onTap: () => Navigator.of(context)
                            .pushNamed('/auth', arguments: 'member'),
                      ),
                      const SizedBox(height: 14),
                      _ModeCard(
                        icon: Icons.directions_car_rounded,
                        title: 'Offer a ride',
                        subtitle: 'Rider · Share your empty seats',
                        color: HopColors.peachDeep,
                        onTap: () => Navigator.of(context)
                            .pushNamed('/auth', arguments: 'rider'),
                      ),
                      const SizedBox(height: 20),
                      // Demo sign-in only exists in demo mode. In the live
                      // app this button is hidden entirely.
                      if (AppConfig.isDemoMode)
                        Center(
                          child: TextButton(
                            onPressed: () async {
                              await state.demoSignIn();
                              if (context.mounted) {
                                Navigator.of(context)
                                    .pushReplacementNamed('/home');
                              }
                            },
                            child: const Text('Continue in demo →'),
                          ),
                        ),
                      const SizedBox(height: 8),
                      const Center(
                        child: Text(
                          'Be kind on the road · Share rides with neighbours',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 12, color: HopColors.inkSoft),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.color,
      required this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(18)),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 18, color: HopColors.inkSoft),
            ],
          ),
        ),
      ),
    );
  }
}
