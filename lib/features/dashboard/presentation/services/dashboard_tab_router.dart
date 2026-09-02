import 'package:petrimonium/features/pet/presentation/companion/pet_context.dart';

/// Pure tab-index → behavior mappings for [DashboardScreen]'s 3 bottom-nav
/// tabs (Início/Proventos/Mentor). Início absorbs what used to be a separate
/// Carteira tab — "Home unifica patrimônio total... sem uma aba 'Carteira'
/// redundante" per the Wallet design system — and Wallet has no Academy tab
/// either, see docs/ECOSYSTEM.md's Stage 5 note. The `dashboard` feature has
/// no domain layer of its own, so this small but real business logic
/// (which persistent-companion voice each tab gets) previously lived inline
/// in the screen; pulled out here so it's independently testable and the
/// screen only orchestrates widgets.
class DashboardTabRouter {
  DashboardTabRouter._();

  static const int homeTab = 0;
  static const int passiveIncomeTab = 1;
  static const int mentorTab = 2;

  /// (`docs/PROJECT_CONTEXT.md`'s Pet Companion section, `PetContext`'s doc
  /// comment.) `PetContext.academy` is never returned here — Wallet has no
  /// Academy tab to map a companion voice to; it's still a valid
  /// destination for the pet's "learn more" action (see
  /// `DashboardScreen._handleCompanionDestination`), just not a tab.
  static PetContext petContextFor(int tabIndex) => switch (tabIndex) {
        homeTab => PetContext.home,
        passiveIncomeTab => PetContext.portfolio,
        _ => PetContext.mentor,
      };

  /// Whether [tabIndex] is one of the two portfolio-flavored tabs — used to
  /// decide whether the companion greeting needs the holdings count. Início
  /// now shows holdings directly (it absorbed Carteira), so it qualifies too.
  static bool showsHoldingsCount(int tabIndex) => tabIndex == homeTab || tabIndex == passiveIncomeTab;
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
