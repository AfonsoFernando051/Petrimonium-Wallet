import 'package:petrimonium/core/di/dependency_injection.dart';
import 'package:petrimonium/features/auth/data/repositories/auth_repository.dart';
import 'package:petrimonium/features/onboarding/data/repositories/onboarding_state_repository.dart';
import 'package:petrimonium/features/pet/data/models/pet_specie_enum.dart';
import 'package:petrimonium/features/pet/domain/repositories/mascot_repository.dart';
import 'package:petrimonium/features/pet/domain/repositories/pet_repository.dart';

/// Where `MyApp` should route the user on cold start.
enum StartRoute { login, mentorWelcome, quickSetup, home }

/// A default pet gets silently provisioned for a Wallet-first signup (see
/// [StartRouteResolver._ensureDefaultPet]) — one of the same suggestions
/// `PetNameField` offers during Academy's pet-naming step, so it never reads
/// as an obviously-synthetic placeholder if the user later sees it.
const String kDefaultWalletPetName = 'Nino';

/// Resolves [StartRoute] from persisted auth/onboarding state — extracted
/// from `MyApp._getStartRoute()` so the routing rules are testable without
/// `WidgetTester`.
///
/// Each step gates the next one:
/// not authenticated -> [StartRoute.login]
/// authenticated, mentor welcome not seen yet -> [StartRoute.mentorWelcome]
/// welcome seen, quick setup (market/currency) not done -> [StartRoute.quickSetup]
/// everything resolved -> [StartRoute.home]
///
/// Wallet's mini-onboarding is deliberately just these 2 screens — per the
/// design, a returning Academy user already has a pet ("mesma conta
/// Petrimonium da Academy"), and a Wallet-first signup gets one silently
/// provisioned (see [_ensureDefaultPet]) rather than shown a chooser: the
/// pet is a shared cross-app companion, not something Wallet itself is
/// asking the user to configure. The old pet-naming/financial-goal/tutorial/
/// portfolio-choice steps (and their screens) are unreachable from cold
/// start now but not deleted — same "deferred cleanup" pattern as the rest
/// of the Wallet/Academy split — until it's decided whether any of them
/// resurface elsewhere (e.g. a "change goal" Profile setting).
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
      await _ensureDefaultPet();

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

  Future<void> _ensureDefaultPet() async {
    final hasPet = await _petRepository.getPetStatus();
    final profile = await _mascotRepository.loadProfile();
    final hasName = profile.name != null && profile.name!.trim().isNotEmpty;
    if (hasPet && hasName) return;

    if (!hasPet) {
      await _petRepository.configurePet(PetSpecieEnum.DOG);
    }
    if (!hasName) {
      await _mascotRepository.saveName(kDefaultWalletPetName);
    }
  }
}
