import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LensAiChatTurn {
  const LensAiChatTurn({
    required this.isUser,
    required this.text,
    required this.atMillis,
  });

  final bool isUser;
  final String text;
  final int atMillis;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'isUser': isUser,
        'text': text,
        'atMillis': atMillis,
      };

  factory LensAiChatTurn.fromJson(Map<String, dynamic> json) {
    return LensAiChatTurn(
      isUser: json['isUser'] as bool? ?? false,
      text: json['text'] as String? ?? '',
      atMillis: json['atMillis'] as int? ?? 0,
    );
  }
}

class LensAiChatStorage {
  LensAiChatStorage._();

  static const String _prefsKey = 'lens_ai_chat_turns_v1';

  static const String kDefaultWelcome =
      '你好！我是 AI 摄影助手，可以和你一起聊曝光、镜头、构图与后期。用文字描述你的场景或器材，我会用中文回复。';

  static Future<List<LensAiChatTurn>> loadTurns() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_prefsKey);
    if (raw == null || raw.trim().isEmpty) {
      return <LensAiChatTurn>[];
    }
    try {
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((dynamic e) =>
              LensAiChatTurn.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return <LensAiChatTurn>[];
    }
  }

  static Future<void> saveTurns(List<LensAiChatTurn> turns) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode(turns.map((LensAiChatTurn e) => e.toJson()).toList()),
    );
  }

  static Future<({String preview, int lastAtMillis})?> inboxSummary() async {
    final List<LensAiChatTurn> turns = await loadTurns();
    if (turns.isEmpty) {
      return null;
    }
    final LensAiChatTurn last = turns.last;
    String preview = last.text.replaceAll('\n', ' ').trim();
    if (preview.length > 44) {
      preview = '${preview.substring(0, 44)}…';
    }
    return (preview: preview, lastAtMillis: last.atMillis);
  }
}
