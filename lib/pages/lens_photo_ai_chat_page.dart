import 'package:flutter/material.dart';

import '../constants/coin_rules.dart';
import '../services/zhipu_chat_service.dart';
import '../theme/huaxing_theme.dart';
import '../utils/lens_ai_chat_storage.dart';
import '../utils/vip_membership_storage.dart';
import '../utils/wallet_coin_storage.dart';
import '../widgets/glass_ui.dart';
import 'wallet_page.dart';

class _ChatTurn {
  _ChatTurn({
    required this.isUser,
    required this.text,
    required this.atMillis,
  });

  final bool isUser;
  final String text;
  final int atMillis;
}

class LensPhotoAiChatPage extends StatefulWidget {
  const LensPhotoAiChatPage({super.key});

  @override
  State<LensPhotoAiChatPage> createState() => _LensPhotoAiChatPageState();
}

class _LensPhotoAiChatPageState extends State<LensPhotoAiChatPage> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final ZhipuChatService _api = ZhipuChatService();

  List<_ChatTurn> _turns = <_ChatTurn>[];
  bool _busy = false;
  bool _hydrating = true;
  int _balance = 0;
  bool _isVip = false;

  static const List<String> _presetQuestions = <String>[
    '夜景长曝怎么设置相机？',
    '人像焦段与环境怎么选？',
    'ND滤镜白天慢门怎么用？',
    '星空银河拍摄要点？',
    '街拍快门与对焦建议？',
    '逆光人像如何测光？',
    '建筑摄影透视校正怎么做？',
    '风光摄影黄金时段怎么把握？',
  ];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    List<LensAiChatTurn> loaded = await LensAiChatStorage.loadTurns();
    final bool vip = await VipMembershipStorage.isVip();
    final int bal = await WalletCoinStorage.loadBalance();
    if (!mounted) return;
    if (loaded.isEmpty) {
      final int now = DateTime.now().millisecondsSinceEpoch;
      loaded = <LensAiChatTurn>[
        LensAiChatTurn(
          isUser: false,
          text: LensAiChatStorage.kDefaultWelcome,
          atMillis: now,
        ),
      ];
      await LensAiChatStorage.saveTurns(loaded);
    }
    if (!mounted) return;
    setState(() {
      _turns = loaded
          .map(
            (LensAiChatTurn e) => _ChatTurn(
              isUser: e.isUser,
              text: e.text,
              atMillis: e.atMillis,
            ),
          )
          .toList();
      _isVip = vip;
      _balance = bal;
      _hydrating = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottomSoon());
  }

  Future<void> _persistTurns() async {
    await LensAiChatStorage.saveTurns(
      _turns
          .map(
            (_ChatTurn t) => LensAiChatTurn(
              isUser: t.isUser,
              text: t.text,
              atMillis: t.atMillis,
            ),
          )
          .toList(),
    );
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    final String trimmed = text.trim();
    if (trimmed.isEmpty || _busy || _hydrating) return;

    final bool isVip = await VipMembershipStorage.isVip();
    final int cost = CoinRules.consultationCoinsForVipFlag(isVip);
    if (!mounted) return;

    final bool spent = await WalletCoinStorage.trySpend(cost);
    if (!spent) {
      if (!mounted) return;
      setState(() {
        _isVip = isVip;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('花杏币不足，本次咨询需要 $cost 花杏币'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.white.withOpacity(0.14),
          action: SnackBarAction(
            label: '去充值',
            textColor: kAccentYellow,
            onPressed: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (BuildContext context) => const WalletPage(),
                ),
              );
            },
          ),
        ),
      );
      return;
    }

    final int balAfter = await WalletCoinStorage.loadBalance();
    if (!mounted) return;
    setState(() {
      _isVip = isVip;
      _balance = balAfter;
    });

    final int now = DateTime.now().millisecondsSinceEpoch;
    setState(() {
      _busy = true;
      _turns.add(_ChatTurn(isUser: true, text: trimmed, atMillis: now));
    });
    await _persistTurns();
    _input.clear();
    _scrollToBottomSoon();

    try {
      final List<Map<String, String>> history = <Map<String, String>>[];
      for (final _ChatTurn t in _turns.skip(1)) {
        history.add(<String, String>{
          'role': t.isUser ? 'user' : 'assistant',
          'content': t.text,
        });
      }

      final String reply = await _api.completeChat(messages: history);
      if (!mounted) return;
      final int replyAt = DateTime.now().millisecondsSinceEpoch;
      setState(() {
        _turns.add(_ChatTurn(isUser: false, text: reply, atMillis: replyAt));
      });
      await _persistTurns();
    } catch (e) {
      await WalletCoinStorage.creditCoins(cost);
      final int refundedBal = await WalletCoinStorage.loadBalance();
      if (!mounted) return;
      final int errAt = DateTime.now().millisecondsSinceEpoch;
      setState(() {
        _balance = refundedBal;
        _turns.add(
          _ChatTurn(
            isUser: false,
            text: '抱歉，暂时无法连接模型：$e\n请检查网络或稍后再试。\n（本次已退还 $cost 花杏币）',
            atMillis: errAt,
          ),
        );
      });
      await _persistTurns();
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
      _scrollToBottomSoon();
    }
  }

  void _scrollToBottomSoon() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final double bottom = MediaQuery.of(context).padding.bottom;

    if (_hydrating) {
      return Scaffold(
        backgroundColor: kBackgroundBlack,
        appBar: AppBar(
          title: const Text('AI 摄影咨询'),
          leading: IconButton(
            icon:
                const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(child: CircularProgressIndicator(color: kAccentYellow)),
      );
    }

    return Scaffold(
      backgroundColor: kBackgroundBlack,
      appBar: AppBar(
        title: const Text('AI 摄影咨询'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: GlassPanel(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              borderRadius: 16,
              blurSigma: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        size: 17,
                        color: kAccentYellow.withOpacity(0.95),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '快捷提问',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.68),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '余额 $_balance 花杏币',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.72),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '·',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.35),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '每次 ${CoinRules.consultationCoinsForVipFlag(_isVip)} 花杏币',
                        style: TextStyle(
                          color: kAccentYellow.withOpacity(0.92),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (_isVip) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: kAccentYellow.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: kAccentYellow.withOpacity(0.45),
                            ),
                          ),
                          child: const Text(
                            'VIP 8折',
                            style: TextStyle(
                              color: kAccentYellow,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              itemCount: _presetQuestions.length,
              separatorBuilder: (BuildContext context, int index) =>
                  const SizedBox(width: 8),
              itemBuilder: (BuildContext context, int index) {
                final String question = _presetQuestions[index];
                return ActionChip(
                  label: Text(
                    question,
                    style: const TextStyle(fontSize: 12.5),
                  ),
                  onPressed: _busy ? null : () => _sendMessage(question),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  backgroundColor: Colors.white.withOpacity(0.08),
                  side: BorderSide(color: Colors.white.withOpacity(0.14)),
                  labelStyle: TextStyle(color: Colors.white.withOpacity(0.9)),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                );
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              itemCount: _turns.length + (_busy ? 1 : 0),
              itemBuilder: (BuildContext context, int index) {
                if (_busy && index == _turns.length) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: GlassPanel(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        borderRadius: 16,
                        blurSigma: 14,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: kAccentYellow.withOpacity(0.9),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '正在回复…',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.55),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                final _ChatTurn turn = _turns[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Align(
                    alignment: turn.isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.86,
                      ),
                      child: GlassPanel(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 11,
                        ),
                        borderRadius: 18,
                        blurSigma: turn.isUser ? 12 : 14,
                        fillOpacityHigh: turn.isUser ? 0.14 : 0.1,
                        child: Text(
                          turn.text,
                          style: TextStyle(
                            color: Colors.white.withOpacity(
                              turn.isUser ? 0.94 : 0.88,
                            ),
                            fontSize: 14,
                            height: 1.42,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(12, 4, 12, bottom + 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: GlassPanel(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
                    borderRadius: 22,
                    blurSigma: 16,
                    child: TextField(
                      controller: _input,
                      enabled: !_busy,
                      maxLines: 4,
                      minLines: 1,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: '输入你的摄影问题…',
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.35),
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(_input.text),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Material(
                  color: _busy ? Colors.white24 : kAccentYellow,
                  borderRadius: BorderRadius.circular(22),
                  child: InkWell(
                    onTap: _busy ? null : () => _sendMessage(_input.text),
                    borderRadius: BorderRadius.circular(22),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Icon(
                        Icons.send_rounded,
                        color: _busy ? Colors.white38 : Colors.black,
                        size: 22,
                      ),
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
