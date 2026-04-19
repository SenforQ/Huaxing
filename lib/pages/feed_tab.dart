import 'dart:ui';

import 'package:flutter/material.dart';

import '../data/lens_feed.dart';
import '../models/feed_comment.dart';
import '../models/lens_post.dart';
import '../state/feed_mute_controller.dart';
import '../theme/huaxing_theme.dart';
import '../utils/feed_interaction_storage.dart';
import '../widgets/feed_comments_sheet.dart';
import '../widgets/feed_post_more_flow.dart';
import '../widgets/glass_ui.dart';
import '../widgets/lens_network_or_asset_image.dart';
import 'author_profile_page.dart';
import 'lens_search_page.dart';
import 'post_detail_page.dart';

class FeedTab extends StatefulWidget {
  const FeedTab({super.key});

  @override
  State<FeedTab> createState() => _FeedTabState();
}

class _FeedTabState extends State<FeedTab> {
  Set<String> _likedIds = <String>{};
  Map<String, List<FeedComment>> _commentsMap =
      <String, List<FeedComment>>{};

  @override
  void initState() {
    super.initState();
    _refreshInteractions();
  }

  Future<void> _refreshInteractions() async {
    final Set<String> liked =
        await FeedInteractionStorage.loadLikedPostIds();
    final Map<String, List<FeedComment>> comments =
        await FeedInteractionStorage.loadCommentsMap();
    if (!mounted) return;
    setState(() {
      _likedIds = liked;
      _commentsMap = comments;
    });
  }

  Future<void> _toggleLike(String id) async {
    await FeedInteractionStorage.toggleLikePost(id);
    await _refreshInteractions();
  }

  Future<void> _openComments(LensPost post) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.48),
      builder: (BuildContext context) => FeedCommentsSheet(
        post: post,
        onCommentsUpdated: () {
          _refreshInteractions();
        },
      ),
    );
  }

  double _bottomPadding(BuildContext context) {
    return MediaQuery.of(context).padding.bottom + 88;
  }

  @override
  Widget build(BuildContext context) {
    final FeedMuteController mute = FeedMuteScope.of(context);
    final List<LensPost> visiblePosts = mute.filterPosts<LensPost>(
      source: lensFeedPosts,
      userNameOf: (LensPost p) => p.userName,
      idOf: (LensPost p) => p.id,
    );

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          pinned: true,
          stretch: true,
          expandedHeight: 76,
          backgroundColor: Colors.transparent,
          flexibleSpace: FlexibleSpaceBar(
            stretchModes: const [
              StretchMode.zoomBackground,
              StretchMode.blurBackground,
            ],
            background: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.65),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(color: Colors.black.withOpacity(0.25)),
                  ),
                ),
              ],
            ),
            titlePadding: const EdgeInsets.only(left: 20, bottom: 4),
            title: Text(
              '花杏摄影',
              style: Theme.of(context).appBarTheme.titleTextStyle?.copyWith(
                    fontSize: 22,
                  ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (BuildContext context) => const LensSearchPage(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(18),
                child: GlassPanel(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  borderRadius: 18,
                  child: Row(
                    children: [
                      Icon(Icons.tag_rounded, color: kAccentYellow.withOpacity(0.95), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '搜索创作者、标签、机身镜头…',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.45),
                            fontSize: 15,
                          ),
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: Colors.white.withOpacity(0.4), size: 22),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 104,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (int i = 0; i < lensStoryAvatarUrls.length; i++)
                  if (i < lensFeedPosts.length &&
                      !mute.blockedUserNames
                          .contains(lensFeedPosts[i].userName))
                    Padding(
                      padding: const EdgeInsets.only(right: 14),
                      child: _StoryRing(
                        avatarUrl: lensStoryAvatarUrls[i],
                        label: lensStoryLabels[i],
                      ),
                    ),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
        if (visiblePosts.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  '暂无动态\n你可尝试调整拉黑或屏蔽设置',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.42),
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, _bottomPadding(context)),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final LensPost post = visiblePosts[index];
                  final bool liked = _likedIds.contains(post.id);
                  final int likeCount =
                      post.likes + (liked ? 1 : 0);
                  final int commentCount =
                      _commentsMap[post.id]?.length ?? 0;
                  return Padding(
                    padding: EdgeInsets.only(
                        bottom:
                            index < visiblePosts.length - 1 ? 18 : 0),
                    child: _LensFeedCard(
                      post: post,
                      displayLikes: likeCount,
                      commentCount: commentCount,
                      liked: liked,
                      onLike: () => _toggleLike(post.id),
                      onCommentTap: () => _openComments(post),
                      onMoreTap: () =>
                          FeedPostMoreFlow.open(context, post),
                      onAuthorTap: () {
                        Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder: (BuildContext context) =>
                                AuthorProfilePage(seedPost: post),
                          ),
                        );
                      },
                      onOpen: () {
                        Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder: (context) => PostDetailPage(
                              post: post,
                              heroTag: 'feed-hero-${post.id}',
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
                childCount: visiblePosts.length,
              ),
            ),
          ),
      ],
    );
  }
}

