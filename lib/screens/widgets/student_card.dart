import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/student.dart';
import 'avatar_widget.dart';

// Design system
const _surfaceHigh = Color(0xFF2A2A2A);
const _primary = Color(0xFFC4C0FF);
const _primaryDark = Color(0xFF8781FF);
const _secondary = Color(0xFF5CDBC0);

class StudentCard extends StatelessWidget {
  const StudentCard({super.key, required this.student});

  final Student student;

  static const List<Color> _tagColors = [
    Color(0xFFC4C0FF),
    Color(0xFF5CDBC0),
    Color(0xFFFFB347),
    Color(0xFFFF6584),
    Color(0xFF56CCF2),
  ];

  String _prettyName(String raw) {
    if (raw.isEmpty) return 'Studente';
    if (raw.startsWith('@')) return raw.replaceFirst('@', '').split('_').first;
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

  @override
  Widget build(BuildContext context) {
    final rawName = student.username ?? student.email.split('@').first;
    final name = _prettyName(rawName);
    final univ = _universityFromDomain(student.emailDomain);
    final fallbackLetter = rawName.isNotEmpty ? rawName[0] : 'S';

    final isLib = student.learningStyle != 'Rumoroso';
    final styleLabel = isLib ? '📖 Library Regular' : '🎧 Cafè & Noise';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(48),
        color: _surfaceHigh,
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.08),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [0, 0.6, 1],
                colors: [
                  Color(0xFF1C1B2E),
                  Color(0xFF1A1A2A),
                  Color(0xFF0E0E18),
                ],
              ),
            ),
          ),

          // Accent glow top-right
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _primaryDark.withValues(alpha: 0.07),
              ),
            ),
          ),

          // Main content
          Column(
            children: [
              // Avatar area — top 55%
              Expanded(
                flex: 55,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                    child: AvatarWidget(
                      base64Image: student.avatarBase64,
                      fallbackLetter: fallbackLetter,
                      radius: 80,
                      hasActiveStory: student.hasActiveStory,
                    ),
                  ),
                ),
              ),

              // Info area — bottom 45%
              Expanded(
                flex: 45,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name
                      Text(
                        name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // @username
                      if (student.username != null)
                        Text(
                          '@${student.username}',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 14,
                            color: _secondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      const SizedBox(height: 6),
                      // University
                      Row(
                        children: [
                          const Icon(Icons.school_outlined,
                              size: 13, color: Colors.white38),
                          const SizedBox(width: 4),
                          Text(
                            univ,
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 13,
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Subject chips
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: student.studySubjects
                            .take(3)
                            .toList()
                            .asMap()
                            .entries
                            .map((e) {
                          final color =
                              _tagColors[e.key % _tagColors.length];
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            child: Text(
                              e.value,
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 12,
                                color: color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const Spacer(),
                      // Style badge + score
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _primary.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            child: Text(
                              styleLabel,
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 12,
                                color: _primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _secondary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            child: Text(
                              '${student.score}% match',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 12,
                                color: _secondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // STUDIA ORA badge
          if (student.isStudying)
            Positioned(
              top: 20,
              left: 20,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                          color: _secondary, shape: BoxShape.circle),
                    )
                        .animate(onPlay: (c) => c.repeat())
                        .fadeOut(duration: 800.ms)
                        .then()
                        .fadeIn(duration: 800.ms),
                    const SizedBox(width: 6),
                    Text(
                      '✦ STUDIA ORA',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 11,
                        color: _secondary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Story ring indicator (top right)
          if (student.hasActiveStory)
            Positioned(
              top: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _primary.withValues(alpha: 0.15),
                ),
                child: const Icon(Icons.auto_stories_rounded,
                    size: 14, color: _primary),
              ),
            ),
        ],
      ),
    );
  }
}
