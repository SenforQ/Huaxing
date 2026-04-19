import 'dart:io';

import 'package:flutter/material.dart';

import '../utils/portfolio_like_storage.dart';
import '../widgets/glass_ui.dart';

class LocalPhotoViewerPage extends StatefulWidget {
  const LocalPhotoViewerPage({
    super.key,
    required this.imagePath,
  });

  final String imagePath;

  @override
  State<LocalPhotoViewerPage> createState() => _LocalPhotoViewerPageState();
}

class _LocalPhotoViewerPageState extends State<LocalPhotoViewerPage> {
  Set<String> _likedPaths = <String>{};

  bool get _liked => _likedPaths.contains(widget.imagePath);

  static const int _baseLikeCount = 0;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final Set<String> liked = await PortfolioLikeStorage.loadLikedPaths();
    if (!mounted) return;
    setState(() => _likedPaths = liked);
  }

  Future<void> _toggleLike() async {
    await PortfolioLikeStorage.toggleLikePath(widget.imagePath);
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final int displayLikes = _baseLikeCount + (_liked ? 1 : 0);

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
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              minScale: 0.85,
              maxScale: 4,
              clipBehavior: Clip.none,
              child: Center(
                child: Image.file(
                  File(widget.imagePath),
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (
                    BuildContext context,
                    Object error,
                    StackTrace? stackTrace,
                  ) {
                    return Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white.withOpacity(0.45),
                        size: 64,
                      ),
                    );
                  },
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
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: GlassPanel(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  borderRadius: 20,
                  blurSigma: 22,
                  child: InkWell(
                    onTap: _toggleLike,
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            _liked
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: _liked
                                ? const Color(0xFFFF5252)
                                : Colors.white.withOpacity(0.9),
                            size: 26,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '$displayLikes',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.92),
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '我的作品 · 本地点赞',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.45),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
