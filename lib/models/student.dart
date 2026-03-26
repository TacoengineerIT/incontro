class Student {
  final String id;
  final String email;
  final List<String> studySubjects;
  final String learningStyle;
  final int score;
  final bool isStudyingNow;

  Student({
    required this.id,
    required this.email,
    required this.studySubjects,
    required this.learningStyle,
    required this.score,
    required this.isStudyingNow,
  });

  String get displayName => email.split('@').first;
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
    );
  }
}