import 'package:flutter/material.dart';

import '../data/lens_feed.dart';
import '../models/lens_post.dart';
import '../state/feed_mute_controller.dart';
import '../theme/huaxing_theme.dart';
import '../utils/feed_interaction_storage.dart';
import '../widgets/feed_post_more_flow.dart';
import '../widgets/glass_ui.dart';
import '../widgets/lens_network_or_asset_image.dart';
import 'post_detail_page.dart';

class ExploreTab extends StatefulWidget {
  const ExploreTab({super.key});

  @override
  State<ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<ExploreTab> {
  Set<String> _likedIds = <String>{};

  @override
  void initState() {
    super.initState();
    _refreshLikes();
  }

  Future<void> _refreshLikes() async {
    final Set<String> liked = await FeedInteractionStorage.loadLikedPostIds();
    if (!mounted) return;
    setState(() => _likedIds = liked);
  }

  Future<void> _toggleLike(String postId) async {
    await FeedInteractionStorage.toggleLikePost(postId);
    await _refreshLikes();
  }

  @override
  Widget build(BuildContext context) {
    final FeedMuteController mute = FeedMuteScope.of(context);
    final List<LensPost> visiblePosts = mute.filterPosts<LensPost>(
      source: lensFeedPosts,
      userNameOf: (LensPost p) => p.userName,
      idOf: (LensPost p) => p.id,
    );
    final double bottom = MediaQuery.of(context).padding.bottom + 88;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: Row(
              children: [
                Text(
                  '发现',
                  style: Theme.of(context).appBarTheme.titleTextStyle,
                ),
                const Spacer(),
                GlassPanel(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  borderRadius: 16,
                  blurSigma: 14,
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_awesome_mosaic_rounded,
                        size: 18,
                        color: kAccentYellow.withOpacity(0.95),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '灵感拼贴',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.82),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Text(
              '双列瀑布 · 点击查看大图与拍摄参数',
              style: TextStyle(
                color: Colors.white.withOpacity(0.45),
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ),
        if (visiblePosts.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text(
                '暂无可浏览内容',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.42),
                  fontSize: 15,
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: EdgeInsets.fromLTRB(12, 0, 12, bottom),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.72,
              ),
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  final LensPost post = visiblePosts[index];
                  final bool liked = _likedIds.contains(post.id);
                  final int displayLikes = post.likes + (liked ? 1 : 0);
                  return _ExploreGridTile(
                    post: post,
                    displayLikes: displayLikes,
                    liked: liked,
                    onOpenDetail: () {
                      Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (BuildContext context) => PostDetailPage(
                            post: post,
                            heroTag: 'explore-hero-${post.id}',
                          ),
                        ),
                      );
                    },
                    onToggleLike: () => _toggleLike(post.id),
                    onMore: () =>
                        FeedPostMoreFlow.open(context, post),
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

class _ExploreGridTile extends StatelessWidget {
  const _ExploreGridTile({
    required this.post,
    required this.displayLikes,
    required this.liked,
    required this.onOpenDetail,
    required this.onToggleLike,
    required this.onMore,
  });

  final LensPost post;
  final int displayLikes;
  final bool liked;
  final VoidCallback onOpenDetail;
  final VoidCallback onToggleLike;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: GlassPanel(
        padding: EdgeInsets.zero,
        borderRadius: 18,
        blurSigma: 14,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onOpenDetail,
                child: Hero(
                  tag: 'explore-hero-${post.id}',
                  child: LensNetworkOrAssetImage(
                    imageRef: post.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (BuildContext context, Object error, StackTrace? stack) {
                      return Container(
                        color: Colors.white.withOpacity(0.06),
                      );
                    },
                  ),
                ),
              ),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: Material(
                color: Colors.black.withOpacity(0.42),
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: IconButton(
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  icon: Icon(
                    Icons.more_horiz_rounded,
                    size: 20,
                    color: Colors.white.withOpacity(0.92),
                  ),
                  onPressed: onMore,
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 26, 10, 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.78),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.userName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: onToggleLike,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 2,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              liked
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              size: 18,
                              color: liked
                                  ? const Color(0xFFFF5252)
                                  : kAccentYellow.withOpacity(0.95),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '$displayLikes',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.88),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
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
          ],
        ),
      ),
    );
  }
}
