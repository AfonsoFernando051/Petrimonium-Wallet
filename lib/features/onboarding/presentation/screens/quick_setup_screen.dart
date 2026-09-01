import 'package:flutter/material.dart';
import 'package:petrimonium/core/constants/app_strings.dart';
import 'package:petrimonium/core/di/dependency_injection.dart';
import 'package:petrimonium/core/theme/app_color_tokens.dart';
import 'package:petrimonium/core/theme/background_presets.dart';
import 'package:petrimonium/core/utils/translator.dart';
import 'package:petrimonium/features/onboarding/data/models/wallet_base_currency_enum.dart';
import 'package:petrimonium/features/onboarding/data/models/wallet_market_enum.dart';
import 'package:petrimonium/features/onboarding/presentation/widgets/onboarding_scaffold.dart';
import 'package:petrimonium/main.dart';

/// Screen 2 of 2 in the Wallet's mini-onboarding: country/market and
/// base-currency, the only setup this app asks for before Home. Both
/// pickers currently resolve to a single option (see [WalletMarketEnum]
/// doc) — real, extensible selectors rather than static text, without
/// pretending multi-market support that doesn't exist yet.
class QuickSetupScreen extends StatefulWidget {
  const QuickSetupScreen({super.key});

  @override
  State<QuickSetupScreen> createState() => _QuickSetupScreenState();
}

class _QuickSetupScreenState extends State<QuickSetupScreen> {
  WalletMarketEnum _market = WalletMarketEnum.brazilB3;
  late WalletBaseCurrencyEnum _currency = _market.defaultCurrency;
  bool _isLoading = false;

  Future<void> _pickMarket() async {
    final selected = await showModalBottomSheet<WalletMarketEnum>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _OptionSheet<WalletMarketEnum>(
        options: WalletMarketEnum.values,
        current: _market,
        labelOf: (m) => '${m.flag} ${m.label}',
      ),
    );
    if (selected != null) {
      setState(() {
        _market = selected;
        _currency = selected.defaultCurrency;
      });
    }
  }

  Future<void> _pickCurrency() async {
    final selected = await showModalBottomSheet<WalletBaseCurrencyEnum>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _OptionSheet<WalletBaseCurrencyEnum>(
        options: WalletBaseCurrencyEnum.values,
        current: _currency,
        labelOf: (c) => c.label,
      ),
    );
    if (selected != null) setState(() => _currency = selected);
  }

  Future<void> _handleContinue() async {
    setState(() => _isLoading = true);
    await DI.walletMarketPreferencesRepository.saveMarket(_market);
    await DI.walletMarketPreferencesRepository.saveBaseCurrency(_currency);
    await DI.onboardingStateRepository.markQuickSetupDone();

    if (mounted) {
      await Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MyApp()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    return OnboardingScaffold(
      intensity: BackgroundIntensity.balanced,
      step: 2,
      totalSteps: 2,
      title: Translator.translate(AppStrings.quickSetupTitle),
      subtitle: Translator.translate(AppStrings.quickSetupSubtitle),
      ctaLabel: Translator.translate(AppStrings.quickSetupCta),
      isCtaLoading: _isLoading,
      onCta: _handleContinue,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(Translator.translate(AppStrings.quickSetupMarketLabel)),
          const SizedBox(height: 8),
          _SetupSelectField(
            value: '${_market.flag} ${_market.label}',
            onTap: _pickMarket,
          ),
          const SizedBox(height: 20),
          _FieldLabel(Translator.translate(AppStrings.quickSetupCurrencyLabel)),
          const SizedBox(height: 8),
          _SetupSelectField(
            value: _currency.label,
            onTap: _pickCurrency,
          ),
          const SizedBox(height: 20),
          Text(
            Translator.translate(AppStrings.quickSetupFooterNote),
            style: TextStyle(color: tokens.textTertiary, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;

  const _FieldLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(color: context.colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
    );
  }
}

class _SetupSelectField extends StatelessWidget {
  final String value;
  final VoidCallback onTap;

  const _SetupSelectField({required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: tokens.primary.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(value, style: TextStyle(color: tokens.textPrimary, fontSize: 15)),
            ),
            Icon(Icons.expand_more, color: tokens.textTertiary),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet listing every value of [T] — currently always a single row
/// (see [WalletMarketEnum]/[WalletBaseCurrencyEnum] docs), but a real list
/// so a second option later is just another enum value, no screen rework.
class _OptionSheet<T> extends StatelessWidget {
  final List<T> options;
  final T current;
  final String Function(T) labelOf;

  const _OptionSheet({required this.options, required this.current, required this.labelOf});

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: tokens.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: tokens.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final option in options)
              ListTile(
                title: Text(labelOf(option), style: TextStyle(color: tokens.textPrimary)),
                trailing: option == current ? Icon(Icons.check, color: tokens.primary) : null,
                onTap: () => Navigator.of(context).pop(option),
              ),
          ],
        ),
      ),
    );
  }
}
