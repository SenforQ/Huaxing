import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import '../models/portfolio_item.dart';
import '../theme/huaxing_theme.dart';
import '../utils/portfolio_storage.dart';
import '../utils/profile_storage.dart';
import '../widgets/glass_ui.dart';

class PortfolioEditPage extends StatefulWidget {
  const PortfolioEditPage({super.key, this.initial});

  final PortfolioItem? initial;

  @override
  State<PortfolioEditPage> createState() => _PortfolioEditPageState();
}

class _PortfolioEditPageState extends State<PortfolioEditPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  late DateTime _capturedAt;
  String? _tempPickedImagePath;
  bool _loading = true;
  String? _existingImageAbsolutePath;

  bool get _isEdit => widget.initial != null;

  static String _formatCapturedLabel(DateTime d) {
    final String hh = d.hour.toString().padLeft(2, '0');
    final String mm = d.minute.toString().padLeft(2, '0');
    return '${d.year}年${d.month}月${d.day}日 $hh:$mm';
  }

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final PortfolioItem? initial = widget.initial;
    _capturedAt = initial?.capturedAt ?? DateTime.now();
    _titleController.text = initial?.title ?? '';
    _contentController.text = initial?.content ?? '';
    _locationController.text = initial?.location ?? '';

    if (initial != null &&
        initial.imageRelativePath.trim().isNotEmpty) {
      final Directory doc = await ProfileStorage.documentsDirectory();
      final File f =
          File(p.join(doc.path, initial.imageRelativePath.trim()));
      if (f.existsSync()) {
        _existingImageAbsolutePath = f.path;
      }
    }

    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 4096,
      maxHeight: 4096,
      imageQuality: 92,
    );
    if (image == null) return;
    setState(() {
      _tempPickedImagePath = image.path;
      _existingImageAbsolutePath = null;
    });
  }

  Future<void> _pickCapturedAt() async {
    final DateTime initial = _capturedAt;
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1970),
      lastDate: DateTime(2100),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: kAccentYellow,
              onPrimary: Colors.black,
              surface: Color(0xFF1E1E1E),
              onSurface: Colors.white,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (pickedDate == null || !mounted) return;

    final TimeOfDay initialTime = TimeOfDay.fromDateTime(initial);
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: kAccentYellow,
              onPrimary: Colors.black,
              surface: Color(0xFF1E1E1E),
              onSurface: Colors.white,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (pickedTime == null || !mounted) return;

    setState(() {
      _capturedAt = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _save() async {
    final String titleTrim = _titleController.text.trim();
    if (titleTrim.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('请填写作品标题'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.white.withOpacity(0.14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final String? tempPath = _tempPickedImagePath;
    final String? existingAbs = _existingImageAbsolutePath;
    if (tempPath == null &&
        (existingAbs == null || !File(existingAbs).existsSync())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('请先上传作品图片'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.white.withOpacity(0.14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    String imageRelative = widget.initial?.imageRelativePath.trim() ?? '';
    if (tempPath != null) {
      if (_isEdit && imageRelative.isNotEmpty) {
        await PortfolioStorage.deleteImageIfExists(imageRelative);
      }
      imageRelative =
          await PortfolioStorage.copyPickedImageToPortfolio(File(tempPath));
    }

    if (imageRelative.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('图片保存失败，请重试'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.white.withOpacity(0.14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final String id = widget.initial?.id ??
        DateTime.now().millisecondsSinceEpoch.toString();

    final PortfolioItem saved = PortfolioItem(
      id: id,
      imageRelativePath: imageRelative,
      title: titleTrim,
      content: _contentController.text.trim(),
      location: _locationController.text.trim(),
      capturedAt: _capturedAt,
    );

    await PortfolioStorage.upsert(saved);

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final String? previewPath = _tempPickedImagePath ?? _existingImageAbsolutePath;

    return Scaffold(
      backgroundColor: kBackgroundBlack,
      appBar: AppBar(
        title: Text(_isEdit ? '编辑作品' : '添加作品'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kAccentYellow))
          : SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                MediaQuery.of(context).padding.bottom + 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '作品图片',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.72),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _pickImage,
                    child: AspectRatio(
                      aspectRatio: 4 / 3,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          color: Colors.white.withOpacity(0.06),
                          child: previewPath != null && File(previewPath).existsSync()
                              ? Image.file(
                                  File(previewPath),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  errorBuilder:
                                      (context, error, stackTrace) =>
                                          _buildImagePlaceholder(),
                                )
                              : _buildImagePlaceholder(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      '点击上传或更换图片',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.42),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '标题',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.72),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GlassPanel(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    borderRadius: 16,
                    blurSigma: 16,
                    child: TextField(
                      controller: _titleController,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: '给你的作品起个标题',
                        hintStyle:
                            TextStyle(color: Colors.white.withOpacity(0.35)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '内容',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.72),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GlassPanel(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    borderRadius: 16,
                    blurSigma: 16,
                    child: TextField(
                      controller: _contentController,
                      maxLines: 6,
                      minLines: 4,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 15, height: 1.4),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        alignLabelWithHint: true,
                        hintText: '说说这张照片的故事、参数或氛围……',
                        hintStyle:
                            TextStyle(color: Colors.white.withOpacity(0.35)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '地点',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.72),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GlassPanel(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    borderRadius: 16,
                    blurSigma: 16,
                    child: TextField(
                      controller: _locationController,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: '拍摄地点（选填）',
                        hintStyle:
                            TextStyle(color: Colors.white.withOpacity(0.35)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '拍摄时间',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.72),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GlassPanel(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    borderRadius: 16,
                    blurSigma: 16,
                    child: InkWell(
                      onTap: _pickCapturedAt,
                      borderRadius: BorderRadius.circular(12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_month_rounded,
                            color: kAccentYellow.withOpacity(0.9),
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _formatCapturedLabel(_capturedAt),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.92),
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
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
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: _save,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        '保存',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_outlined,
          size: 56,
          color: kAccentYellow.withOpacity(0.75),
        ),
        const SizedBox(height: 12),
        Text(
          '点击选择照片',
          style: TextStyle(
            color: Colors.white.withOpacity(0.45),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
