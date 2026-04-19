import 'dart:convert';
import 'dart:io';

import '../config/zhipu_api_config.dart';

class ZhipuChatService {
  ZhipuChatService();

  static const String _systemPrompt =
      '你是「花杏摄影」的专业摄影指导老师。请针对用户问题，从曝光、构图、镜头选择、光线运用与后期思路等方面给出实用建议。'
      '回答力求简洁清晰、可操作。无论用户用什么语言提问，请务必使用简体中文回复。';

  Future<String> completeChat({
    required List<Map<String, String>> messages,
  }) async {
    final List<Map<String, dynamic>> payloadMessages = <Map<String, dynamic>>[
      <String, dynamic>{
        'role': 'system',
        'content': _systemPrompt,
      },
      ...messages.map(
        (Map<String, String> m) => <String, dynamic>{
          'role': m['role'],
          'content': m['content'],
        },
      ),
    ];

    final HttpClient client = HttpClient();
    try {
      final Uri uri = Uri.parse(ZhipuApiConfig.chatCompletionsUrl);
      final HttpClientRequest request = await client.postUrl(uri);
      request.headers.set(
        HttpHeaders.contentTypeHeader,
        'application/json; charset=utf-8',
      );
      request.headers.set(
        HttpHeaders.authorizationHeader,
        'Bearer ${ZhipuApiConfig.apiKey}',
      );
      request.write(
        jsonEncode(<String, dynamic>{
          'model': ZhipuApiConfig.modelId,
          'messages': payloadMessages,
          'temperature': 0.65,
          'max_tokens': 2048,
        }),
      );
      final HttpClientResponse response = await request.close();
      final String body = await response.transform(utf8.decoder).join();

      final dynamic decoded = jsonDecode(body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final String err = _extractError(decoded);
        throw Exception(err.isEmpty ? '请求失败 (${response.statusCode})' : err);
      }

      final dynamic choices = decoded is Map<String, dynamic>
          ? decoded['choices']
          : null;
      if (choices is! List<dynamic> || choices.isEmpty) {
        throw Exception('模型未返回有效内容');
      }
      final dynamic first = choices.first;
      if (first is! Map<String, dynamic>) {
        throw Exception('模型响应格式异常');
      }
      final dynamic msg = first['message'];
      if (msg is! Map<String, dynamic>) {
        throw Exception('模型响应缺少 message');
      }
      final dynamic content = msg['content'];
      if (content is! String || content.trim().isEmpty) {
        throw Exception('模型返回空文本');
      }
      return content.trim();
    } finally {
      client.close(force: true);
    }
  }

  String _extractError(dynamic decoded) {
    if (decoded is Map<String, dynamic>) {
      final dynamic err = decoded['error'];
      if (err is Map<String, dynamic>) {
        final dynamic m = err['message'];
        if (m is String && m.isNotEmpty) return m;
      }
      final dynamic msg = decoded['message'];
      if (msg is String && msg.isNotEmpty) return msg;
    }
    return '';
  }
}
