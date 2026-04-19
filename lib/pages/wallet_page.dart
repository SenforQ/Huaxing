import 'dart:async';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../constants/coin_rules.dart';
import '../models/wallet_coin_product.dart';
import '../theme/huaxing_theme.dart';
import '../utils/wallet_coin_storage.dart';
import '../widgets/glass_ui.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  final InAppPurchase _iap = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _purchaseSub;

  bool _queryDone = false;
  final Map<String, ProductDetails> _productDetailsById =
      <String, ProductDetails>{};

  int _balance = 0;
  bool _purchasePending = false;
  String? _busyProductId;

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
    final int bal = await WalletCoinStorage.loadBalance();
    if (!mounted) return;
    setState(() => _balance = bal);

    final bool available = await _iap.isAvailable();
    if (!mounted) return;
    if (!available) {
      setState(() => _queryDone = true);
      return;
    }

    final Set<String> ids = WalletCoinProduct.products
        .map((WalletCoinProduct e) => e.productId)
        .toSet();
    try {
      final ProductDetailsResponse response =
          await _iap.queryProductDetails(ids);
      if (!mounted) return;
      final Map<String, ProductDetails> map = <String, ProductDetails>{};
      for (final ProductDetails d in response.productDetails) {
        map[d.id] = d;
      }
      setState(() {
        _productDetailsById
          ..clear()
          ..addAll(map);
        _queryDone = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _queryDone = true);
    }
  }

  Future<void> _refreshBalance() async {
    final int b = await WalletCoinStorage.loadBalance();
    if (!mounted) return;
    setState(() => _balance = b);
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final PurchaseDetails purchase in purchases) {
      await _handlePurchase(purchase);
    }
  }

  String _dedupeKey(PurchaseDetails d) {
    final String? pid = d.purchaseID;
    if (pid != null && pid.isNotEmpty) {
      return '${d.productID}:$pid';
    }
    final String server = d.verificationData.serverVerificationData;
    if (server.isNotEmpty) {
      return '${d.productID}:srv:${server.hashCode}';
    }
    final String local = d.verificationData.localVerificationData;
    if (local.isNotEmpty) {
      return '${d.productID}:loc:${local.hashCode}';
    }
    return '${d.productID}:fallback:${DateTime.now().microsecondsSinceEpoch}';
  }

  Future<void> _handlePurchase(PurchaseDetails purchase) async {
    if (purchase.status == PurchaseStatus.pending) {
      if (!mounted) return;
      setState(() => _purchasePending = true);
      return;
    }

    if (purchase.status == PurchaseStatus.error) {
      if (!mounted) return;
      setState(() {
        _purchasePending = false;
        _busyProductId = null;
      });
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
      final WalletCoinProduct? meta =
          WalletCoinProduct.byProductId(purchase.productID);
      if (meta != null) {
        final String key = _dedupeKey(purchase);
        await WalletCoinStorage.addCoinsIfNewPurchase(
          dedupePurchaseKey: key,
          coins: meta.coins,
        );
        await _refreshBalance();
        if (!mounted) return;
        setState(() {
          _purchasePending = false;
          _busyProductId = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已成功充值 ${meta.coins} 花杏币'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.white.withOpacity(0.14),
          ),
        );
      } else {
        if (!mounted) return;
        setState(() {
          _purchasePending = false;
          _busyProductId = null;
        });
      }
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
      return;
    }

    if (!mounted) return;
    setState(() {
      _purchasePending = false;
      _busyProductId = null;
    });
    if (purchase.pendingCompletePurchase) {
      await _iap.completePurchase(purchase);
    }
  }

  Future<void> _buy(WalletCoinProduct product) async {
    final ProductDetails? details = _productDetailsById[product.productId];
    if (details == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('商店未返回该商品，无法发起支付（请检查后台商品 ID）'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.white.withOpacity(0.14),
        ),
      );
      return;
    }
    if (_purchasePending) return;

    setState(() {
      _busyProductId = product.productId;
      _purchasePending = true;
    });

    try {
      final PurchaseParam param = PurchaseParam(productDetails: details);
      final bool started =
          await _iap.buyConsumable(purchaseParam: param);
      if (!started && mounted) {
        setState(() {
          _purchasePending = false;
          _busyProductId = null;
        });
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
      setState(() {
        _purchasePending = false;
        _busyProductId = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('发起购买失败：$e'),
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

  void _showCoinRulesDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1C1C1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.info_outline_rounded, color: kAccentYellow.withOpacity(0.95)),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  '花杏币说明',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            '· AI 咨询：普通用户每次 ${CoinRules.consultationCoinsStandard} 花杏币；VIP 会员 8 折，每次 ${CoinRules.consultationCoinsVip} 花杏币。\n\n'
            '· 查看他人拍摄的图片时，将按该作品或页面提示扣除对应数量的花杏币。',
            style: TextStyle(
              color: Colors.white.withOpacity(0.88),
              fontSize: 15,
              height: 1.55,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                '知道了',
                style: TextStyle(
                  color: kAccentYellow,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundBlack,
      appBar: AppBar(
        title: const Text('钱包 · 花杏币'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            tooltip: '花杏币说明',
            icon: const Icon(Icons.help_outline_rounded, color: Colors.white),
            onPressed: () => _showCoinRulesDialog(context),
          ),
        ],
      ),
      body: GradientShellBackground(
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: GlassPanel(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 22,
                    ),
                    borderRadius: 22,
                    blurSigma: 22,
                    child: Row(
                      children: [
                        Icon(
                          Icons.monetization_on_rounded,
                          color: kAccentYellow.withOpacity(0.95),
                          size: 36,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '当前余额',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.55),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '$_balance',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '花杏币',
                          style: TextStyle(
                            color: kAccentYellow.withOpacity(0.88),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (!_queryDone)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: 48),
                    child: Center(
                      child: CircularProgressIndicator(color: kAccentYellow),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(
                      WalletCoinProduct.products
                          .map(
                            (WalletCoinProduct product) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _WalletProductCard(
                                product: product,
                                storeDetails:
                                    _productDetailsById[product.productId],
                                busy: _busyProductId == product.productId,
                                onBuy: () => _buy(product),
                              ),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WalletProductCard extends StatelessWidget {
  const _WalletProductCard({
    required this.product,
    required this.storeDetails,
    required this.busy,
    required this.onBuy,
  });

  final WalletCoinProduct product;
  final ProductDetails? storeDetails;
  final bool busy;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final String displayPrice =
        storeDetails?.price ?? product.priceText;

    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      borderRadius: 18,
      blurSigma: 18,
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                colors: [
                  kAccentYellow.withOpacity(0.35),
                  kAccentYellow.withOpacity(0.08),
                ],
              ),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.stars_rounded,
              color: kAccentYellow.withOpacity(0.95),
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${product.coins} 花杏币',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  displayPrice,
                  style: TextStyle(
                    color: kAccentYellow.withOpacity(0.92),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: busy ? null : onBuy,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              minimumSize: const Size(108, 44),
            ),
            child: busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black87,
                    ),
                  )
                : const Text(
                    'Buy',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
