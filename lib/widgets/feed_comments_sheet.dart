import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../models/feed_comment.dart';
import '../models/lens_post.dart';
import '../pages/user_agreement_page.dart';
import '../state/feed_mute_controller.dart';
import '../theme/huaxing_theme.dart';
import '../utils/comment_user_agreement_storage.dart';
import '../utils/feed_interaction_storage.dart';
import '../utils/profile_storage.dart';
import 'feed_post_more_flow.dart';

String _formatRelativeTime(int millis) {
  final DateTime dt = DateTime.fromMillisecondsSinceEpoch(millis);
  final DateTime now = DateTime.now();
  final Duration diff = now.difference(dt);
  if (diff.inSeconds < 60) {
    return '刚刚';
  }
  if (diff.inMinutes < 60) {
    return '${diff.inMinutes} 分钟前';
  }
  if (diff.inHours < 24) {
    return '${diff.inHours} 小时前';
  }
  final String hh = dt.hour.toString().padLeft(2, '0');
  final String mm = dt.minute.toString().padLeft(2, '0');
  return '${dt.year}/${dt.month}/${dt.day} $hh:$mm';
}

class FeedCommentsSheet extends StatefulWidget {
  const FeedCommentsSheet({
    super.key,
    required this.post,
    required this.onCommentsUpdated,
  });

  final LensPost post;
  final VoidCallback onCommentsUpdated;

  @override
  State<FeedCommentsSheet> createState() => _FeedCommentsSheetState();
}

