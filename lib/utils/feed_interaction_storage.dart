import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/feed_comment.dart';

class FeedInteractionStorage {
  FeedInteractionStorage._();

  static const String keyLikedPostIds = 'feed_liked_post_ids_v1';
  static const String keyCommentsJson = 'feed_comments_json_v1';

  static Future<Set<String>> loadLikedPostIds() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(keyLikedPostIds);
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

  static Future<void> saveLikedPostIds(Set<String> ids) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyLikedPostIds, jsonEncode(ids.toList()));
  }

  static Future<void> toggleLikePost(String postId) async {
    final Set<String> ids = await loadLikedPostIds();
    if (ids.contains(postId)) {
      ids.remove(postId);
    } else {
      ids.add(postId);
    }
    await saveLikedPostIds(ids);
  }

  static Future<Map<String, List<FeedComment>>> loadCommentsMap() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(keyCommentsJson);
    if (raw == null || raw.trim().isEmpty) {
      return <String, List<FeedComment>>{};
    }
    try {
      final Map<String, dynamic> decoded =
          jsonDecode(raw) as Map<String, dynamic>;
      final Map<String, List<FeedComment>> out =
          <String, List<FeedComment>>{};
      decoded.forEach((String k, dynamic v) {
        if (v is List<dynamic>) {
          out[k] = v
              .map((dynamic e) =>
                  FeedComment.fromJson(Map<String, dynamic>.from(e as Map)))
              .where((FeedComment c) => c.id.isNotEmpty && c.text.isNotEmpty)
              .toList();
        }
      });
      return out;
    } catch (_) {
      return <String, List<FeedComment>>{};
    }
  }

  static Future<void> saveCommentsMap(
      Map<String, List<FeedComment>> map) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> encoded = <String, dynamic>{};
    map.forEach((String k, List<FeedComment> v) {
      encoded[k] = v.map((FeedComment c) => c.toJson()).toList();
    });
    await prefs.setString(keyCommentsJson, jsonEncode(encoded));
  }

  static Future<List<FeedComment>> commentsForPost(String postId) async {
    final Map<String, List<FeedComment>> map = await loadCommentsMap();
    return List<FeedComment>.from(map[postId] ?? <FeedComment>[]);
  }

  static Future<void> appendComment(String postId, FeedComment comment) async {
    final Map<String, List<FeedComment>> map = await loadCommentsMap();
    final List<FeedComment> list =
        List<FeedComment>.from(map[postId] ?? <FeedComment>[]);
    list.add(comment);
    map[postId] = list;
    await saveCommentsMap(map);
  }
}
