import 'package:flutter/material.dart';
import '../../../../core/widgets/cosmic_background.dart';

/// Same living nebula/aurora background every other Wallet screen uses (the
/// default `bg_nebula.png`, `BackgroundIntensity.balanced`) — previously
/// this overrode it with `questionary_space_paw.png`, a leftover artwork
/// asset from the old pre-redesign questionnaire screen, which read as an
/// inconsistent, off-brand background against the new flat login layout.
class LoginBackground extends StatelessWidget {
  const LoginBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return const CosmicBackground(child: SizedBox.shrink());
  }
}
