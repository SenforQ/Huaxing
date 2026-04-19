import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../data/lens_feed.dart';
import '../models/lens_post.dart';
import '../pages/report_page.dart';
import '../state/feed_mute_controller.dart';

/// Feed 卡片 ⋮ 与详情页右上角：**举报**、**拉黑**、**屏蔽此动态**。  
/// 摄影师主页 ⋮：**举报**、**拉黑**、**屏蔽其作品**（隐藏该用户全部动态）。
class FeedPostMoreFlow {
  FeedPostMoreFlow._();

  /// 跳转举报页。
  static void startReport(BuildContext context, LensPost post) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => ReportPage(
          postId: post.id,
          userName: post.userName,
          previewCaption: post.caption,
        ),
      ),
    );
  }

  /// 拉黑作者并回到根视图（主页 Tab）。
  static Future<void> blockAndReturnToRoot(
      BuildContext context, LensPost post) async {
    final FeedMuteController mute = FeedMuteScope.of(context);
    await mute.blockUser(post.userName);
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true)
        .popUntil((Route<dynamic> r) => r.isFirst);
  }

  /// 屏蔽本条动态并回到根视图。
  static Future<void> hideAndReturnToRoot(
      BuildContext context, LensPost post) async {
    final FeedMuteController mute = FeedMuteScope.of(context);
    await mute.hidePost(post.id);
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true)
        .popUntil((Route<dynamic> r) => r.isFirst);
  }

  /// 屏蔽该用户在数据源中的全部作品（每条动态单独加入隐藏列表）并回到根视图。
  static Future<void> hideAuthorWorksAndReturnToRoot(
      BuildContext context, LensPost seedPost) async {
    final FeedMuteController mute = FeedMuteScope.of(context);
    for (final LensPost x in lensFeedPosts) {
      if (x.userName == seedPost.userName) {
        await mute.hidePost(x.id);
      }
    }
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true)
        .popUntil((Route<dynamic> r) => r.isFirst);
  }

  /// 右下角 ⋮：弹出 iOS ActionSheet，选项与详情栏一致。
  static Future<void> open(BuildContext context, LensPost post) async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext ctx) => CupertinoActionSheet(
        title: Text('「${post.userName}」的作品'),
        message: const Text('请选择操作'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              startReport(context, post);
            },
            child: const Text('举报'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.of(ctx).pop();
              await blockAndReturnToRoot(context, post);
            },
            child: Text('拉黑「${post.userName}」'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.of(ctx).pop();
              await hideAndReturnToRoot(context, post);
            },
            child: const Text('屏蔽此动态'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('取消'),
        ),
      ),
    );
  }

  /// 摄影师主页右上角 ⋮：**举报**、**拉黑**、**屏蔽其作品**。
  static Future<void> openAuthorProfile(
      BuildContext context, LensPost seedPost) async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext ctx) => CupertinoActionSheet(
        title: Text('「${seedPost.userName}」'),
        message: const Text('请选择操作'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              startReport(context, seedPost);
            },
            child: const Text('举报'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.of(ctx).pop();
              await blockAndReturnToRoot(context, seedPost);
            },
            child: Text('拉黑「${seedPost.userName}」'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.of(ctx).pop();
              await hideAuthorWorksAndReturnToRoot(context, seedPost);
            },
            child: const Text('屏蔽'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('取消'),
        ),
      ),
    );
  }
}
