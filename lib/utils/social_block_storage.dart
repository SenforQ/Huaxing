import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SocialBlockStorage {
  SocialBlockStorage._();

  static const String keyBlockedUsers = 'social_blocked_user_names_v1';
  static const String keyHiddenPosts = 'social_hidden_post_ids_v1';

  static Future<Set<String>> loadBlockedUsers() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(keyBlockedUsers);
    if (raw == null || raw.trim().isEmpty) {
      return <String>{};
    }
    try {
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      return list.map((dynamic e) => e.toString().trim()).where((String s) => s.isNotEmpty).toSet();
    } catch (_) {
      return <String>{};
    }
  }

  static Future<Set<String>> loadHiddenPostIds() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(keyHiddenPosts);
    if (raw == null || raw.trim().isEmpty) {
      return <String>{};
    }
    try {
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      return list.map((dynamic e) => e.toString().trim()).where((String s) => s.isNotEmpty).toSet();
    } catch (_) {
      return <String>{};
    }
  }

  static Future<void> saveBlockedUsers(Set<String> names) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyBlockedUsers, jsonEncode(names.toList()));
  }

  static Future<void> saveHiddenPostIds(Set<String> ids) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyHiddenPosts, jsonEncode(ids.toList()));
  }

  static Future<void> addBlockedUser(String userName) async {
    final String n = userName.trim();
    if (n.isEmpty) return;
    final Set<String> set = await loadBlockedUsers();
    set.add(n);
    await saveBlockedUsers(set);
  }

  static Future<void> addHiddenPost(String postId) async {
    final String id = postId.trim();
    if (id.isEmpty) return;
    final Set<String> set = await loadHiddenPostIds();
    set.add(id);
    await saveHiddenPostIds(set);
  }
}
