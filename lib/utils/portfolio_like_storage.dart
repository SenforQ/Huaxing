import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class PortfolioLikeStorage {
  PortfolioLikeStorage._();

  static const String _prefsKey = 'my_portfolio_liked_paths_v1';

  static Future<Set<String>> loadLikedPaths() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_prefsKey);
    if (raw == null || raw.trim().isEmpty) {
      return <String>{};
    }
    try {
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      return list.map((dynamic e) => e.toString()).toSet();
    } catch (_) {
      return <String>{};
    }
  }

  static Future<void> saveLikedPaths(Set<String> paths) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(paths.toList()));
  }

  static Future<void> toggleLikePath(String localPath) async {
    final String key = localPath.trim();
    if (key.isEmpty) return;
    final Set<String> paths = await loadLikedPaths();
    if (paths.contains(key)) {
      paths.remove(key);
    } else {
      paths.add(key);
    }
    await saveLikedPaths(paths);
  }
}
