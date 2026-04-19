import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import '../theme/huaxing_theme.dart';
import '../utils/profile_storage.dart';
import '../widgets/glass_ui.dart';

class EditorPage extends StatefulWidget {
  const EditorPage({super.key});

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _signatureController = TextEditingController();

  bool _loading = true;
  String? _avatarRelativePath;
  String? _avatarAbsolutePathForDisplay;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    final state = await ProfileStorage.load();
    final doc = await ProfileStorage.documentsDirectory();
    String? abs;
    if (state.avatarRelativePath != null &&
        state.avatarRelativePath!.isNotEmpty) {
      final f = File(p.join(doc.path, state.avatarRelativePath!));
      if (f.existsSync()) {
        abs = f.path;
      }
    }
    if (!mounted) return;
    setState(() {
      _nicknameController.text = state.nickname;
      _signatureController.text = state.signature;
      _avatarRelativePath = state.avatarRelativePath;
      _avatarAbsolutePathForDisplay = abs;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _signatureController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 92,
    );
    if (image == null) return;

    final relativePath =
        await ProfileStorage.savePickedAvatarToSandbox(File(image.path));
    final doc = await ProfileStorage.documentsDirectory();
    final abs = p.join(doc.path, relativePath);

    if (!mounted) return;
    setState(() {
      _avatarRelativePath = relativePath;
      _avatarAbsolutePathForDisplay = abs;
    });
  }

  Future<void> _save() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('昵称不能为空'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.white.withOpacity(0.14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    await ProfileStorage.save(
      nickname: nickname,
      signature: _signatureController.text,
      avatarRelativePath: _avatarRelativePath,
    );

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundBlack,
      appBar: AppBar(
        title: const Text('编辑资料'),
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
                16,
                20,
                MediaQuery.of(context).padding.bottom + 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '头像',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.72),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: GestureDetector(
                      onTap: _pickAvatar,
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
                          child: _avatarAbsolutePathForDisplay != null &&
                                  File(_avatarAbsolutePathForDisplay!).existsSync()
                              ? Image.file(
                                  File(_avatarAbsolutePathForDisplay!),
                                  width: 106,
                                  height: 106,
                                  fit: BoxFit.cover,
                                )
                              : Image.asset(
                                  'assets/user_default.png',
                                  width: 106,
                                  height: 106,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stack) {
                                    return Container(
                                      color: const Color(0xFF1E1E1E),
                                      alignment: Alignment.center,
                                      child: Icon(
                                        Icons.person_rounded,
                                        size: 48,
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      '点击更换头像',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.42),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    '昵称',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.72),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GlassPanel(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    borderRadius: 16,
                    blurSigma: 16,
                    child: TextField(
                      controller: _nicknameController,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: '请输入昵称',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.35)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '个性签名',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.72),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GlassPanel(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    borderRadius: 16,
                    blurSigma: 16,
                    child: TextField(
                      controller: _signatureController,
                      maxLines: 4,
                      minLines: 3,
                      style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        alignLabelWithHint: true,
                        hintText: '介绍一下自己（选填）',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.35)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: _save,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Text('保存', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
