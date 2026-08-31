import 'package:petrimonium/core/theme/background_presets.dart';
import 'package:petrimonium/features/pet/presentation/companion/pet_context.dart';

/// Pure tab-index → behavior mappings for [DashboardScreen]'s 4 bottom-nav
/// tabs (Visão Geral/Carteira/Proventos/Mentor). Wallet has no Academy tab —
/// see docs/ECOSYSTEM.md's Stage 5 note. The `dashboard` feature has no
/// domain layer of its own, so this small but real business logic (which
/// background mood and which persistent-companion voice each tab gets)
/// previously lived inline in the screen; pulled out here so it's
/// independently testable and the screen only orchestrates widgets.
class DashboardTabRouter {
  DashboardTabRouter._();

  static const int homeTab = 0;
  static const int walletTab = 1;
  static const int passiveIncomeTab = 2;
  static const int mentorTab = 3;

  // Content-hierarchy comes from swapping intensity per selected tab: full
  // cosmic expression on Visão Geral, progressively quieter for the more
  // data-dense tabs.
  static const List<BackgroundIntensity> _tabIntensities = [
    BackgroundIntensity.immersive, // Visão Geral
    BackgroundIntensity.balanced, // Carteira / Portfolio
    BackgroundIntensity.balanced, // Proventos / Passive income
    BackgroundIntensity.mentor, // Mentor
  ];

  static BackgroundIntensity backgroundIntensityFor(int tabIndex) => _tabIntensities[tabIndex];

  /// (`docs/PROJECT_CONTEXT.md`'s Pet Companion section, `PetContext`'s doc
  /// comment.) `PetContext.academy` is never returned here — Wallet has no
  /// Academy tab to map a companion voice to; it's still a valid
  /// destination for the pet's "learn more" action (see
  /// `DashboardScreen._handleCompanionDestination`), just not a tab.
  static PetContext petContextFor(int tabIndex) => switch (tabIndex) {
        homeTab => PetContext.home,
        walletTab || passiveIncomeTab =>
          PetContext.portfolio, // Carteira / Proventos share the same companion voice
        _ => PetContext.mentor,
      };

  /// Whether [tabIndex] is one of the two portfolio-flavored tabs — used to
  /// decide whether the companion greeting needs the holdings count.
  static bool showsHoldingsCount(int tabIndex) => tabIndex == walletTab || tabIndex == passiveIncomeTab;
}

/// Small display-formatting helpers for the Dashboard chrome — kept
/// alongside [DashboardTabRouter] rather than inline in the screen for the
/// same "no domain layer to hold this" reason.
class DashboardFormatters {
  DashboardFormatters._();

  /// Notification-bell badge count: caps the visible digits at "9+" instead
  /// of letting a busy user's badge grow unbounded and break the pill layout.
  static String notificationBadgeLabel(int count) => count > 9 ? '9+' : '$count';
}
