class FeedComment {
  const FeedComment({
    required this.id,
    required this.authorName,
    required this.text,
    required this.createdAtMillis,
    this.authorAvatarRelativePath,
  });

  final String id;
  final String authorName;
  final String text;
  final int createdAtMillis;
  final String? authorAvatarRelativePath;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'authorName': authorName,
      'text': text,
      'createdAtMillis': createdAtMillis,
      if (authorAvatarRelativePath != null &&
          authorAvatarRelativePath!.trim().isNotEmpty)
        'authorAvatarRelativePath': authorAvatarRelativePath!.trim(),
    };
  }

  factory FeedComment.fromJson(Map<String, dynamic> json) {
    final Object? rawRel = json['authorAvatarRelativePath'];
    final String? rel = rawRel is String ? rawRel.trim() : null;
    return FeedComment(
      id: json['id'] as String? ?? '',
      authorName: json['authorName'] as String? ?? '',
      text: json['text'] as String? ?? '',
      createdAtMillis: json['createdAtMillis'] as int? ?? 0,
      authorAvatarRelativePath:
          rel != null && rel.isNotEmpty ? rel : null,
    );
  }
}
