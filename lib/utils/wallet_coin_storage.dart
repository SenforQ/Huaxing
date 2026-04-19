import 'package:shared_preferences/shared_preferences.dart';

class WalletCoinStorage {
  WalletCoinStorage._();

  static const String _balanceKey = 'wallet_coin_balance_v1';
  static const String _processedPurchaseIdsKey =
      'wallet_processed_purchase_ids_v1';

  static Future<int> loadBalance() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_balanceKey) ?? 0;
  }

  static Future<void> addCoinsIfNewPurchase({
    required String dedupePurchaseKey,
    required int coins,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> processed =
        prefs.getStringList(_processedPurchaseIdsKey) ?? <String>[];
    if (processed.contains(dedupePurchaseKey)) {
      return;
    }
    final int current = prefs.getInt(_balanceKey) ?? 0;
    await prefs.setInt(_balanceKey, current + coins);
    processed.add(dedupePurchaseKey);
    await prefs.setStringList(_processedPurchaseIdsKey, processed);
  }

  static Future<bool> trySpend(int amount) async {
    if (amount <= 0) return true;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int current = prefs.getInt(_balanceKey) ?? 0;
    if (current < amount) return false;
    await prefs.setInt(_balanceKey, current - amount);
    return true;
  }

  static Future<void> creditCoins(int amount) async {
    if (amount <= 0) return;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int current = prefs.getInt(_balanceKey) ?? 0;
    await prefs.setInt(_balanceKey, current + amount);
  }
}
