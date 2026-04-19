import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/lens_post.dart';
import '../theme/huaxing_theme.dart';
import '../utils/feed_interaction_storage.dart';
import '../widgets/feed_post_more_flow.dart';
import '../widgets/glass_ui.dart';
import '../widgets/lens_network_or_asset_image.dart';

class PostDetailPage extends StatefulWidget {
  const PostDetailPage({
    super.key,
    required this.post,
    required this.heroTag,
  });

  final LensPost post;
  final String heroTag;

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
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

  Future<void> _toggleLike() async {
    await FeedInteractionStorage.toggleLikePost(widget.post.id);
    await _refreshLikes();
  }

  bool get _liked => _likedIds.contains(widget.post.id);

  int get _displayLikes => widget.post.likes + (_liked ? 1 : 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.post.userName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.more_horiz_rounded,
              color: Colors.white.withOpacity(0.85),
            ),
            onPressed: () => FeedPostMoreFlow.open(context, widget.post),
          ),
        ],
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              color: Colors.black.withOpacity(0.35),
            ),
          ),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              minScale: 0.85,
              maxScale: 3.2,
              clipBehavior: Clip.none,
              child: Center(
                child: Hero(
                  tag: widget.heroTag,
                  child: LensNetworkOrAssetImage(
                    imageRef: widget.post.imageUrl,
                    fit: BoxFit.contain,
                    width: double.infinity,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return SizedBox(
                        height: MediaQuery.of(context).size.height * 0.55,
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: kAccentYellow,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stack) {
                      return const Icon(
                        Icons.broken_image_outlined,
                        size: 64,
                        color: Colors.white38,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: GlassPanel(
                  borderRadius: 22,
                  blurSigma: 22,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          InkWell(
                            onTap: _toggleLike,
                            borderRadius: BorderRadius.circular(22),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 6,
                                horizontal: 4,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _liked
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    color: _liked
                                        ? const Color(0xFFFF5252)
                                        : Colors.white.withOpacity(0.88),
                                    size: 28,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '$_displayLikes',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.94),
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.photo_camera_rounded,
                            size: 16,
                            color: kAccentYellow.withOpacity(0.85),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              widget.post.shotWith,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: kAccentYellow.withOpacity(0.85),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          const Icon(Icons.place_outlined,
                              size: 16, color: kAccentYellow),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              widget.post.location,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.88),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (widget.post.userBio.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Icon(Icons.person_outline_rounded,
                                  size: 16,
                                  color: Colors.white.withOpacity(0.55)),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.post.userBio,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.62),
                                  fontSize: 13,
                                  height: 1.45,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 10),
                      Text(
                        widget.post.caption,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
