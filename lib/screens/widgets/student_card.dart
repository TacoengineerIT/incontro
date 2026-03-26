import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../models/student.dart';

class StudentCard extends StatelessWidget {
  const StudentCard({super.key, required this.student});

  final Student student;

  static const _accent = Color(0xFF6C63FF);
  static const _bg = Color(0xFF1A1A2E);

  static const List<Color> _tagColors = [
    Color(0xFF6C63FF),
    Color(0xFFFF6584),
    Color(0xFF43C6AC),
    Color(0xFFFFB347),
    Color(0xFF56CCF2),
  ];

  String _prettyName(String raw) {
    if (raw.isEmpty) return 'Studente';
    return raw[0].toUpperCase() + raw.substring(1);
  }

  String _universityFromDomain(String domain) {
    final d = domain.toLowerCase();
    const map = <String, String>{
      'unina.it': 'Univ. Federico II',
      'unipi.it': 'Univ. di Pisa',
      'unibo.it': 'Univ. di Bologna',
      'uniroma1.it': 'Sapienza',
      'polimi.it': 'Politecnico di Milano',
      'polito.it': 'Politecnico di Torino',
    };
    if (map.containsKey(d)) return map[d]!;
    if (d.isEmpty) return 'Università';
    return 'Univ. $domain';
  }

  Widget _compatBar(int score) {
    final v = (score / 100).clamp(0.0, 1.0);
    final color = Color.lerp(const Color(0xFFFF6B6B), const Color(0xFF43C6AC), v)!;
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 10,
        color: Colors.white.withValues(alpha: 0.08),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: v,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.95),
                    color.withValues(alpha: 0.55),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = _prettyName(student.displayName);
    final univ = _universityFromDomain(student.emailDomain);

    final styleIcon = student.learningStyle == 'Rumoroso'
        ? Icons.headphones_rounded
        : Icons.menu_book_rounded;
    final styleText =
        student.learningStyle == 'Rumoroso' ? '🎧 Rumoroso' : '📚 Silenzioso';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _bg,
            const Color(0xFF16213E).withValues(alpha: 0.95),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: _accent.withValues(alpha: 0.22),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6C63FF), Color(0xFFFF6B6B)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6C63FF).withValues(alpha: 0.35),
                        blurRadius: 18,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      name[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        univ,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.58),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(styleIcon, color: _accent, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            styleText,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.72),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (student.isStudyingNow)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: const Color(0xFF2ECC71).withValues(alpha: 0.18),
                  border: Border.all(
                    color: const Color(0xFF2ECC71).withValues(alpha: 0.28),
                  ),
                ),
                child: const Text(
                  '🟢 Studia ora',
                  style: TextStyle(
                    color: Color(0xFF2ECC71),
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              )
                  .animate(onPlay: (c) => c.repeat())
                  .fadeIn(duration: 500.ms)
                  .fadeOut(duration: 700.ms),
            if (student.isStudyingNow) const SizedBox(height: 14),
            Text(
              'MATERIE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Colors.white.withValues(alpha: 0.38),
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: student.studySubjects.asMap().entries.map((entry) {
                final color = _tagColors[entry.key % _tagColors.length];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    entry.value,
                    style: TextStyle(
                      fontSize: 13,
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              }).toList(),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: _accent.withValues(alpha: 0.12),
                border: Border.all(color: _accent.withValues(alpha: 0.20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome_rounded, color: _accent, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Compatibilità',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.80),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${student.score}%',
                        style: const TextStyle(
                          color: _accent,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _compatBar(student.score),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}