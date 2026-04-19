import 'package:flutter/material.dart';

import '../theme/huaxing_theme.dart';
import '../utils/chat_peer_storage.dart';
import '../widgets/glass_ui.dart';

class ChatConversationPage extends StatefulWidget {
  const ChatConversationPage({
    super.key,
    required this.peerUserName,
    required this.peerAvatarUrl,
  });

  final String peerUserName;
  final String peerAvatarUrl;

  @override
  State<ChatConversationPage> createState() => _ChatConversationPageState();
}

class _ChatConversationPageState extends State<ChatConversationPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatDmEntry> _messages = <ChatDmEntry>[];
  bool _awaitingReply = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final List<ChatDmEntry> list =
        await ChatPeerStorage.loadMessages(widget.peerUserName);
    final bool awaitReply =
        await ChatPeerStorage.awaitingTheirReply(widget.peerUserName);
    if (!mounted) return;
    setState(() {
      _messages = list;
      _awaitingReply = awaitReply;
      _loading = false;
    });
    if (list.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_scrollController.hasClients) {
          _scrollController
              .jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final String text = _controller.text.trim();
    if (text.isEmpty) return;

    if (_awaitingReply) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('请等待对方回复后再发送'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.white.withOpacity(0.14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    await ChatPeerStorage.appendOutgoing(widget.peerUserName, text);
    _controller.clear();
    await _bootstrap();
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final double bottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: kBackgroundBlack,
      appBar: AppBar(
        title: Text(
          widget.peerUserName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: kAccentYellow))
                : _messages.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 36),
                          child: Text(
                            '发送消息开启对话\n对方可能不会即时回复',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.45),
                              fontSize: 15,
                              height: 1.45,
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                        itemCount: _messages.length,
                        itemBuilder: (BuildContext context, int index) {
                          final ChatDmEntry m = _messages[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.72,
                                ),
                                child: GlassPanel(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                  borderRadius: 18,
                                  blurSigma: 14,
                                  child: Text(
                                    m.text,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.92),
                                      fontSize: 15,
                                      height: 1.38,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
          if (_awaitingReply && _messages.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                '等待对方回复后可继续发送',
                style: TextStyle(
                  color: kAccentYellow.withOpacity(0.85),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(12, 6, 12, bottom + 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: GlassPanel(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    borderRadius: 22,
                    blurSigma: 16,
                    child: TextField(
                      controller: _controller,
                      maxLines: 4,
                      minLines: 1,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: '输入消息…',
                        hintStyle:
                            TextStyle(color: Colors.white.withOpacity(0.35)),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Material(
                  color: kAccentYellow,
                  borderRadius: BorderRadius.circular(22),
                  child: InkWell(
                    onTap: _send,
                    borderRadius: BorderRadius.circular(22),
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Icon(Icons.send_rounded, color: Colors.black, size: 22),
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
