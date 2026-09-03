import 'package:petrimonium/core/di/dependency_injection.dart';
import 'package:petrimonium/features/auth/data/repositories/auth_repository.dart';
import 'package:petrimonium/features/onboarding/data/repositories/onboarding_state_repository.dart';
import 'package:petrimonium/features/pet/domain/repositories/mascot_repository.dart';
import 'package:petrimonium/features/pet/domain/repositories/pet_repository.dart';

/// Where `MyApp` should route the user on cold start.
enum StartRoute { login, petSetup, mentorWelcome, quickSetup, home }

/// A pet that already exists server-side (e.g. from the Academy) but has no
/// name cached on this device yet — first login on a new device — falls
/// back to this name rather than being sent to [StartRoute.petSetup] (see
/// [StartRouteResolver._ensureLocalPetName]): one of the same suggestions
/// `PetNameField` offers during Academy's pet-naming step, so it never reads
/// as an obviously-synthetic placeholder if the user later sees it.
const String kDefaultWalletPetName = 'Nino';

/// Resolves [StartRoute] from persisted auth/onboarding state — extracted
/// from `MyApp._getStartRoute()` so the routing rules are testable without
/// `WidgetTester`.
///
/// Each step gates the next one:
/// not authenticated -> [StartRoute.login]
/// authenticated, no Pet on the account yet -> [StartRoute.petSetup]
/// has a Pet, mentor welcome not seen yet -> [StartRoute.mentorWelcome]
/// welcome seen, quick setup (market/currency) not done -> [StartRoute.quickSetup]
/// everything resolved -> [StartRoute.home]
///
/// A returning Academy user already has a Pet ("mesma conta Petrimonium da
/// Academy") and skips [StartRoute.petSetup] entirely — the pet is a shared
/// cross-app companion, so an existing one is never re-configured, only a
/// missing local name gets backfilled (see [_ensureLocalPetName]). A
/// Wallet-first signup with no Pet at all is routed to [StartRoute.petSetup]
/// to choose a species and name it, via `PetSetupScreen`. The old
/// pet-naming/financial-goal/tutorial/portfolio-choice steps (and their
/// screens) are unreachable from cold start now but not deleted — same
/// "deferred cleanup" pattern as the rest of the Wallet/Academy split —
/// until it's decided whether any of them resurface elsewhere (e.g. a
/// "change goal" Profile setting).
class StartRouteResolver {
  StartRouteResolver({
    AuthRepository? authRepository,
    PetRepository? petRepository,
    MascotRepository? mascotRepository,
    OnboardingStateRepository? onboardingStateRepository,
  })  : _authRepository = authRepository ?? DI.authRepository,
        _petRepository = petRepository ?? DI.petRepository,
        _mascotRepository = mascotRepository ?? DI.mascotRepository,
        _onboardingStateRepository = onboardingStateRepository ?? DI.onboardingStateRepository;

  final AuthRepository _authRepository;
  final PetRepository _petRepository;
  final MascotRepository _mascotRepository;
  final OnboardingStateRepository _onboardingStateRepository;

  Future<StartRoute> resolve() async {
    final loggedIn = await _authRepository.isLoggedIn();
    if (!loggedIn) return StartRoute.login;

    try {
      final hasPet = await _petRepository.getPetStatus();
      if (!hasPet) return StartRoute.petSetup;

      await _ensureLocalPetName();

      final seenMentorWelcome = await _onboardingStateRepository.hasSeenMentorWelcome();
      if (!seenMentorWelcome) return StartRoute.mentorWelcome;

      final quickSetupDone = await _onboardingStateRepository.hasCompletedQuickSetup();
      if (!quickSetupDone) return StartRoute.quickSetup;

      return StartRoute.home;
    } catch (_) {
      // Any failure while resolving pet/onboarding state is treated as "not
      // safely resumable" — log the user out rather than risk stranding
      // them on a screen that assumes state that couldn't be loaded.
      await _authRepository.logout();
      return StartRoute.login;
    }
  }

  Future<void> _ensureLocalPetName() async {
    final profile = await _mascotRepository.loadProfile();
    final hasName = profile.name != null && profile.name!.trim().isNotEmpty;
    if (!hasName) {
      await _mascotRepository.saveName(kDefaultWalletPetName);
    }
  }
}
