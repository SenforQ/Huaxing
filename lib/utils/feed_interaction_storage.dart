import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/feed_comment.dart';

class FeedInteractionStorage {
  FeedInteractionStorage._();

  static const String keyLikedPostIds = 'feed_liked_post_ids_v1';
  static const String keyCommentsJson = 'feed_comments_json_v1';

  static const String _builtinCommentPost101Id = 'builtin-lens-101-1';

  static List<FeedComment> _builtinCommentsForPost(String postId) {
    if (postId == '101') {
      return <FeedComment>[
        FeedComment(
          id: _builtinCommentPost101Id,
          authorName: '江澄',
          text: '拍摄很不错！',
          createdAtMillis: 1713456000000,
        ),
      ];
    }
    return <FeedComment>[];
  }

  static Map<String, List<FeedComment>> _mergeBuiltinComments(
    Map<String, List<FeedComment>> stored,
  ) {
    final Map<String, List<FeedComment>> out =
        <String, List<FeedComment>>{};
    stored.forEach((String k, List<FeedComment> v) {
      out[k] = List<FeedComment>.from(v);
    });
    final List<String> postIds = <String>{
      ...out.keys,
      '101',
    }.toList();
    for (final String postId in postIds) {
      final List<FeedComment> builtin = _builtinCommentsForPost(postId);
      if (builtin.isEmpty) {
        continue;
      }
      final List<FeedComment> merged =
          List<FeedComment>.from(out[postId] ?? <FeedComment>[]);
      final Set<String> ids = merged.map((FeedComment c) => c.id).toSet();
      for (final FeedComment c in builtin) {
        if (!ids.contains(c.id)) {
          merged.insert(0, c);
          ids.add(c.id);
        }
      }
      out[postId] = merged;
    }
    return out;
  }

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
      return _mergeBuiltinComments(<String, List<FeedComment>>{});
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
      return _mergeBuiltinComments(out);
    } catch (_) {
      return _mergeBuiltinComments(<String, List<FeedComment>>{});
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
