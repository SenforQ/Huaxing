class ChatPreview {
  const ChatPreview({
    required this.id,
    required this.peerName,
    required this.avatarUrl,
    required this.lastMessage,
    required this.timeLabel,
    required this.unread,
    required this.online,
  });

  final String id;
  final String peerName;
  final String avatarUrl;
  final String lastMessage;
  final String timeLabel;
  final int unread;
  final bool online;
}
