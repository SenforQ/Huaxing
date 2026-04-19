import 'dart:io';

import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:path/path.dart' as p;

import '../models/portfolio_item.dart';
import '../theme/huaxing_theme.dart';
import '../utils/portfolio_storage.dart';
import '../utils/profile_storage.dart';
import '../utils/vip_membership_storage.dart';
import '../utils/wallet_coin_storage.dart';
import '../widgets/glass_ui.dart';
import 'editor_page.dart';
import 'portfolio_edit_page.dart';
import 'about_page.dart';
import 'feedback_page.dart';
import 'privacy_policy_page.dart';
import 'user_agreement_page.dart';
import 'vip_page.dart';
import 'wallet_page.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  bool _loadingProfile = true;
  String _nickname = ProfileStorage.defaultNickname;
  String _signature = '';
  String? _avatarAbsolutePath;
  String _applicationDocumentsPath = '';
  List<PortfolioItem> _portfolioItems = <PortfolioItem>[];
  int _coinBalance = 0;
  bool _isVip = false;

  @override
  void initState() {
    super.initState();
    _reloadProfile();
  }

  Future<void> _reloadProfile() async {
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
    final List<PortfolioItem> portfolioList =
        await PortfolioStorage.loadValidSortedNewestFirst();
    final int coins = await WalletCoinStorage.loadBalance();
    final bool vip = await VipMembershipStorage.isVip();
    if (!mounted) return;
    setState(() {
      _nickname = state.nickname;
      _signature = state.signature;
      _avatarAbsolutePath = abs;
      _applicationDocumentsPath = doc.path;
      _portfolioItems = portfolioList;
      _coinBalance = coins;
      _isVip = vip;
      _loadingProfile = false;
    });
  }

  Future<void> _reloadCoinBalance() async {
    final int coins = await WalletCoinStorage.loadBalance();
    if (!mounted) return;
    setState(() => _coinBalance = coins);
  }

  Future<void> _reloadVipStatus() async {
    final bool vip = await VipMembershipStorage.isVip();
    if (!mounted) return;
    setState(() => _isVip = vip);
  }

  @override
  Widget build(BuildContext context) {
    final double bottom = MediaQuery.of(context).padding.bottom + 88;
    if (_loadingProfile) {
      return const Center(
        child: CircularProgressIndicator(color: kAccentYellow),
      );
    }
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: GlassPanel(
              padding: const EdgeInsets.all(18),
              borderRadius: 24,
              blurSigma: 22,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 86,
                    height: 86,
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
                      child: _avatarAbsolutePath != null &&
                              File(_avatarAbsolutePath!).existsSync()
                          ? Image.file(
                              File(_avatarAbsolutePath!),
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            )
                          : Image.asset(
                              'assets/user_default.png',
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stack) {
                                return Container(
                                  color: const Color(0xFF1E1E1E),
                                  alignment: Alignment.center,
                                  child: Icon(Icons.person_rounded, size: 44, color: Colors.white.withOpacity(0.7)),
                                );
                              },
                            ),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _nickname,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 22,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _signature.trim().isEmpty ? '暂无设置个性签名' : _signature,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.58),
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
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: GlassPanel(
              padding: const EdgeInsets.symmetric(vertical: 18),
              borderRadius: 20,
              blurSigma: 18,
              child: Row(
                children: [
                  Expanded(
                    child: _StatBlock(
                      value: '${_portfolioItems.length}',
                      label: '作品',
                    ),
                  ),
                  Container(width: 1, height: 38, color: Colors.white.withOpacity(0.12)),
                  Expanded(
                    child: _StatBlock(value: '0', label: '获赞'),
                  ),
                  Container(width: 1, height: 38, color: Colors.white.withOpacity(0.12)),
                  Expanded(
                    child: _StatBlock(value: '0', label: '粉丝'),
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: _SectionTitleRow(title: '账户与资产'),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GlassPanel(
              padding: EdgeInsets.zero,
              borderRadius: 18,
              blurSigma: 18,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ProfileMenuTile(
                    icon: Icons.account_balance_wallet_rounded,
                    title: '我的钱包',
                    valueText: '$_coinBalance 花杏币',
                    showDividerBelow: true,
                    onTap: () async {
                      await Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (BuildContext context) => const WalletPage(),
                        ),
                      );
                      await _reloadCoinBalance();
                    },
                  ),
                  _ProfileMenuTile(
                    icon: Icons.workspace_premium_rounded,
                    title: '开通VIP',
                    valueText: _isVip ? '已开通' : '未开通',
                    showDividerBelow: false,
                    onTap: () async {
                      await Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (BuildContext context) => const VipPage(),
                        ),
                      );
                      await _reloadVipStatus();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: _SectionTitleRow(title: '资料编辑'),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GlassPanel(
              padding: EdgeInsets.zero,
              borderRadius: 18,
              blurSigma: 18,
              child: _ProfileMenuTile(
                icon: Icons.edit_note_rounded,
                title: '编辑资料',
                onTap: () async {
                  final saved = await Navigator.of(context).push<bool>(
                    MaterialPageRoute<bool>(
                      builder: (context) => const EditorPage(),
                    ),
                  );
                  if (saved == true && mounted) {
                    await _reloadProfile();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('资料已保存'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Colors.white.withOpacity(0.14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  }
                },
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: _SectionTitleRow(title: '推荐与反馈'),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GlassPanel(
              padding: EdgeInsets.zero,
              borderRadius: 18,
              blurSigma: 18,
              child: Column(
                children: [
                  _ProfileMenuTile(
                    icon: Icons.star_rate_rounded,
                    title: '给个好评',
                    showDividerBelow: true,
                    onTap: () async {
                      final InAppReview inAppReview = InAppReview.instance;
                      if (await inAppReview.isAvailable()) {
                        await inAppReview.requestReview();
                        return;
                      }
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('当前无法唤起系统评分（可能受系统次数限制，或须真机已安装应用）'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Colors.white.withOpacity(0.14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    },
                  ),
                  _ProfileMenuTile(
                    icon: Icons.feedback_outlined,
                    title: '意见反馈',
                    showDividerBelow: false,
                    onTap: () async {
                      final submitted = await Navigator.of(context).push<bool>(
                        MaterialPageRoute<bool>(
                          builder: (context) => const FeedbackPage(),
                        ),
                      );
                      if (submitted == true && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('提交成功'),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: Colors.white.withOpacity(0.14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: _SectionTitleRow(title: '协议与关于'),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GlassPanel(
              padding: EdgeInsets.zero,
              borderRadius: 18,
              blurSigma: 18,
              child: Column(
                children: [
                  _ProfileMenuTile(
                    icon: Icons.privacy_tip_outlined,
                    title: '隐私政策',
                    showDividerBelow: true,
                    onTap: () {
                      Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (context) => const PrivacyPolicyPage(),
                        ),
                      );
                    },
                  ),
                  _ProfileMenuTile(
                    icon: Icons.article_outlined,
                    title: '用户协议',
                    showDividerBelow: true,
                    onTap: () {
                      Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (context) => const UserAgreementPage(),
                        ),
                      );
                    },
                  ),
                  _ProfileMenuTile(
                    icon: Icons.info_outline_rounded,
                    title: '关于我们',
                    showDividerBelow: false,
                    onTap: () {
                      Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (context) => const AboutPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 22, 16, 10),
            child: Row(
              children: [
                Icon(
                  Icons.collections_rounded,
                  color: kAccentYellow.withOpacity(0.9),
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  '作品集',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.92),
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
                const Spacer(),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      final bool? saved = await Navigator.of(context)
                          .push<bool>(
                        MaterialPageRoute<bool>(
                          builder: (BuildContext context) =>
                              const PortfolioEditPage(),
                        ),
                      );
                      if (saved == true && mounted) {
                        await _reloadProfile();
                      }
                    },
                    borderRadius: BorderRadius.circular(22),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        Icons.add_rounded,
                        color: kAccentYellow.withOpacity(0.95),
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 10)),
        if (_portfolioItems.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(12, 0, 12, bottom),
              child: GlassPanel(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 32),
                borderRadius: 18,
                blurSigma: 18,
                child: Column(
                  children: [
                    Icon(
                      Icons.photo_camera_outlined,
                      size: 52,
                      color: kAccentYellow.withOpacity(0.88),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      '暂无作品',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.92),
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '还没有摄影作品，快去添加你的摄影作品，把值得记住的画面留在这里。',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.48),
                        fontSize: 14,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: EdgeInsets.fromLTRB(12, 0, 12, bottom),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final PortfolioItem item = _portfolioItems[index];
                  final String fullPath = p.join(
                    _applicationDocumentsPath,
                    item.imageRelativePath,
                  );
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        final bool? saved =
                            await Navigator.of(context).push<bool>(
                          MaterialPageRoute<bool>(
                            builder: (BuildContext context) => PortfolioEditPage(
                              initial: item,
                            ),
                          ),
                        );
                        if (saved == true && mounted) {
                          await _reloadProfile();
                        }
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(
                          File(fullPath),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stack) {
                            return Container(
                              color: Colors.white.withOpacity(0.06),
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.broken_image_outlined,
                                color: Colors.white.withOpacity(0.35),
                                size: 28,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
                childCount: _portfolioItems.length,
              ),
            ),
          ),
      ],
    );
  }
}

class _SectionTitleRow extends StatelessWidget {
  const _SectionTitleRow({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: kAccentYellow,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withOpacity(0.88),
            fontWeight: FontWeight.w700,
            fontSize: 15,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  const _ProfileMenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.showDividerBelow = false,
    this.valueText,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool showDividerBelow;
  final String? valueText;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: kAccentYellow.withOpacity(0.12),
        highlightColor: kAccentYellow.withOpacity(0.06),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white.withOpacity(0.08),
                        border: Border.all(color: Colors.white.withOpacity(0.12)),
                      ),
                      child: Icon(icon, color: kAccentYellow.withOpacity(0.95), size: 22),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (valueText != null) ...[
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        valueText!,
                        style: const TextStyle(
                          color: kAccentYellow,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white.withOpacity(0.38),
                    size: 26,
                  ),
                ],
              ),
            ),
            if (showDividerBelow)
              Padding(
                padding: const EdgeInsets.only(left: 68),
                child: Divider(height: 1, thickness: 1, color: Colors.white.withOpacity(0.08)),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: kAccentYellow,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.52),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
