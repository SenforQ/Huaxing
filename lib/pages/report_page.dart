import 'package:flutter/material.dart';

import '../theme/huaxing_theme.dart';
import '../widgets/glass_ui.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({
    super.key,
    required this.postId,
    required this.userName,
    this.previewCaption,
  });

  final String postId;
  final String userName;
  final String? previewCaption;

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final TextEditingController _detailController = TextEditingController();
  String _category = '垃圾广告';

  static const List<String> _categories = <String>[
    '垃圾广告',
    '色情低俗',
    '诈骗信息',
    '侵权内容',
    '违规违法',
    '其他',
  ];

  @override
  void dispose() {
    _detailController.dispose();
    super.dispose();
  }

  void _submit() {
    final String detail = _detailController.text.trim();
    if (detail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('请填写举报说明'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.white.withOpacity(0.14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(
        content: const Text('已收到举报，我们会尽快处理'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.white.withOpacity(0.14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundBlack,
      appBar: AppBar(
        title: const Text('举报'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          MediaQuery.of(context).padding.bottom + 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GlassPanel(
              padding: const EdgeInsets.all(16),
              borderRadius: 18,
              blurSigma: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '被举报对象',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.55),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '动态 ID：${widget.postId}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.42),
                      fontSize: 12,
                    ),
                  ),
                  if (widget.previewCaption != null &&
                      widget.previewCaption!.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      widget.previewCaption!.trim(),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.72),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 22),
            Text(
              '举报类型',
              style: TextStyle(
                color: Colors.white.withOpacity(0.72),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final String c in _categories)
                  ChoiceChip(
                    label: Text(c),
                    selected: _category == c,
                    onSelected: (_) => setState(() => _category = c),
                    selectedColor: kAccentYellow.withOpacity(0.35),
                    labelStyle: TextStyle(
                      color: _category == c ? Colors.black : Colors.white.withOpacity(0.88),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    side: BorderSide(color: Colors.white.withOpacity(0.18)),
                    backgroundColor: Colors.white.withOpacity(0.06),
                  ),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              '举报说明',
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
                controller: _detailController,
                maxLines: 8,
                minLines: 5,
                style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.45),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: '请描述具体情况，便于我们核实…',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.35)),
                ),
              ),
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _submit,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  '提交举报',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
