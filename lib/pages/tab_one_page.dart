import 'package:flutter/material.dart';

import 'feed_tab.dart';

/// 首页摄影流 Tab：承载 [FeedTab]。
/// 拉黑/屏蔽后由 [FeedMuteScope] 触发依赖重建，[FeedTab] 内会重新过滤数据。
class TabOnePage extends StatelessWidget {
  const TabOnePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeedTab();
  }
}
