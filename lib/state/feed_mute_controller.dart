import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/feed_comment.dart';
import '../utils/social_block_storage.dart';

class FeedMuteController extends ChangeNotifier {
  Set<String> blockedUserNames = <String>{};
  Set<String> hiddenPostIds = <String>{};

  Future<void> reloadFromStorage() async {
    final Set<String> blocked = await SocialBlockStorage.loadBlockedUsers();
    final Set<String> hidden = await SocialBlockStorage.loadHiddenPostIds();
    blockedUserNames = blocked;
    hiddenPostIds = hidden;
    notifyListeners();
  }

  Future<void> blockUser(String userName) async {
    await SocialBlockStorage.addBlockedUser(userName);
    await reloadFromStorage();
  }

  Future<void> hidePost(String postId) async {
    await SocialBlockStorage.addHiddenPost(postId);
    await reloadFromStorage();
  }

  List<T> filterPosts<T>({
    required List<T> source,
    required String Function(T item) userNameOf,
    required String Function(T item) idOf,
  }) {
    return source
        .where((T p) =>
            !blockedUserNames.contains(userNameOf(p)) &&
            !hiddenPostIds.contains(idOf(p)))
        .toList();
  }

  /// 评论区展示：排除已拉黑用户的评论（存储仍保留，仅 UI 过滤）。
  List<FeedComment> filterVisibleComments(List<FeedComment> source) {
    return source
        .where(
          (FeedComment c) =>
              !blockedUserNames.contains(c.authorName.trim()),
        )
        .toList();
  }
}

class FeedMuteScope extends InheritedNotifier<FeedMuteController> {
  const FeedMuteScope({
    super.key,
    required FeedMuteController super.notifier,
    required super.child,
  });

  static FeedMuteController of(BuildContext context) {
    final FeedMuteScope? scope =
        context.dependOnInheritedWidgetOfExactType<FeedMuteScope>();
    assert(scope != null, 'FeedMuteScope not found above this context');
    return scope!.notifier!;
  }
}
