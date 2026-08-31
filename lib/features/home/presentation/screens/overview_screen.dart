import 'package:flutter/material.dart';
import 'package:petrimonium/core/theme/app_color_tokens.dart';
import 'package:petrimonium/core/widgets/app_loading_indicator.dart';
import 'package:petrimonium/features/home/presentation/widgets/academy_bridge_cta.dart';
import 'package:petrimonium/features/home/presentation/widgets/portfolio_not_connected_card.dart';
import 'package:petrimonium/features/home/presentation/widgets/portfolio_reminder_banner.dart';
import 'package:petrimonium/features/portfolio/domain/entities/insight.dart';
import 'package:petrimonium/features/portfolio/domain/services/insight_generator.dart';
import 'package:petrimonium/features/portfolio/presentation/controllers/portfolio_controller.dart';
import 'package:petrimonium/features/portfolio/presentation/widgets/hero_summary_section.dart';
import 'package:petrimonium/features/portfolio/presentation/widgets/insights_section.dart';
import 'package:petrimonium/features/portfolio/presentation/widgets/shared/error_banner.dart';
import 'package:petrimonium/features/portfolio/presentation/widgets/wealth_evolution_bar_card.dart';

/// Wallet's "Visão Geral" — the real-portfolio dashboard landing screen,
/// replacing the old learning-first `HomeScreen` (which was Academy's
/// orchestration layer and never belonged in a real-money app). Shows a
/// patrimonial snapshot (current value, wealth evolution, insights) and a
/// bridge to Academy for the educational side of a concept — never a
/// lesson, module, mission, or quiz, which live only in Academy now.
///
/// No own `Scaffold`/`AppBar`/background — embedded directly in
/// `DashboardScreen`'s shared chrome, same as `PortfolioScreen`.
class OverviewScreen extends StatelessWidget {
  const OverviewScreen({
    super.key,
    required this.controller,
    required this.showPortfolioReminder,
    required this.onDismissPortfolioReminder,
    required this.investorProfileUnanswered,
    required this.onOpenPortfolioTab,
    this.onOpenAcademy,
  });

  final PortfolioController controller;
  final bool showPortfolioReminder;
  final VoidCallback onDismissPortfolioReminder;
  final bool investorProfileUnanswered;
  final VoidCallback onOpenPortfolioTab;

  /// `null` until real deep-linking to the separate Academy app exists —
  /// see `AcademyBridgeCta`'s class doc.
  final VoidCallback? onOpenAcademy;

  @override
  Widget build(BuildContext context) {
    if (controller.isLoading &&
        controller.holdings.isEmpty &&
        controller.error == null) {
      return const AppLoadingIndicator();
    }

    final hasPortfolio = controller.holdings.isNotEmpty;
    final List<Insight> insights = hasPortfolio
        ? InsightGenerator.generate(
            controller.stats,
            onOpenAllocation: onOpenPortfolioTab,
            onOpenConfigure: onOpenPortfolioTab,
          )
        : const <Insight>[];

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
            if (controller.error != null) ...[
              ErrorBanner(onRetry: controller.refresh),
              const SizedBox(height: 16),
            ],

            if (showPortfolioReminder) ...[
              PortfolioReminderBanner(onDismiss: onDismissPortfolioReminder),
              const SizedBox(height: 16),
            ],

            if (!hasPortfolio)
              PortfolioNotConnectedCard(
                showInvestorProfileAction: investorProfileUnanswered,
              )
            else ...[
              HeroSummarySection(controller: controller),
              const SizedBox(height: 16),
              WealthEvolutionBarCard(controller: controller),
              const SizedBox(height: 16),
              if (insights.isNotEmpty) ...[
                InsightsSection(insights: insights),
                const SizedBox(height: 16),
              ],
            ],

            Align(
              alignment: Alignment.centerLeft,
              child: AcademyBridgeCta(onOpenAcademy: onOpenAcademy),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
