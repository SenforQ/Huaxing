import 'package:shared_preferences/shared_preferences.dart';

class CommentUserAgreementStorage {
  CommentUserAgreementStorage._();

  static const String keyAccepted = 'comment_user_agreement_accepted_v1';

  static Future<bool> hasAccepted() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keyAccepted) ?? false;
  }

  static Future<void> setAccepted(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyAccepted, value);
  }
}
