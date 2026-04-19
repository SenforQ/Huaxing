import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// 本地单向会话：仅存用户发送的内容；「等待对方回复」标记用于限制连续发送。
class ChatPeerStorage {
  ChatPeerStorage._();

  static String _peerKey(String peerUserName) =>
      Uri.encodeComponent(peerUserName.trim());

  static String _messagesKey(String peer) => 'chat_dm_msgs_${_peerKey(peer)}';

  static String _awaitKey(String peer) => 'chat_dm_await_${_peerKey(peer)}';

  static Future<bool> awaitingTheirReply(String peerUserName) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_awaitKey(peerUserName)) ?? false;
  }

  static Future<void> _setAwaiting(String peerUserName, bool v) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_awaitKey(peerUserName), v);
  }

  static Future<List<ChatDmEntry>> loadMessages(String peerUserName) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_messagesKey(peerUserName));
    if (raw == null || raw.trim().isEmpty) {
      return <ChatDmEntry>[];
    }
    try {
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((dynamic e) =>
              ChatDmEntry.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return <ChatDmEntry>[];
    }
  }

  static Future<void> _saveMessages(
      String peerUserName, List<ChatDmEntry> list) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _messagesKey(peerUserName),
      jsonEncode(list.map((ChatDmEntry e) => e.toJson()).toList()),
    );
  }

  /// 用于消息列表：所有已有本地私信记录的创作者（按最后一条时间倒序）。
  static Future<List<ChatPeerInboxSummary>> loadPeerInboxSummaries() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    const String prefix = 'chat_dm_msgs_';
    final List<ChatPeerInboxSummary> out = <ChatPeerInboxSummary>[];
    for (final String key in prefs.getKeys()) {
      if (!key.startsWith(prefix)) {
        continue;
      }
      final String encoded = key.substring(prefix.length);
      final String userName = Uri.decodeComponent(encoded);
      final List<ChatDmEntry> msgs = await loadMessages(userName);
      if (msgs.isEmpty) {
        continue;
      }
      final ChatDmEntry last = msgs.last;
      String preview = last.text.replaceAll('\n', ' ').trim();
      if (preview.length > 40) {
        preview = '${preview.substring(0, 40)}…';
      }
      out.add(
        ChatPeerInboxSummary(
          userName: userName,
          lastPreview: preview,
          lastAtMillis: last.sentAtMillis,
        ),
      );
    }
    out.sort(
      (ChatPeerInboxSummary a, ChatPeerInboxSummary b) =>
          b.lastAtMillis.compareTo(a.lastAtMillis),
    );
    return out;
  }

  /// 追加一条用户发出的消息，并标记「等待对方回复」。
  static Future<void> appendOutgoing(
      String peerUserName, String text) async {
    final String t = text.trim();
    if (t.isEmpty) return;
    final List<ChatDmEntry> list = await loadMessages(peerUserName);
    list.add(ChatDmEntry(
      text: t,
      sentAtMillis: DateTime.now().millisecondsSinceEpoch,
    ));
    await _saveMessages(peerUserName, list);
    await _setAwaiting(peerUserName, true);
  }

}

class ChatPeerInboxSummary {
  const ChatPeerInboxSummary({
    required this.userName,
    required this.lastPreview,
    required this.lastAtMillis,
  });

  final String userName;
  final String lastPreview;
  final int lastAtMillis;
}

class ChatDmEntry {
  const ChatDmEntry({
    required this.text,
    required this.sentAtMillis,
  });

  final String text;
  final int sentAtMillis;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'text': text,
        'sentAtMillis': sentAtMillis,
      };

  factory ChatDmEntry.fromJson(Map<String, dynamic> json) {
    return ChatDmEntry(
      text: json['text'] as String? ?? '',
      sentAtMillis: json['sentAtMillis'] as int? ?? 0,
    );
  }
}
