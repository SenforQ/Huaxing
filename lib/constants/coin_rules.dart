class CoinRules {
  CoinRules._();

  /// 单次 AI 咨询（非 VIP）：花杏币
  static const int consultationCoinsStandard = 30;

  /// 单次 AI 咨询（VIP 8 折）：花杏币
  static const int consultationCoinsVip = 24;

  /// 兼容旧命名：等同于非 VIP 单次消耗
  static const int consultationCoinsPerSession = consultationCoinsStandard;

  static int consultationCoinsForVipFlag(bool isVip) {
    return isVip ? consultationCoinsVip : consultationCoinsStandard;
  }
}
