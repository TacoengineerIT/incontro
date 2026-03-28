class UserProfile {
  final String id;
  final String email;
  final String? username;
  final String? avatarBase64;
  final List<String> studySubjects;
  final String? learningStyle;
  final int followersCount;
  final int followingCount;
  final bool hasActiveStory;
  final bool isVerified;

  UserProfile({
    required this.id,
    required this.email,
    this.username,
    this.avatarBase64,
    required this.studySubjects,
    this.learningStyle,
    required this.followersCount,
    required this.followingCount,
    required this.hasActiveStory,
    required this.isVerified,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      username: json['username'] as String?,
      avatarBase64: json['avatar_base64'] as String?,
      studySubjects: List<String>.from(json['study_subjects'] ?? []),
      learningStyle: json['learning_style'] as String?,
      followersCount: json['followers_count'] as int? ?? 0,
      followingCount: json['following_count'] as int? ?? 0,
      hasActiveStory: json['has_active_story'] as bool? ?? false,
      isVerified: json['is_verified'] as bool? ?? false,
    );
  }
}