class _FeedCommentsSheetState extends State<FeedCommentsSheet> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<FeedComment> _allComments = <FeedComment>[];
  bool _loading = true;
  String _documentsPath = '';
  String _profileNickname = ProfileStorage.defaultNickname;
  String? _profileAvatarAbs;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  String? _avatarAbsolutePathForComment(FeedComment c) {
    final String rel = c.authorAvatarRelativePath?.trim() ?? '';
    if (rel.isNotEmpty && _documentsPath.isNotEmpty) {
      final File f = File(p.join(_documentsPath, rel));
      if (f.existsSync()) {
        return f.path;
      }
    }
    final String nick = c.authorName.trim();
    final String mine = _profileNickname.trim();
    if (nick.isNotEmpty &&
        mine.isNotEmpty &&
        nick == mine &&
        _profileAvatarAbs != null &&
        File(_profileAvatarAbs!).existsSync()) {
      return _profileAvatarAbs;
    }
    return null;
  }

  bool _isCommentFromOtherUser(FeedComment c) {
    final String author = c.authorName.trim();
    final String mine = _profileNickname.trim();
    if (author.isEmpty || mine.isEmpty) {
      return author.isNotEmpty && author != mine;
    }
    return author != mine;
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final List<FeedComment> list =
        await FeedInteractionStorage.commentsForPost(widget.post.id);
    final ProfileEditState state = await ProfileStorage.load();
    final Directory doc = await ProfileStorage.documentsDirectory();
    String? abs;
    if (state.avatarRelativePath != null &&
        state.avatarRelativePath!.trim().isNotEmpty) {
      final File f = File(p.join(doc.path, state.avatarRelativePath!.trim()));
      if (f.existsSync()) {
        abs = f.path;
      }
    }
    final String nick = state.nickname.trim().isEmpty
        ? ProfileStorage.defaultNickname
        : state.nickname.trim();
    if (!mounted) return;
    setState(() {
      _allComments = list;
      _documentsPath = doc.path;
      _profileNickname = nick;
      _profileAvatarAbs = abs;
      _loading = false;
    });
  }

  Future<bool?> _showCommentAgreementGateDialog() async {
    final BuildContext sheetContext = context;
    bool checked = false;
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext _, void Function(void Function()) setLocal) {
            return AlertDialog(
              backgroundColor: const Color(0xFF2C2C2E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: Text(
                '发表评论前请确认',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.96),
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '为保护社区环境，发表评论前请阅读并同意遵守《用户协议》。不同意则无法发布评论。',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.78),
                        fontSize: 15,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(sheetContext).push<void>(
                            MaterialPageRoute<void>(
                              builder: (BuildContext context) =>
                                  const UserAgreementPage(),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: kAccentYellow,
                          padding: EdgeInsets.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          '查看完整用户协议',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: checked,
                            onChanged: (bool? v) {
                              setLocal(() => checked = v ?? false);
                            },
                            activeColor: kAccentYellow,
                            checkColor: Colors.black,
                            side: BorderSide(
                              color: Colors.white.withOpacity(0.45),
                            ),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setLocal(() => checked = !checked),
                              behavior: HitTestBehavior.opaque,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Text(
                                  '我已阅读《用户协议》，并同意在发表评论时遵守其中约定（包括不得发布违法、侵权、骚扰、低俗等不良信息）。',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.88),
                                    fontSize: 14,
                                    height: 1.42,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(
                    '取消',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.65),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                FilledButton(
                  onPressed: checked
                      ? () => Navigator.of(dialogContext).pop(true)
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: kAccentYellow,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor:
                        Colors.white.withOpacity(0.12),
                    disabledForegroundColor:
                        Colors.white.withOpacity(0.35),
                  ),
                  child: const Text(
                    '同意并发送',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _send() async {
    final String text = _controller.text.trim();
    if (text.isEmpty) return;

    final bool agreedStored =
        await CommentUserAgreementStorage.hasAccepted();
    if (!agreedStored) {
      final bool? agreed = await _showCommentAgreementGateDialog();
      if (agreed != true) {
        return;
      }
      await CommentUserAgreementStorage.setAccepted(true);
    }

    final ProfileEditState profile = await ProfileStorage.load();
    final String nick = profile.nickname.trim().isEmpty
        ? ProfileStorage.defaultNickname
        : profile.nickname.trim();
    final String? avatarRel = profile.avatarRelativePath?.trim();
    final FeedComment comment = FeedComment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      authorName: nick,
      text: text,
      createdAtMillis: DateTime.now().millisecondsSinceEpoch,
      authorAvatarRelativePath:
          avatarRel != null && avatarRel.isNotEmpty ? avatarRel : null,
    );
    await FeedInteractionStorage.appendComment(widget.post.id, comment);
    _controller.clear();
    await _reload();
    widget.onCommentsUpdated();
    if (mounted) {
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    FeedMuteScope.of(context);
    return SizedBox.expand(
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.56,
        minChildSize: 0.38,
        maxChildSize: 0.94,
        builder: (BuildContext context, ScrollController scrollController) {
          final FeedMuteController mute = FeedMuteScope.of(context);
          final List<FeedComment> visibleComments =
              mute.filterVisibleComments(_allComments);
          return DecoratedBox(
            decoration: const BoxDecoration(
              color: Color(0xFF2C2C2E),
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 24,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 38,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.28),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 14, 4, 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.close_rounded,
                            color: Colors.white.withOpacity(0.72), size: 22),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Expanded(
                        child: Text(
                          '评论',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.96),
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                Divider(height: 1, color: Colors.white.withOpacity(0.08)),
                Expanded(
                  child: _loading
                      ? const Center(
                          child:
                              CircularProgressIndicator(color: kAccentYellow),
                        )
                      : visibleComments.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 40),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.chat_bubble_outline_rounded,
                                      size: 48,
                                      color: Colors.white.withOpacity(0.28),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      '暂无评论',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.55),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '还没有人留言，来说点什么吧。',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.38),
                                        fontSize: 14,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.separated(
                              controller: scrollController,
                              padding: const EdgeInsets.fromLTRB(
                                  16, 12, 16, 12),
                              itemCount: visibleComments.length,
                              separatorBuilder: (_, __) => Divider(
                                height: 20,
                                thickness: 0.5,
                                color: Colors.white.withOpacity(0.08),
                              ),
                              itemBuilder: (BuildContext context, int index) {
                                final FeedComment c = visibleComments[index];
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _ProfileRingAvatar(
                                      absolutePath:
                                          _avatarAbsolutePathForComment(c),
                                      size: 40,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Expanded(
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Flexible(
                                                      child: Text(
                                                        c.authorName,
                                                        maxLines: 1,
                                                        overflow:
                                                            TextOverflow.ellipsis,
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          fontSize: 15,
                                                        ),
                                                      ),
                                                    ),
                                                    if (_isCommentFromOtherUser(
                                                        c)) ...[
                                                      const SizedBox(width: 6),
                                                      _OtherUserCommentBadge(
                                                        onTap: () {
                                                          FeedPostMoreFlow
                                                              .openCommentAuthorActions(
                                                            context,
                                                            widget.post,
                                                            c,
                                                            onCommentsDataRefresh:
                                                                () {
                                                              widget
                                                                  .onCommentsUpdated();
                                                              _reload();
                                                            },
                                                          );
                                                        },
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                              Text(
                                                _formatRelativeTime(
                                                    c.createdAtMillis),
                                                style: TextStyle(
                                                  color: Colors.white
                                                      .withOpacity(0.38),
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            c.text,
                                            style: TextStyle(
                                              color:
                                                  Colors.white.withOpacity(0.88),
                                              fontSize: 15,
                                              height: 1.42,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                ),
                Divider(height: 1, color: Colors.white.withOpacity(0.12)),
                Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Padding(
                  padding: EdgeInsets.only(
                    left: 12,
                    right: 12,
                    top: 10,
                    bottom:
                        MediaQuery.of(context).padding.bottom + 12,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.35),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.12),
                            ),
                          ),
                          child: TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            maxLines: 4,
                            minLines: 1,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              height: 1.35,
                            ),
                            decoration: InputDecoration(
                              hintText: '友善评论，分享你的看法…',
                              hintStyle: TextStyle(
                                color: Colors.white.withOpacity(0.34),
                                fontSize: 15,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            onSubmitted: (_) => _send(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Material(
                        color: kAccentYellow,
                        borderRadius: BorderRadius.circular(22),
                        child: InkWell(
                          onTap: _send,
                          borderRadius: BorderRadius.circular(22),
                          child: const Padding(
                            padding: EdgeInsets.all(12),
                            child: Icon(
                              Icons.send_rounded,
                              color: Colors.black,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _OtherUserCommentBadge extends StatelessWidget {
  const _OtherUserCommentBadge({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: SizedBox(
          width: 20,
          height: 20,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: kAccentYellow,
            ),
            child: Center(
              child: Text(
                '!',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileRingAvatar extends StatelessWidget {
  const _ProfileRingAvatar({
    required this.absolutePath,
    required this.size,
  });

  final String? absolutePath;
  final double size;

  @override
  Widget build(BuildContext context) {
    final double inner = size - 5;
    return SizedBox(
      width: size,
      height: size,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              kAccentYellow.withOpacity(0.95),
              kAccentYellow.withOpacity(0.35),
            ],
          ),
        ),
        padding: const EdgeInsets.all(2.5),
        child: ClipOval(
          child: absolutePath != null && File(absolutePath!).existsSync()
              ? Image.file(
                  File(absolutePath!),
                  width: inner,
                  height: inner,
                  fit: BoxFit.cover,
                  errorBuilder: (BuildContext context, Object error,
                      StackTrace? stackTrace) {
                    return _DefaultAvatarFace(size: inner);
                  },
                )
              : _DefaultAvatarFace(size: inner),
        ),
      ),
    );
  }
}

class _DefaultAvatarFace extends StatelessWidget {
  const _DefaultAvatarFace({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/user_default.png',
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (BuildContext context, Object error, StackTrace? stack) {
        return Container(
          width: size,
          height: size,
          color: const Color(0xFF1E1E1E),
          alignment: Alignment.center,
          child: Icon(
            Icons.person_rounded,
            size: size * 0.45,
            color: Colors.white.withOpacity(0.7),
          ),
        );
      },
    );
  }
}
