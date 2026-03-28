class Student {
  final String id;
  final String email;
  final List<String> studySubjects;
  final String learningStyle;
  final int score;
  final bool isStudyingNow;
  final bool isStudying;
  final String? studyLocation;
  final String? username;
  final String? avatarBase64;
  final int followersCount;
  final bool hasActiveStory;

  Student({
    required this.id,
    required this.email,
    required this.studySubjects,
    required this.learningStyle,
    required this.score,
    required this.isStudyingNow,
    required this.isStudying,
    this.studyLocation,
    this.username,
    this.avatarBase64,
    this.followersCount = 0,
    this.hasActiveStory = false,
  });

  String get displayName {
    if (username != null) return '@$username';
    return email.split('@').first;
  }

  String get emailDomain => email.contains('@') ? email.split('@').last : '';

  factory Student.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>;
    return Student(
      id: user['id'] as String,
      email: user['email'] as String,
      studySubjects: List<String>.from(user['study_subjects'] ?? []),
      learningStyle: user['learning_style'] ?? 'Non specificato',
      score: json['score'] as int? ?? 0,
      isStudyingNow: (json['is_studying_now'] == true) ||
          (json['has_active_session'] == true) ||
          (user['is_studying_now'] == true) ||
          (user['has_active_session'] == true),
      isStudying: json['is_studying'] as bool? ?? false,
      studyLocation: json['study_location'] as String?,
      username: (json['username'] ?? user['username']) as String?,
      avatarBase64: (json['avatar_base64'] ?? user['avatar_base64']) as String?,
      followersCount: (json['followers_count'] ?? user['followers_count'] ?? 0) as int,
      hasActiveStory: (json['has_active_story'] ?? user['has_active_story'] ?? false) as bool,
    );
  }
}
