import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyPortfolioStorage {
  MyPortfolioStorage._();

  static const String _prefsKey = 'my_portfolio_local_paths_v1';

  static Future<List<String>> loadPaths() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_prefsKey);
    if (raw == null || raw.trim().isEmpty) {
      return <String>[];
    }
    try {
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      final List<String> paths = list
          .map((dynamic e) => e.toString().trim())
          .where((String s) => s.isNotEmpty)
          .toList();
      final List<String> existing = <String>[];
      for (final String path in paths) {
        if (File(path).existsSync()) {
          existing.add(path);
        }
      }
      if (existing.length != paths.length) {
        await savePaths(existing);
      }
      return existing;
    } catch (_) {
      return <String>[];
    }
  }

  static Future<void> savePaths(List<String> paths) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(paths));
  }

  static Future<String?> copyIntoPortfolio(String sourcePath) async {
    try {
      final Directory dir = await getApplicationDocumentsDirectory();
      final String portfolioDir = p.join(dir.path, 'my_portfolio');
      await Directory(portfolioDir).create(recursive: true);
      final String ext = p.extension(sourcePath);
      final String safeExt =
          (ext.isNotEmpty && ext.length <= 8) ? ext : '.jpg';
      final String destPath = p.join(
        portfolioDir,
        '${DateTime.now().millisecondsSinceEpoch}$safeExt',
      );
      await File(sourcePath).copy(destPath);
      return destPath;
    } catch (_) {
      return null;
    }
  }

  static Future<void> deleteFileIfExists(String path) async {
    try {
      final File f = File(path);
      if (await f.exists()) {
        await f.delete();
      }
    } catch (_) {}
  }
}
