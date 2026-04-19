import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/portfolio_item.dart';
import 'profile_storage.dart';

class PortfolioStorage {
  PortfolioStorage._();

  static const String keyItemsJson = 'portfolio_items_json_v1';

  static Future<List<PortfolioItem>> loadRaw() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(keyItemsJson);
    if (raw == null || raw.trim().isEmpty) {
      return <PortfolioItem>[];
    }
    try {
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((dynamic e) =>
              PortfolioItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .where((PortfolioItem i) => i.id.isNotEmpty)
          .toList();
    } catch (_) {
      return <PortfolioItem>[];
    }
  }

  static Future<List<PortfolioItem>> loadValidSortedNewestFirst() async {
    final Directory doc = await ProfileStorage.documentsDirectory();
    final List<PortfolioItem> raw = await loadRaw();
    final List<PortfolioItem> kept = <PortfolioItem>[];
    bool removedAny = false;
    for (final PortfolioItem item in raw) {
      final String rel = item.imageRelativePath.trim();
      if (rel.isEmpty) {
        removedAny = true;
        continue;
      }
      final File f = File(p.join(doc.path, rel));
      if (f.existsSync()) {
        kept.add(item);
      } else {
        removedAny = true;
      }
    }
    kept.sort((PortfolioItem a, PortfolioItem b) =>
        b.capturedAt.compareTo(a.capturedAt));
    if (removedAny) {
      await save(kept);
    }
    return kept;
  }

  static Future<void> save(List<PortfolioItem> items) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String encoded =
        jsonEncode(items.map((PortfolioItem e) => e.toJson()).toList());
    await prefs.setString(keyItemsJson, encoded);
  }

  static Future<String> copyPickedImageToPortfolio(File pickedFile) async {
    final Directory doc = await ProfileStorage.documentsDirectory();
    final String stamp = DateTime.now().millisecondsSinceEpoch.toString();
    final String relative = 'portfolio/gallery_$stamp.jpg';
    final File dest = File(p.join(doc.path, relative));
    await dest.parent.create(recursive: true);
    await pickedFile.copy(dest.path);
    return relative;
  }

  static Future<void> deleteImageIfExists(String? relativePath) async {
    final String rel = relativePath?.trim() ?? '';
    if (rel.isEmpty) return;
    final File f = await ProfileStorage.fileFromRelative(rel);
    if (f.existsSync()) {
      await f.delete();
    }
  }

  static Future<void> upsert(PortfolioItem item) async {
    final List<PortfolioItem> items = await loadRaw();
    final int idx = items.indexWhere((PortfolioItem e) => e.id == item.id);
    if (idx >= 0) {
      items[idx] = item;
    } else {
      items.insert(0, item);
    }
    await save(items);
  }

  static Future<void> deleteById(String id) async {
    final List<PortfolioItem> items = await loadRaw();
    items.removeWhere((PortfolioItem e) => e.id == id);
    await save(items);
  }
}
