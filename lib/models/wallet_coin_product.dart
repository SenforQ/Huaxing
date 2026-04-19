class WalletCoinProduct {
  const WalletCoinProduct({
    required this.productId,
    required this.coins,
    required this.price,
    required this.priceText,
  });

  final String productId;
  final int coins;
  final double price;
  final String priceText;

  static const List<WalletCoinProduct> products = <WalletCoinProduct>[
    WalletCoinProduct(
      productId: 'iOS_HX_29_9',
      coins: 900,
      price: 1.99,
      priceText: r'29.99元',
    ),
    WalletCoinProduct(
      productId: 'iOS_HX_49_9',
      coins: 1869,
      price: 2.99,
      priceText: r'49.9元',
    ),
    WalletCoinProduct(
      productId: 'iOS_HX_99_9',
      coins: 3799,
      price: 5.99,
      priceText: r'99.9元',
    )
  ];

  static WalletCoinProduct? byProductId(String id) {
    for (final WalletCoinProduct p in products) {
      if (p.productId == id) return p;
    }
    return null;
  }
}
