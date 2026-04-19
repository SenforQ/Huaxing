import 'package:flutter/material.dart';

import '../data/lens_feed.dart';
import '../models/lens_post.dart';
import '../theme/huaxing_theme.dart';
import '../widgets/glass_ui.dart';
import '../widgets/lens_network_or_asset_image.dart';
import 'post_detail_page.dart';

bool _tokenMatches(String haystack, String needleLower) {
  return haystack.toLowerCase().contains(needleLower);
}

bool _postMatchesAny(LensPost post, String needleLower) {
  return _tokenMatches(post.userName, needleLower) ||
      _tokenMatches(post.userBio, needleLower) ||
      _tokenMatches(post.location, needleLower) ||
      _tokenMatches(post.caption, needleLower) ||
      _tokenMatches(post.shotWith, needleLower);
}

bool _creatorMatches(LensPost post, String needleLower) {
  return _tokenMatches(post.userName, needleLower) ||
      _tokenMatches(post.userBio, needleLower);
}

List<LensPost> _postsMatching(String query) {
  final String t = query.trim();
  if (t.isEmpty) {
    return <LensPost>[];
  }
  final String low = t.toLowerCase();
  return lensFeedPosts
      .where((LensPost p) => _postMatchesAny(p, low))
      .toList();
}

List<LensPost> _creatorsMatching(String query) {
  final String t = query.trim();
  if (t.isEmpty) {
    return <LensPost>[];
  }
  final String low = t.toLowerCase();
  final Map<String, LensPost> byName = <String, LensPost>{};
  for (final LensPost p in lensFeedPosts) {
    if (_creatorMatches(p, low)) {
      byName.putIfAbsent(p.userName, () => p);
    }
  }
  return byName.values.toList();
}

class LensSearchPage extends StatefulWidget {
  const LensSearchPage({super.key});

  @override
  State<LensSearchPage> createState() => _LensSearchPageState();
}

class _LensSearchPageState extends State<LensSearchPage> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _applyChip(String text) {
    _controller.text = text;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final String query = _controller.text;
    final List<LensPost> creators = _creatorsMatching(query);
    final List<LensPost> posts = _postsMatching(query);
    final bool hasQuery = query.trim().isNotEmpty;
    final double bottom = MediaQuery.of(context).padding.bottom + 24;

