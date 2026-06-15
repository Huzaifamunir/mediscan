import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/analysis_result.dart';

class StorageService {
  static const String _historyKey = 'analysis_history';
  static const String _apiKeyKey = 'openai_api_key';

  // ─── API Key ─────────────────────────────────────────────────────────────────
  Future<void> saveApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyKey, apiKey);
  }

  Future<String?> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_apiKeyKey);
  }

  // ─── History ─────────────────────────────────────────────────────────────────
  Future<List<AnalysisResult>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getStringList(_historyKey) ?? [];
    return jsonStr
        .map((s) => AnalysisResult.fromJson(jsonDecode(s)))
        .toList()
      ..sort((a, b) => b.analyzedAt.compareTo(a.analyzedAt));
  }

  Future<void> saveResult(AnalysisResult result) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_historyKey) ?? [];
    existing.insert(0, jsonEncode(result.toJson()));
    // Keep max 50 results
    if (existing.length > 50) {
      existing.removeLast();
    }
    await prefs.setStringList(_historyKey, existing);
  }

  Future<void> deleteResult(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_historyKey) ?? [];
    final filtered = existing.where((s) {
      final data = jsonDecode(s);
      return data['id'] != id;
    }).toList();
    await prefs.setStringList(_historyKey, filtered);
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }
}
