import 'package:flutter/material.dart';

import '../data/lens_feed.dart';
import '../theme/huaxing_theme.dart';
import '../utils/chat_peer_storage.dart';
import '../utils/lens_ai_chat_storage.dart';
import '../widgets/glass_ui.dart';
import '../widgets/lens_network_or_asset_image.dart';
import 'chat_conversation_page.dart';
import 'lens_photo_ai_chat_page.dart';

const String _kDefaultAvatarAsset = 'assets/user_default.png';

class InboxTab extends StatefulWidget {
  const InboxTab({
    super.key,
    required this.isActive,
  });

  /// 当前底部导航是否选中「消息」页；用于每次进入时重新拉取会话列表。
  final bool isActive;

  @override
  State<InboxTab> createState() => _InboxTabState();
}

class _InboxTabState extends State<InboxTab> {
  bool _loading = true;
  bool _didLoadOnce = false;
  ({String preview, int lastAtMillis})? _aiSummary;
  List<ChatPeerInboxSummary> _peers = <ChatPeerInboxSummary>[];

  @override
  void initState() {
    super.initState();
    if (widget.isActive) {
      _load(silent: false);
    }
  }

  @override
  void didUpdateWidget(InboxTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _load(silent: _didLoadOnce);
    }
  }

  Future<void> _load({required bool silent}) async {
    if (!silent && mounted) {
      setState(() => _loading = true);
    }
    final ({String preview, int lastAtMillis})? ai =
        await LensAiChatStorage.inboxSummary();
    final List<ChatPeerInboxSummary> peers =
        await ChatPeerStorage.loadPeerInboxSummaries();
    if (!mounted) return;
    setState(() {
      _aiSummary = ai;
      _peers = peers;
      _loading = false;
      _didLoadOnce = true;
    });
  }

  String _formatTime(int millis) {
    final DateTime t = DateTime.fromMillisecondsSinceEpoch(millis);
    final DateTime now = DateTime.now();
    if (now.difference(t).inDays == 0) {
      return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    }
    return '${t.month}/${t.day}';
  }

  Future<void> _openAiChat() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const LensPhotoAiChatPage(),
      ),
    );
    await _load(silent: _didLoadOnce);
  }

  Future<void> _openPeerChat(ChatPeerInboxSummary row) async {
    final String avatar =
        lensAvatarUrlForUserName(row.userName) ?? _kDefaultAvatarAsset;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => ChatConversationPage(
          peerUserName: row.userName,
          peerAvatarUrl: avatar,
        ),
      ),
    );
    await _load(silent: _didLoadOnce);
  }

  @override
  Widget build(BuildContext context) {
    final double bottomPad = MediaQuery.of(context).padding.bottom + 88;

    return RefreshIndicator(
      color: kAccentYellow,
      backgroundColor: const Color(0xFF1A1A1E),
      onRefresh: () => _load(silent: true),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: Row(
                children: [
                  Text(
                    '消息',
                    style: Theme.of(context).appBarTheme.titleTextStyle,
                  ),
                ],
              ),
            ),
          ),
          if (_loading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: CircularProgressIndicator(color: kAccentYellow),
              ),
            )
          else ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                child: Text(
                  '会话',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.45),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: _openAiChat,
                    child: GlassPanel(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      borderRadius: 18,
                      blurSigma: 18,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor:
                                kAccentYellow.withOpacity(0.22),
                            child: Icon(
                              Icons.auto_awesome_rounded,
                              color: kAccentYellow.withOpacity(0.95),
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'AI 摄影咨询',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.95),
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    if (_aiSummary != null)
                                      Text(
                                        _formatTime(_aiSummary!.lastAtMillis),
                                        style: TextStyle(
                                          color:
                                              Colors.white.withOpacity(0.38),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  _aiSummary?.preview ??
                                      '智谱 GLM · 摄影问答 · 点此进入',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.52),
                                    fontSize: 13,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.white.withOpacity(0.35),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (_peers.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
                  child: Text(
                    '创作者私信',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.45),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  final ChatPeerInboxSummary row = _peers[index];
                  final String avatarUrl =
                      lensAvatarUrlForUserName(row.userName) ??
                          _kDefaultAvatarAsset;
                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      index == 0 ? 2 : 0,
                      16,
                      index < _peers.length - 1 ? 10 : 0,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => _openPeerChat(row),
                        child: GlassPanel(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          borderRadius: 18,
                          blurSigma: 16,
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(22),
                                child: SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: LensNetworkOrAssetImage(
                                    imageRef: avatarUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (BuildContext context, Object e,
                                            StackTrace? st) {
                                      return Container(
                                        color: Colors.white.withOpacity(0.08),
                                        alignment: Alignment.center,
                                        child: Icon(
                                          Icons.person_rounded,
                                          color:
                                              Colors.white.withOpacity(0.45),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            row.userName,
                                            style: TextStyle(
                                              color: Colors.white
                                                  .withOpacity(0.94),
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          _formatTime(row.lastAtMillis),
                                          style: TextStyle(
                                            color: Colors.white
                                                .withOpacity(0.38),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      row.lastPreview,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color:
                                            Colors.white.withOpacity(0.48),
                                        fontSize: 13,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: Colors.white.withOpacity(0.35),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
                childCount: _peers.length,
              ),
            ),
            if (!_loading && _peers.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24, 8, 24, bottomPad),
                  child: GlassPanel(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 28,
                    ),
                    borderRadius: 20,
                    blurSigma: 18,
                    child: Column(
                      children: [
                        Icon(
                          Icons.forum_outlined,
                          size: 44,
                          color: kAccentYellow.withOpacity(0.55),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          '暂无创作者私信',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.72),
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '在动态中进入摄影师主页即可发私信，记录会出现在这里。',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.42),
                            fontSize: 13,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverToBoxAdapter(child: SizedBox(height: bottomPad)),
          ],
        ],
      ),
    );
  }
}
