import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class FollowStorage {
  FollowStorage._();

  static const String keyFollowing = 'author_follow_user_names_v1';

  static Future<Set<String>> followedNames() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(keyFollowing);
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

  static Future<bool> isFollowing(String userName) async {
    final Set<String> s = await followedNames();
    return s.contains(userName.trim());
  }

  static Future<void> saveFollowing(Set<String> names) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyFollowing, jsonEncode(names.toList()));
  }

  static Future<void> setFollowing(String userName, bool following) async {
    final String n = userName.trim();
    if (n.isEmpty) return;
    final Set<String> set = await followedNames();
    if (following) {
      set.add(n);
    } else {
      set.remove(n);
    }
    await saveFollowing(set);
  }

  static Future<void> toggle(String userName) async {
    final bool cur = await isFollowing(userName);
    await setFollowing(userName, !cur);
  }
}
