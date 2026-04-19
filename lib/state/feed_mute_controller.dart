import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
