import 'package:flutter/material.dart';
import 'package:petrimonium/core/constants/app_strings.dart';
import 'package:petrimonium/core/theme/app_color_tokens.dart';
import 'package:petrimonium/core/utils/translator.dart';

/// The inverse of Academy's `WalletBridgeCta` — Wallet's link out to
/// Petrimonium Academy for the educational content behind a real position
/// or concept. Unlike Academy's current CTA (still same-repo, so it can
/// fall back to an in-app tab switch), Wallet and Academy are genuinely
/// separate apps with no shared code — this always renders the disabled
/// "coming soon" state until real OS-level deep-linking (`url_launcher` +
/// a `petrimonium://` scheme) is wired, per docs/ECOSYSTEM.md's Stage 5
/// note. Never omitted for that reason — a visible, disabled state tells
/// the user this is coming, rather than silently absent.
class AcademyBridgeCta extends StatelessWidget {
  const AcademyBridgeCta({super.key, this.onOpenAcademy});

  final VoidCallback? onOpenAcademy;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    final available = onOpenAcademy != null;
    return TextButton.icon(
      onPressed: onOpenAcademy,
      icon: Icon(
        Icons.school_outlined,
        size: 18,
        color: available ? tokens.primary : tokens.textTertiary,
      ),
      label: Text(
        Translator.translate(
          available
              ? AppStrings.academyBridgeCtaLabel
              : AppStrings.academyBridgeComingSoon,
        ),
        style: TextStyle(
          color: available ? tokens.primary : tokens.textTertiary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
