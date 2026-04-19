import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/huaxing_theme.dart';
import '../utils/my_portfolio_storage.dart';
import '../widgets/glass_ui.dart';

class MyPortfolioDetailPage extends StatefulWidget {
  const MyPortfolioDetailPage({super.key});

  @override
  State<MyPortfolioDetailPage> createState() => _MyPortfolioDetailPageState();
}

class _MyPortfolioDetailPageState extends State<MyPortfolioDetailPage> {
  final ImagePicker _picker = ImagePicker();
  List<String> _paths = <String>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final List<String> list = await MyPortfolioStorage.loadPaths();
    if (!mounted) return;
    setState(() {
      _paths = list;
      _loading = false;
    });
  }

  Future<void> _addFromGallery() async {
    final XFile? file =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 88);
    if (file == null) return;
    final String? dest = await MyPortfolioStorage.copyIntoPortfolio(file.path);
    if (!mounted) return;
    if (dest == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('保存图片失败，请重试'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.white.withOpacity(0.14),
        ),
      );
      return;
    }
    final List<String> next = <String>[..._paths, dest];
    await MyPortfolioStorage.savePaths(next);
    setState(() => _paths = next);
  }

  Future<void> _confirmDelete(int index) async {
    final String path = _paths[index];
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E22),
        title: const Text('删除作品', style: TextStyle(color: Colors.white)),
        content: const Text(
          '确定从作品集中移除这张图片吗？',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除', style: TextStyle(color: Color(0xFFFF5252))),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await MyPortfolioStorage.deleteFileIfExists(path);
    final List<String> next = List<String>.from(_paths)..removeAt(index);
    await MyPortfolioStorage.savePaths(next);
    setState(() => _paths = next);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundBlack,
      appBar: AppBar(
        title: const Text('我的作品集'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_photo_alternate_rounded,
                color: kAccentYellow.withOpacity(0.95)),
            onPressed: _loading ? null : _addFromGallery,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kAccentYellow))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: GlassPanel(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    borderRadius: 16,
                    blurSigma: 16,
                    child: Row(
                      children: [
                        Icon(Icons.collections_outlined,
                            color: kAccentYellow.withOpacity(0.9), size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _paths.isEmpty
                                ? '点击下方按钮或右上角添加，作品将保存在本机。'
                                : '共 ${_paths.length} 张 · 长按缩略图可删除',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.68),
                              fontSize: 13,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: _paths.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.image_outlined,
                                  size: 56,
                                  color: Colors.white.withOpacity(0.28),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  '暂无作品',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.55),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '从相册添加你的摄影作品',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.38),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          physics: const BouncingScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 1,
                          ),
                          itemCount: _paths.length,
                          itemBuilder: (BuildContext context, int index) {
                            final String path = _paths[index];
                            return GestureDetector(
                              onLongPress: () => _confirmDelete(index),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  File(path),
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (BuildContext context, Object error,
                                          StackTrace? stackTrace) {
                                    return Container(
                                      color: const Color(0xFF1A1A1C),
                                      alignment: Alignment.center,
                                      child: Icon(
                                        Icons.broken_image_outlined,
                                        color: Colors.white.withOpacity(0.35),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: FilledButton(
                      onPressed: _loading ? null : _addFromGallery,
                      style: FilledButton.styleFrom(
                        backgroundColor: kAccentYellow,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        '从相册添加作品',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
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
