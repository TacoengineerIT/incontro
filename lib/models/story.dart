class Story {
  final String id;
  final String imageBase64;
  final String? caption;
  final double createdAt;
  final String userId;

  Story({
    required this.id,
    required this.imageBase64,
    this.caption,
    required this.createdAt,
    required this.userId,
  });

  bool get isExpired =>
      DateTime.now().millisecondsSinceEpoch / 1000 - createdAt > 86400;

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: json['id'] as String,
      imageBase64: json['image_base64'] as String,
      caption: json['caption'] as String?,
      createdAt: (json['created_at'] as num).toDouble(),
      userId: json['user_id'] as String? ?? '',
    );
  }
}
