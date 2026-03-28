import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AvatarWidget extends StatelessWidget {
  final String? base64Image;
  final String fallbackLetter;
  final double radius;
  final Color? borderColor;
  final bool hasActiveStory;

  const AvatarWidget({
    super.key,
    required this.fallbackLetter,
    required this.radius,
    this.base64Image,
    this.borderColor,
    this.hasActiveStory = false,
  });

  @override
  Widget build(BuildContext context) {
    final totalSize = radius * 2 + (hasActiveStory ? 6 : 0);

    return SizedBox(
      width: totalSize,
      height: totalSize,
      child: Stack(
        children: [
          if (hasActiveStory)
            Container(
              width: radius * 2 + 6,
              height: radius * 2 + 6,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF6C63FF),
                    Color(0xFFFF6584),
                    Color(0xFFFFB347),
                  ],
                ),
              ),
            ),
          Positioned(
            top: hasActiveStory ? 3 : 0,
            left: hasActiveStory ? 3 : 0,
            child: CircleAvatar(
              radius: radius,
              backgroundColor: borderColor ?? const Color(0xFF6C63FF),
              backgroundImage: base64Image != null
                  ? MemoryImage(base64Decode(base64Image!))
                  : null,
              child: base64Image == null
                  ? Text(
                      fallbackLetter.isEmpty
                          ? 'S'
                          : fallbackLetter[0].toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: radius * 0.7,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
