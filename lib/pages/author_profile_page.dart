import 'package:flutter/material.dart';

import '../data/lens_feed.dart';
import '../models/lens_post.dart';
import '../state/feed_mute_controller.dart';
import '../theme/huaxing_theme.dart';
import '../utils/follow_storage.dart';
import '../widgets/feed_post_more_flow.dart';
import '../widgets/glass_ui.dart';
import '../widgets/lens_network_or_asset_image.dart';
import 'chat_conversation_page.dart';
import 'post_detail_page.dart';

class AuthorProfilePage extends StatefulWidget {
  const AuthorProfilePage({
    super.key,
    required this.seedPost,
  });

  final LensPost seedPost;

  @override
  State<AuthorProfilePage> createState() => _AuthorProfilePageState();
}

class _AuthorProfilePageState extends State<AuthorProfilePage> {
  bool _following = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFollow();
  }

  Future<void> _loadFollow() async {
    final bool v =
        await FollowStorage.isFollowing(widget.seedPost.userName);
    if (!mounted) return;
    setState(() {
      _following = v;
      _loading = false;
    });
  }

  Future<void> _toggleFollow() async {
    await FollowStorage.toggle(widget.seedPost.userName);
    await _loadFollow();
  }

  void _openChat() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => ChatConversationPage(
          peerUserName: widget.seedPost.userName,
          peerAvatarUrl: widget.seedPost.userAvatar,
        ),
      ),
    );
  }

  void _openPost(LensPost post) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => PostDetailPage(
          post: post,
          heroTag: 'profile-portfolio-${post.id}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final LensPost p = widget.seedPost;
    final FeedMuteController mute = FeedMuteScope.of(context);
    final List<LensPost> visibleFeed = mute.filterPosts<LensPost>(
      source: lensFeedPosts,
      userNameOf: (LensPost x) => x.userName,
      idOf: (LensPost x) => x.id,
    );
    final List<LensPost> portfolioPosts = <LensPost>[
      for (final LensPost x in visibleFeed)
        if (x.userName == p.userName) x,
    ];

    return Scaffold(
      backgroundColor: kBackgroundBlack,
      appBar: AppBar(
        title: const Text('摄影师主页'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.more_horiz_rounded,
              color: Colors.white.withOpacity(0.88),
            ),
            onPressed: () =>
                FeedPostMoreFlow.openAuthorProfile(context, widget.seedPost),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kAccentYellow))
          : SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                MediaQuery.of(context).padding.bottom + 28,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 112,
                      height: 112,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            kAccentYellow.withOpacity(0.95),
                            kAccentYellow.withOpacity(0.35),
                          ],
                        ),
                      ),
                      padding: const EdgeInsets.all(3),
                      child: ClipOval(
                        child: LensNetworkOrAssetImage(
                          imageRef: p.userAvatar,
                          fit: BoxFit.cover,
                          errorBuilder: (BuildContext context, Object error,
                              StackTrace? stackTrace) {
                            return Container(
                              color: const Color(0xFF1E1E1E),
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.person_rounded,
                                size: 52,
                                color: Colors.white.withOpacity(0.65),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    p.userName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.place_outlined,
                        size: 16,
                        color: Colors.white.withOpacity(0.5),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          p.location,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.55),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  GlassPanel(
                    padding: const EdgeInsets.all(18),
                    borderRadius: 20,
                    blurSigma: 18,
                    child: Text(
                      p.userBio.isEmpty ? '暂无简介' : p.userBio,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.82),
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      backgroundColor: _following
                          ? Colors.white.withOpacity(0.12)
                          : kAccentYellow.withOpacity(0.25),
                      foregroundColor:
                          _following ? Colors.white : kAccentYellow,
                    ),
                    onPressed: _toggleFollow,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        _following ? '已关注' : '+ 关注',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _openChat,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        '发消息',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Text(
                        '作品集',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.92),
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${portfolioPosts.length} 件',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.45),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (portfolioPosts.isEmpty)
                    GlassPanel(
                      padding: const EdgeInsets.symmetric(
                        vertical: 22,
                        horizontal: 16,
                      ),
                      borderRadius: 16,
                      blurSigma: 14,
                      child: Center(
                        child: Text(
                          '暂无作品',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1,
                      ),
                      itemCount: portfolioPosts.length,
                      itemBuilder: (BuildContext context, int index) {
                        final LensPost work = portfolioPosts[index];
                        return Hero(
                          tag: 'profile-portfolio-${work.id}',
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _openPost(work),
                              borderRadius: BorderRadius.circular(10),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    LensNetworkOrAssetImage(
                                      imageRef: work.imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (BuildContext context, Object error,
                                              StackTrace? stackTrace) {
                                        return Container(
                                          color: const Color(0xFF1E1E1E),
                                          alignment: Alignment.center,
                                          child: Icon(
                                            Icons.image_not_supported_outlined,
                                            color: Colors.white.withOpacity(0.35),
                                            size: 28,
                                          ),
                                        );
                                      },
                                    ),
                                    Positioned(
                                      left: 0,
                                      right: 0,
                                      bottom: 0,
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              Colors.black.withOpacity(0.55),
                                            ],
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                            6,
                                            16,
                                            6,
                                            6,
                                          ),
                                          child: Text(
                                            work.location,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.88),
                                              fontSize: 9,
                                              fontWeight: FontWeight.w600,
                                              height: 1.1,
                                            ),
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
                      },
                    ),
                ],
              ),
            ),
    );
  }
}
