import 'dart:convert';
import 'package:petrimonium/core/network/api_client.dart';
import 'package:petrimonium/core/network/api_error_parser.dart';
import 'package:petrimonium/features/investment/data/models/asset_registration_model.dart';

class InvestmentRemoteDataSource {
  final ApiClient apiClient;

  InvestmentRemoteDataSource({required this.apiClient});

  /// [confirmReplace] tells the backend the caller knows this call *replaces*
  /// the whole portfolio and has seen what it is replacing. The backend
  /// rejects an unconfirmed submission that would end up with fewer lots than
  /// the user holds (409 `PORTFOLIO_REPLACE_NOT_CONFIRMED`), which is what
  /// protects app versions predating this flag from wiping a portfolio after a
  /// failed load — see `InvestmentConfigurationScreen`.
  Future<void> configureInvestments(
    List<AssetRegistrationModel> investments, {
    bool confirmReplace = false,
  }) async {
    final response = await apiClient.post(
      '/api/investments/configure?confirmReplace=$confirmReplace',
      investments.map((e) => e.toJson()).toList(),
    );

    if (response.statusCode != 200) {
      throw Exception(extractErrorDetail(response, fallback: 'Failed to configure investments'));
    }
  }

  Future<Map<String, dynamic>?> fetchQuote(String ticker) async {
    try {
      final response = await apiClient.get('/api/investments/quote/$ticker');
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      // Return null on failure
    }
    return null;
  }

  Future<Map<String, dynamic>?> fetchQuoteAtDate(String ticker, String date) async {
    try {
      final response = await apiClient.get('/api/investments/quote/$ticker/at-date?date=$date');
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      // Return null on failure
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> searchQuotes(String query) async {
    try {
      final response = await apiClient.get('/api/investments/search?query=$query');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      // return empty array on failure
    }
    return [];
  }
}
