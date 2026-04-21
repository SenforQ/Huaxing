import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../data/lens_feed.dart';
import '../models/feed_comment.dart';
import '../models/lens_post.dart';
import '../pages/report_page.dart';
import '../state/feed_mute_controller.dart';

/// Feed 卡片 ⋮ 与详情页右上角：**举报**、**拉黑**、**屏蔽此动态**。  
/// 摄影师主页 ⋮：**举报**、**拉黑**、**屏蔽其作品**（隐藏该用户全部动态）。
class FeedPostMoreFlow {
  FeedPostMoreFlow._();

  /// 跳转举报页（被举报对象为动态作者）。
  static void startReport(BuildContext context, LensPost post) {
    startReportWithTarget(
      context,
      postId: post.id,
      userName: post.userName,
      previewCaption: post.caption,
    );
  }

  /// 跳转举报页（可指定被举报用户，例如评论者）。
  static void startReportWithTarget(
    BuildContext context, {
    required String postId,
    required String userName,
    String? previewCaption,
  }) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => ReportPage(
          postId: postId,
          userName: userName,
          previewCaption: previewCaption,
        ),
      ),
    );
  }

  /// 拉黑作者并回到根视图（主页 Tab）。
  static Future<void> blockAndReturnToRoot(
      BuildContext context, LensPost post) async {
    await blockUserByNameAndReturnToRoot(context, post.userName);
  }

  /// 按用户名拉黑并回到根视图。
  static Future<void> blockUserByNameAndReturnToRoot(
      BuildContext context, String userName) async {
    final FeedMuteController mute = FeedMuteScope.of(context);
    await mute.blockUser(userName.trim());
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

  /// 评论列表中「其他用户」标记：拉黑、屏蔽此动态、举报。  
  /// [onCommentsDataRefresh]：拉黑或屏蔽后用于重新拉取评论区数据并刷新 Feed 评论数。
  static Future<void> openCommentAuthorActions(
    BuildContext context,
    LensPost post,
    FeedComment comment, {
    VoidCallback? onCommentsDataRefresh,
  }) async {
    final String name = comment.authorName.trim();
    if (name.isEmpty) {
      return;
    }
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext ctx) => CupertinoActionSheet(
        title: Text('「$name」'),
        message: const Text('请选择操作'),
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.of(ctx).pop();
              final FeedMuteController mute = FeedMuteScope.of(context);
              await mute.blockUser(name);
              if (!context.mounted) {
                return;
              }
              onCommentsDataRefresh?.call();
            },
            child: Text('拉黑「$name」'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.of(ctx).pop();
              final FeedMuteController mute = FeedMuteScope.of(context);
              await mute.hidePost(post.id);
              if (!context.mounted) {
                return;
              }
              onCommentsDataRefresh?.call();
              Navigator.of(context, rootNavigator: true)
                  .popUntil((Route<dynamic> r) => r.isFirst);
            },
            child: const Text('屏蔽此动态'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              startReportWithTarget(
                context,
                postId: post.id,
                userName: name,
                previewCaption: comment.text,
              );
            },
            child: const Text('举报'),
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
