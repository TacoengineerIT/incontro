import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'widgets/avatar_widget.dart';

// Design system
const _surface = Color(0xFF1E1E1E);
const _surfaceHigh = Color(0xFF2A2A2A);
const _secondary = Color(0xFF5CDBC0);

class StoryViewerScreen extends StatefulWidget {
  final String username;
  final String? avatarBase64;
  final List<Map<String, dynamic>> stories;

  const StoryViewerScreen({
    super.key,
    required this.username,
    required this.stories,
    this.avatarBase64,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  Timer? _autoTimer;
  late AnimationController _progressController;
  final _messageCtrl = TextEditingController();
  bool _paused = false;

  static const _storyDuration = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: _storyDuration,
    );
    _startStory();
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _progressController.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  void _startStory() {
    _autoTimer?.cancel();
    _progressController.forward(from: 0);
    _autoTimer = Timer(_storyDuration, _nextStory);
  }

  void _nextStory() {
    if (_currentIndex < widget.stories.length - 1) {
      setState(() => _currentIndex++);
      _startStory();
    } else {
      Navigator.pop(context);
    }
  }

  void _prevStory() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
      _startStory();
    }
  }

  void _pause() {
    if (_paused) return;
    _paused = true;
    _autoTimer?.cancel();
    _progressController.stop();
  }

  void _resume() {
    if (!_paused) return;
    _paused = false;
    _progressController.forward();
    _autoTimer = Timer(
      _storyDuration * (1 - _progressController.value),
      _nextStory,
    );
  }

  String _timeAgo(dynamic ts) {
    if (ts == null) return '';
    final created = ts is double
        ? DateTime.fromMillisecondsSinceEpoch((ts * 1000).toInt())
        : DateTime.now();
    final diff = DateTime.now().difference(created);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m fa';
    if (diff.inHours < 24) return '${diff.inHours}h fa';
    return '${diff.inDays}g fa';
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.stories[_currentIndex];
    final imageB64 = story['image_base64'] as String?;
    final caption = story['caption'] as String?;
    final timeAgo = _timeAgo(story['created_at']);

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onLongPressStart: (_) => _pause(),
        onLongPressEnd: (_) => _resume(),
        onTapUp: (details) {
          if (_messageCtrl.text.isNotEmpty) return;
          final width = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < width / 2) {
            _prevStory();
          } else {
            _nextStory();
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Story image
            if (imageB64 != null)
              Image.memory(
                base64Decode(imageB64),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Center(
                  child: Icon(Icons.broken_image,
                      color: Colors.white54, size: 64),
                ),
              )
            else
              Container(
                color: _surfaceHigh,
                child: const Center(
                  child: Icon(Icons.image_not_supported,
                      color: Colors.white54, size: 64),
                ),
              ),

            // Top gradient overlay
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 140,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.75),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Bottom gradient overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 180,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.80),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Progress bars
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 12,
              right: 12,
              child: Row(
                children: List.generate(widget.stories.length, (i) {
                  return Expanded(
                    child: Container(
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: Colors.white.withValues(alpha: 0.30),
                      ),
                      child: i < _currentIndex
                          ? Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            )
                          : i == _currentIndex
                              ? AnimatedBuilder(
                                  animation: _progressController,
                                  builder: (_, _) => FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: _progressController.value,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                    ),
                  );
                }),
              ),
            ),

            // User info row + close
            Positioned(
              top: MediaQuery.of(context).padding.top + 20,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  AvatarWidget(
                    base64Image: widget.avatarBase64,
                    fallbackLetter: widget.username.isNotEmpty
                        ? widget.username[0]
                        : 'U',
                    radius: 20,
                    hasActiveStory: false,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '@${widget.username}',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        if (timeAgo.isNotEmpty)
                          Text(
                            timeAgo,
                            style: GoogleFonts.beVietnamPro(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded,
                        color: Colors.white, size: 22),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Caption
            if (caption != null && caption.isNotEmpty)
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 90,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    caption,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.beVietnamPro(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
              ),

            // Message input bar
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 16,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: _surface.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: TextField(
                        controller: _messageCtrl,
                        style: GoogleFonts.beVietnamPro(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        onTap: _pause,
                        onEditingComplete: _resume,
                        decoration: InputDecoration(
                          hintText: 'Invia un messaggio...',
                          hintStyle: GoogleFonts.beVietnamPro(
                            color: Colors.white38,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {
                      _messageCtrl.clear();
                      _resume();
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _secondary.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        color: _secondary,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
