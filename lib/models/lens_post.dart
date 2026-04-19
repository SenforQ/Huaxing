class LensPost {
  const LensPost({
    required this.id,
    required this.userName,
    required this.userAvatar,
    required this.userBio,
    required this.location,
    required this.imageUrl,
    required this.caption,
    required this.likes,
    required this.comments,
    required this.shotWith,
  });

  final String id;
  final String userName;
  final String userAvatar;
  final String userBio;
  final String location;
  final String imageUrl;
  final String caption;
  final int likes;
  final int comments;
  final String shotWith;
}
