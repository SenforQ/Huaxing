import 'dart:async';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../constants/coin_rules.dart';
import '../models/vip_iap_product.dart';
import '../theme/huaxing_theme.dart';
import '../utils/vip_membership_storage.dart';
import '../widgets/glass_ui.dart';

class VipPage extends StatefulWidget {
  const VipPage({super.key});

  @override
  State<VipPage> createState() => _VipPageState();
}

class _VipPageState extends State<VipPage> {
  final InAppPurchase _iap = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _purchaseSub;

  bool _queryDone = false;
  ProductDetails? _vipProductDetails;

  bool _isVip = false;
  bool _purchasePending = false;

  @override
  void initState() {
    super.initState();
    _purchaseSub = _iap.purchaseStream.listen(
      _onPurchases,
      onDone: () {},
      onError: (Object error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('购买流异常：$error'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.white.withOpacity(0.14),
          ),
        );
      },
    );
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final bool vip = await VipMembershipStorage.isVip();
    if (!mounted) return;
    setState(() => _isVip = vip);

    final bool available = await _iap.isAvailable();
    if (!mounted) return;
    if (!available) {
      setState(() => _queryDone = true);
      return;
    }

    try {
      final ProductDetailsResponse response = await _iap.queryProductDetails(
        <String>{VipIapProduct.productId},
      );
      if (!mounted) return;
      ProductDetails? found;
      for (final ProductDetails d in response.productDetails) {
        if (d.id == VipIapProduct.productId) {
          found = d;
          break;
        }
      }
      setState(() {
        _vipProductDetails = found;
        _queryDone = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _queryDone = true);
    }
  }

  Future<void> _refreshVipFlag() async {
    final bool vip = await VipMembershipStorage.isVip();
    if (!mounted) return;
    setState(() => _isVip = vip);
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final PurchaseDetails purchase in purchases) {
      await _handlePurchase(purchase);
    }
  }

  Future<void> _handlePurchase(PurchaseDetails purchase) async {
    if (purchase.productID != VipIapProduct.productId) {
      return;
    }

    if (purchase.status == PurchaseStatus.pending) {
      if (!mounted) return;
      setState(() => _purchasePending = true);
      return;
    }

    if (purchase.status == PurchaseStatus.error) {
      if (!mounted) return;
      setState(() => _purchasePending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(purchase.error?.message ?? '购买失败'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.white.withOpacity(0.14),
        ),
      );
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
      return;
    }

    if (purchase.status == PurchaseStatus.purchased ||
        purchase.status == PurchaseStatus.restored) {
      await VipMembershipStorage.setVipActive(true);
      await _refreshVipFlag();
      if (!mounted) return;
      setState(() => _purchasePending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            purchase.status == PurchaseStatus.restored
                ? '已恢复 VIP 权益'
                : 'VIP 开通成功，AI 咨询享 8 折优惠（${CoinRules.consultationCoinsVip} 花杏币/次）',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.white.withOpacity(0.14),
        ),
      );
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
      return;
    }

    if (!mounted) return;
    setState(() => _purchasePending = false);
    if (purchase.pendingCompletePurchase) {
      await _iap.completePurchase(purchase);
    }
  }

  Future<void> _startPurchase() async {
    if (_isVip || _purchasePending) return;

    final ProductDetails? details = _vipProductDetails;
    if (details == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('商店未返回 VIP 商品，无法发起支付（请检查 App Store 商品 ID）'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.white.withOpacity(0.14),
        ),
      );
      return;
    }

    setState(() => _purchasePending = true);
    try {
      final PurchaseParam param = PurchaseParam(productDetails: details);
      final bool started = await _iap.buyNonConsumable(purchaseParam: param);
      if (!started && mounted) {
        setState(() => _purchasePending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('无法发起购买'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.white.withOpacity(0.14),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _purchasePending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('发起购买失败：$e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.white.withOpacity(0.14),
        ),
      );
    }
  }

  Future<void> _restorePurchases() async {
    try {
      await _iap.restorePurchases();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('已向商店查询购买记录'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.white.withOpacity(0.14),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('恢复失败：$e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.white.withOpacity(0.14),
        ),
      );
    }
  }

  @override
  void dispose() {
    _purchaseSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String priceLine =
        _vipProductDetails?.price ?? VipIapProduct.priceDisplayCny;

    return Scaffold(
      backgroundColor: kBackgroundBlack,
      appBar: AppBar(
        title: const Text('开通 VIP'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: GradientShellBackground(
        child: SafeArea(
          child: !_queryDone
              ? const Center(
                  child: CircularProgressIndicator(color: kAccentYellow),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      GlassPanel(
                        padding: const EdgeInsets.all(22),
                        borderRadius: 22,
                        blurSigma: 22,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.workspace_premium_rounded,
                                  color: kAccentYellow.withOpacity(0.95),
                                  size: 32,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _isVip ? '您已是 VIP 会员' : 'VIP 专属权益',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Text(
                              '· AI 咨询享 8 折优惠：单次原价 ${CoinRules.consultationCoinsStandard} 花杏币，开通 VIP 后仅需 ${CoinRules.consultationCoinsVip} 花杏币。',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.88),
                                fontSize: 15,
                                height: 1.55,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              '· 查看他人拍摄的作品时，仍按页面提示扣除对应花杏币（不受 VIP 文本折扣影响时以页面为准）。',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.62),
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      GlassPanel(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 20,
                        ),
                        borderRadius: 18,
                        blurSigma: 18,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'VIP 会员',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.55),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  priceLine,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    '（参考 ${VipIapProduct.priceDisplayCny}）',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.45),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      FilledButton(
                        onPressed: _isVip
                            ? null
                            : (_purchasePending ? null : _startPurchase),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          minimumSize: const Size(double.infinity, 52),
                        ),
                        child: _purchasePending
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black87,
                                ),
                              )
                            : Text(
                                _isVip ? '已开通' : '立即开通',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton(
                          onPressed: _restorePurchases,
                          child: Text(
                            '恢复购买',
                            style: TextStyle(
                              color: kAccentYellow.withOpacity(0.9),
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
