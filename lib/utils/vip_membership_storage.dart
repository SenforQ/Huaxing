import 'package:shared_preferences/shared_preferences.dart';

class VipMembershipStorage {
  VipMembershipStorage._();

  static const String _vipActiveKey = 'vip_membership_active_v1';

  static Future<bool> isVip() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_vipActiveKey) ?? false;
  }

  static Future<void> setVipActive(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_vipActiveKey, value);
  }
}