class _StoryRing extends StatelessWidget {
  const _StoryRing({
    required this.avatarUrl,
    required this.label,
  });

  final String avatarUrl;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
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
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF0E0E10),
            ),
            padding: const EdgeInsets.all(2),
            child: ClipOval(
              child: LensNetworkOrAssetImage(
                imageRef: avatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) {
                  return Container(color: Colors.white12, child: const Icon(Icons.person, color: Colors.white38));
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 68,
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.82),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _LensFeedCard extends StatelessWidget {
  const _LensFeedCard({
    required this.post,
    required this.displayLikes,
    required this.commentCount,
    required this.liked,
    required this.onLike,
    required this.onCommentTap,
    required this.onMoreTap,
    required this.onAuthorTap,
    required this.onOpen,
  });

  final LensPost post;
  final int displayLikes;
  final int commentCount;
  final bool liked;
  final VoidCallback onLike;
  final VoidCallback onCommentTap;
  final VoidCallback onMoreTap;
  final VoidCallback onAuthorTap;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: EdgeInsets.zero,
      borderRadius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onAuthorTap,
                    borderRadius: BorderRadius.circular(22),
                    child: ClipOval(
                      child: LensNetworkOrAssetImage(
                        imageRef: post.userAvatar,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) {
                          return Container(
                            width: 40,
                            height: 40,
                            color: Colors.white10,
                            child: const Icon(Icons.person, color: Colors.white38, size: 22),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.place_rounded, size: 13, color: Colors.white.withOpacity(0.55)),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              post.location,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.55),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.more_horiz_rounded, color: Colors.white.withOpacity(0.55)),
                  onPressed: onMoreTap,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onOpen,
            child: AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(4)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(
                      tag: 'feed-hero-${post.id}',
                      child: LensNetworkOrAssetImage(
                        imageRef: post.imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            color: Colors.white.withOpacity(0.04),
                            child: const Center(
                              child: CircularProgressIndicator(color: kAccentYellow, strokeWidth: 2),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stack) {
                          return Container(
                            color: Colors.white.withOpacity(0.06),
                            alignment: Alignment.center,
                            child: const Icon(Icons.image_not_supported_outlined, color: Colors.white38, size: 48),
                          );
                        },
                      ),
                    ),
                    Positioned(
                      left: 12,
                      bottom: 12,
                      child: GlassPanel(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        borderRadius: 14,
                        blurSigma: 14,
                        fillOpacityHigh: 0.1,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.photo_camera_rounded, size: 14, color: kAccentYellow),
                            const SizedBox(width: 6),
                            Text(
                              post.shotWith,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.92),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 14, 6),
            child: Row(
              children: [
                InkWell(
                  onTap: onLike,
                  borderRadius: BorderRadius.circular(22),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        Icon(
                          liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: liked ? const Color(0xFFFF5252) : Colors.white.withOpacity(0.85),
                          size: 26,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$displayLikes',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: onCommentTap,
                  borderRadius: BorderRadius.circular(22),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded, color: Colors.white.withOpacity(0.85), size: 24),
                        const SizedBox(width: 6),
                        Text(
                          '$commentCount',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
            child: RichText(
              text: TextSpan(
                style: TextStyle(color: Colors.white.withOpacity(0.92), fontSize: 14, height: 1.45),
                children: [
                  TextSpan(
                    text: '${post.userName} ',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: post.caption),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
