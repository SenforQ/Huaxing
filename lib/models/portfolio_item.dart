class PortfolioItem {
  const PortfolioItem({
    required this.id,
    required this.imageRelativePath,
    required this.title,
    required this.content,
    required this.location,
    required this.capturedAt,
  });

  final String id;
  final String imageRelativePath;
  final String title;
  final String content;
  final String location;
  final DateTime capturedAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'imageRelativePath': imageRelativePath,
      'title': title,
      'content': content,
      'location': location,
      'capturedAt': capturedAt.toIso8601String(),
    };
  }

  factory PortfolioItem.fromJson(Map<String, dynamic> json) {
    final String? rawTime = json['capturedAt'] as String?;
    DateTime at = DateTime.now();
    if (rawTime != null && rawTime.isNotEmpty) {
      try {
        at = DateTime.parse(rawTime);
      } catch (_) {}
    }
    return PortfolioItem(
      id: json['id'] as String? ?? '',
      imageRelativePath: json['imageRelativePath'] as String? ?? '',
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      location: json['location'] as String? ?? '',
      capturedAt: at,
    );
  }

  PortfolioItem copyWith({
    String? id,
    String? imageRelativePath,
    String? title,
    String? content,
    String? location,
    DateTime? capturedAt,
  }) {
    return PortfolioItem(
      id: id ?? this.id,
      imageRelativePath: imageRelativePath ?? this.imageRelativePath,
      title: title ?? this.title,
      content: content ?? this.content,
      location: location ?? this.location,
      capturedAt: capturedAt ?? this.capturedAt,
    );
  }
}
