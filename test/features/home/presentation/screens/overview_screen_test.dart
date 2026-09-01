import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:petrimonium/core/theme/app_theme.dart';
import 'package:petrimonium/core/utils/translator.dart';
import 'package:petrimonium/features/home/presentation/screens/overview_screen.dart';
import 'package:petrimonium/features/home/presentation/widgets/portfolio_not_connected_card.dart';
import 'package:petrimonium/features/portfolio/domain/entities/holding.dart';
import 'package:petrimonium/features/portfolio/presentation/controllers/portfolio_controller.dart';
import 'package:petrimonium/features/portfolio/presentation/widgets/holdings_section.dart';

import '../../../portfolio/presentation/controllers/portfolio_controller_test.dart';
import '../../../portfolio/domain/services/portfolio_test_fixtures.dart';

void main() {
  late FakePortfolioRepository repository;
  late PortfolioController controller;

  setUp(() {
    Translator.currentLanguage = 'pt';
    SharedPreferences.setMockInitialValues({});
    repository = FakePortfolioRepository();
    controller = PortfolioController(
      repository: repository,
      achievementsLocalRepository: FakeAchievementsLocalRepository(),
      achievementsRepository: FakeAchievementsRepository(),
      gamificationRepository: FakeGamificationRepository(),
      missionsRepository: FakeMissionsRepository(),
    );
  });

  tearDown(() => controller.dispose());

  Widget buildTestableWidget() {
    return MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: OverviewScreen(controller: controller, onOpenMentor: (_) {}),
      ),
    );
  }

  group('OverviewScreen', () {
    testWidgets('shows PortfolioNotConnectedCard when there are no holdings', (tester) async {
      await controller.loadAll();
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      expect(find.byType(PortfolioNotConnectedCard), findsOneWidget);
      expect(find.byType(HoldingsSection), findsNothing);
    });

    testWidgets('shows the wealth hero, change placeholder and holdings when holdings exist', (tester) async {
      final holdings = [lot(ticker: 'PETR4', quantity: 100, purchasePrice: 10)];
      repository.holdingsToReturn = Holding.fromLots(holdings);
      repository.summaryToReturn = statsFromLots(holdings).summary;
      await controller.loadAll();

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      expect(find.byType(PortfolioNotConnectedCard), findsNothing);
      expect(find.text('Como está meu patrimônio?'), findsOneWidget);
      expect(find.text('O que mudou (últimos 30 dias)'), findsOneWidget);
      expect(
        find.text('Detalhamento por valorização, aportes e rendimentos — em breve.'),
        findsOneWidget,
      );
      expect(find.byType(HoldingsSection), findsOneWidget);
    });

    testWidgets('shows the "Bem-vindo(a) de volta" greeting', (tester) async {
      await controller.loadAll();
      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      expect(find.text('Bem-vindo(a) de volta'), findsOneWidget);
    });
  });
}