    return Scaffold(
      backgroundColor: kBackgroundBlack,
      appBar: AppBar(
        title: const Text('搜索'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
            child: GlassPanel(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              borderRadius: 18,
              blurSigma: 16,
              child: Row(
                children: [
                  Icon(Icons.search_rounded,
                      color: kAccentYellow.withOpacity(0.9), size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: '创作者、地点、文案、机身镜头…',
                        hintStyle:
                            TextStyle(color: Colors.white.withOpacity(0.38)),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  if (hasQuery)
                    IconButton(
                      icon: Icon(Icons.clear_rounded,
                          color: Colors.white.withOpacity(0.55)),
                      onPressed: () {
                        _controller.clear();
                        setState(() {});
                      },
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                if (!hasQuery)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '试试这些关键词',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.55),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final String label in lensStoryLabels)
                                ActionChip(
                                  label: Text(label),
                                  onPressed: () => _applyChip(label),
                                  backgroundColor:
                                      Colors.white.withOpacity(0.08),
                                  labelStyle: TextStyle(
                                    color: Colors.white.withOpacity(0.88),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                  side: BorderSide(
                                    color: Colors.white.withOpacity(0.14),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 2),
                                ),
                              ActionChip(
                                label: const Text('胶片'),
                                onPressed: () => _applyChip('胶片'),
                                backgroundColor:
                                    Colors.white.withOpacity(0.08),
                                labelStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.88),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                                side: BorderSide(
                                  color: Colors.white.withOpacity(0.14),
                                ),
                              ),
                              ActionChip(
                                label: const Text('索尼'),
                                onPressed: () => _applyChip('索尼'),
                                backgroundColor:
                                    Colors.white.withOpacity(0.08),
                                labelStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.88),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                                side: BorderSide(
                                  color: Colors.white.withOpacity(0.14),
                                ),
                              ),
                              ActionChip(
                                label: const Text('长曝光'),
                                onPressed: () => _applyChip('长曝光'),
                                backgroundColor:
                                    Colors.white.withOpacity(0.08),
                                labelStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.88),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                                side: BorderSide(
                                  color: Colors.white.withOpacity(0.14),
                                ),
                              ),
                              ActionChip(
                                label: const Text('外滩'),
                                onPressed: () => _applyChip('外滩'),
                                backgroundColor:
                                    Colors.white.withOpacity(0.08),
                                labelStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.88),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                                side: BorderSide(
                                  color: Colors.white.withOpacity(0.14),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),
                          Center(
                            child: Text(
                              '输入关键词后，将匹配创作者资料与作品内容。',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.38),
                                fontSize: 14,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (hasQuery &&
                    creators.isEmpty &&
                    posts.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(32, 0, 32, bottom),
                        child: Text(
                          '没有找到相关内容，换个关键词试试。',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.45),
                            fontSize: 15,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (hasQuery && creators.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      child: Text(
                        '创作者 · ${creators.length}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.72),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                if (hasQuery && creators.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (BuildContext context, int index) {
                          final LensPost p = creators[index];
                          return Padding(
                            padding: EdgeInsets.only(
                                bottom: index < creators.length - 1 ? 10 : 0),
                            child: GlassPanel(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                              borderRadius: 16,
                              blurSigma: 14,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: LensNetworkOrAssetImage(
                                      imageRef: p.userAvatar,
                                      width: 52,
                                      height: 52,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Container(
                                          width: 52,
                                          height: 52,
                                          color: Colors.white.withOpacity(0.08),
                                          alignment: Alignment.center,
                                          child: Icon(
                                            Icons.person_rounded,
                                            color:
                                                Colors.white.withOpacity(0.4),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p.userName,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          p.userBio,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color:
                                                Colors.white.withOpacity(0.52),
                                            fontSize: 13,
                                            height: 1.35,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        childCount: creators.length,
                      ),
                    ),
                  ),
                if (hasQuery && posts.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                          16, creators.isNotEmpty ? 18 : 4, 16, 8),
                      child: Text(
                        '作品 · ${posts.length}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.72),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                if (hasQuery && posts.isNotEmpty)
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, bottom),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (BuildContext context, int index) {
                          final LensPost p = posts[index];
                          return Padding(
                            padding: EdgeInsets.only(
                                bottom: index < posts.length - 1 ? 12 : 0),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(18),
                                onTap: () {
                                  Navigator.of(context).push<void>(
                                    MaterialPageRoute<void>(
                                      builder: (BuildContext context) =>
                                          PostDetailPage(
                                        post: p,
                                        heroTag: 'search-hero-${p.id}',
                                      ),
                                    ),
                                  );
                                },
                                child: GlassPanel(
                                  padding: EdgeInsets.zero,
                                  borderRadius: 18,
                                  blurSigma: 16,
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(18),
                                          bottomLeft: Radius.circular(18),
                                        ),
                                        child: LensNetworkOrAssetImage(
                                          imageRef: p.imageUrl,
                                          width: 108,
                                          height: 108,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Container(
                                              width: 108,
                                              height: 108,
                                              color: Colors.white
                                                  .withOpacity(0.06),
                                            );
                                          },
                                        ),
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              12, 10, 12, 10),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  ClipOval(
                                                    child: LensNetworkOrAssetImage(
                                                      imageRef: p.userAvatar,
                                                      width: 26,
                                                      height: 26,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context,
                                                          error, stackTrace) {
                                                        return Container(
                                                          width: 26,
                                                          height: 26,
                                                          color: Colors
                                                              .white
                                                              .withOpacity(
                                                                  0.1),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      p.userName,
                                                      maxLines: 1,
                                                      overflow: TextOverflow
                                                          .ellipsis,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                p.caption,
                                                maxLines: 2,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: Colors.white
                                                      .withOpacity(0.62),
                                                  fontSize: 13,
                                                  height: 1.35,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                p.location,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: kAccentYellow
                                                      .withOpacity(0.82),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
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
                          );
                        },
                        childCount: posts.length,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
