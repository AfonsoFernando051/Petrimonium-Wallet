import 'package:flutter/material.dart';
import 'package:petrimonium/core/constants/app_strings.dart';
import 'package:petrimonium/core/di/dependency_injection.dart';
import 'package:petrimonium/core/theme/app_color_tokens.dart';
import 'package:petrimonium/core/utils/formatters.dart';
import 'package:petrimonium/core/utils/translator.dart';
import 'package:petrimonium/core/widgets/app_loading_indicator.dart';
import 'package:petrimonium/core/widgets/layer_chip.dart';
import 'package:petrimonium/features/home/presentation/widgets/mentor_insight_card.dart';
import 'package:petrimonium/features/home/presentation/widgets/portfolio_not_connected_card.dart';
import 'package:petrimonium/features/portfolio/domain/entities/holding.dart';
import 'package:petrimonium/features/portfolio/domain/entities/investment_type_display.dart';
import 'package:petrimonium/features/portfolio/presentation/controllers/portfolio_controller.dart';
import 'package:petrimonium/features/portfolio/presentation/widgets/holdings_section.dart';
import 'package:petrimonium/features/portfolio/presentation/widgets/shared/error_banner.dart';

/// Wallet's "Início" — the unified patrimônio + Mentor screen, absorbing
/// what used to be a separate Carteira tab ("Home unifica patrimônio
/// total... sem uma aba 'Carteira' redundante" per the Wallet design
/// system). Shows: a greeting, the Mentor's one interpretation for the
/// session, total wealth (labeled as data — source/timestamp always shown),
/// a placeholder for the valorização/aportes/rendimentos breakdown (real
/// backend field doesn't exist yet), and holdings grouped by category.
///
/// No own `Scaffold`/`AppBar`/background — embedded directly in
/// `DashboardScreen`'s shared chrome.
class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key, required this.controller, required this.onOpenMentor});

  final PortfolioController controller;

  /// Opens the Mentor tab, optionally resuming a specific conversation
  /// (Home's Mentor card's "Por que estou vendo isto?") — `null` opens a
  /// blank chat.
  final ValueChanged<int?> onOpenMentor;

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  String? _displayName;

  @override
  void initState() {
    super.initState();
    _loadDisplayName();
  }

  // There is no user display-name field anywhere yet (backend or client) —
  // only email. Derived from it as a graceful, honest stand-in rather than
  // fabricated; the real fix is a backend profile-name field.
  Future<void> _loadDisplayName() async {
    final email = await DI.authRepository.getSavedEmail();
    if (!mounted || email == null || email.isEmpty) return;
    final localPart = email.split('@').first;
    final firstToken = localPart.split(RegExp(r'[._-]')).first;
    if (firstToken.isEmpty) return;
    setState(() {
      _displayName = firstToken[0].toUpperCase() + firstToken.substring(1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    if (controller.isLoading && controller.holdings.isEmpty && controller.error == null) {
      return const AppLoadingIndicator();
    }

    final hasPortfolio = controller.holdings.isNotEmpty;

    return RefreshIndicator(
      color: context.colors.primary,
      backgroundColor: context.colors.surfaceElevated,
      onRefresh: controller.refresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Greeting(displayName: _displayName),
            const SizedBox(height: 16),

            MentorInsightCard(onOpenMentor: widget.onOpenMentor),

            if (controller.error != null) ...[
              ErrorBanner(onRetry: controller.refresh),
              const SizedBox(height: 16),
            ],

            if (!hasPortfolio)
              const PortfolioNotConnectedCard()
            else ...[
              _WealthHeroCard(controller: controller),
              const SizedBox(height: 16),
              const _WealthChangePlaceholderCard(),
              const SizedBox(height: 20),
              Text(
                Translator.translate(AppStrings.homeHoldingsSectionTitle),
                style: TextStyle(
                  color: context.colors.textTertiary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 8),
              HoldingsSection(
                holdings: controller.holdings,
                totalPortfolioValue: controller.summary.currentValue,
              ),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.displayName});

  final String? displayName;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          Translator.translate(AppStrings.homeGreetingLabel),
          style: TextStyle(color: tokens.textSecondary, fontSize: 13),
        ),
        if (displayName != null) ...[
          const SizedBox(height: 2),
          Text(
            displayName!,
            style: TextStyle(color: tokens.textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ],
    );
  }
}

class _WealthHeroCard extends StatelessWidget {
  const _WealthHeroCard({required this.controller});

  final PortfolioController controller;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    final now = TimeOfDay.now();
    final time = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final types = controller.holdings
        .map((Holding h) => h.type)
        .toSet()
        .map((type) => type.label)
        .join(', ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            Translator.translate(AppStrings.homeWealthSectionTitle),
            style: TextStyle(color: tokens.textTertiary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6),
          ),
          const SizedBox(height: 12),
          LayerChip(
            layer: DataLayer.data,
            label: '${Translator.translate(AppStrings.homeWealthDataChipLabel)} · B3, hoje $time',
          ),
          const SizedBox(height: 12),
          Text(
            AppFormatters.currency(controller.summary.currentValue),
            style: TextStyle(
              color: tokens.textPrimary,
              fontSize: 30,
              fontWeight: FontWeight.bold,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'BRL · ${Translator.translate(AppStrings.homeWealthScopePrefix)}: $types',
            style: TextStyle(color: tokens.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _WealthChangePlaceholderCard extends StatelessWidget {
  const _WealthChangePlaceholderCard();

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            Translator.translate(AppStrings.homeChangeSectionTitle),
            style: TextStyle(color: tokens.textTertiary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6),
          ),
          const SizedBox(height: 12),
          LayerChip(
            layer: DataLayer.calculation,
            label: Translator.translate(AppStrings.homeChangeCalcChipLabel),
          ),
          const SizedBox(height: 12),
          Text(
            Translator.translate(AppStrings.homeChangeComingSoonNote),
            style: TextStyle(color: tokens.textSecondary, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }
}
