import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/student.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import 'main_navigator.dart';
import 'story_viewer_screen.dart';
import 'widgets/avatar_widget.dart';
import 'widgets/student_card.dart';

// Design system
const _bg = Color(0xFF131313);
const _surfaceHigh = Color(0xFF2A2A2A);
const _primary = Color(0xFFC4C0FF);
const _primaryDark = Color(0xFF8781FF);
const _secondary = Color(0xFF5CDBC0);

class SwipeScreen extends StatefulWidget {
  const SwipeScreen({super.key});

  @override
  State<SwipeScreen> createState() => _SwipeScreenState();
}

enum _SwipeFx { none, like, dislike }

class _SwipeScreenState extends State<SwipeScreen> {
  final CardSwiperController _swiperController = CardSwiperController();
  List<Student> _students = [];
  bool _loading = true;
  String? _error;
  Student? _matchStudent;
  _SwipeFx _fx = _SwipeFx.none;

  List<Map<String, dynamic>> _storyUsers = [];
  String? _myAvatar;
  String _myName = '';

  @override
  void initState() {
    super.initState();
    _loadStudents();
    _loadStoriesFeed();
    _loadMyProfile();
  }

  Future<void> _loadStudents() async {
    try {
      final students = await ApiService.getRecommendations();
      setState(() {
        _students = students;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _loadStoriesFeed() async {
    try {
      final feed = await ApiService.getStoriesFeed();
      if (!mounted) return;
      setState(() => _storyUsers = feed
          .map((e) => {
                'username': e['user']['username'] ?? '',
                'avatar_base64': e['user']['avatar_base64'],
                'stories': e['stories'],
              })
          .toList());
    } catch (_) {}
  }

  Future<void> _loadMyProfile() async {
    try {
      final me = await ApiService.getMe();
      if (!mounted) return;
      setState(() {
        _myAvatar = me['avatar_base64'] as String?;
        final username = me['username'] as String?;
        final email = me['email'] as String? ?? '';
        _myName = username ?? email.split('@').first;
      });
    } catch (_) {}
  }

  void _showFx(_SwipeFx fx) {
    setState(() => _fx = fx);
    Future.delayed(const Duration(milliseconds: 420), () {
      if (!mounted) return;
      setState(() => _fx = _SwipeFx.none);
    });
  }

  bool _onSwipe(int prev, int? curr, CardSwiperDirection dir) {
    final student = _students[prev];
    final isLike = dir == CardSwiperDirection.right;
    _showFx(isLike ? _SwipeFx.like : _SwipeFx.dislike);
    ApiService.swipe(student.id, isLike).then((isMatch) {
      if (!mounted) return;
      if (isMatch) {
        setState(() => _matchStudent = student);
        NotificationService.showMatchNotification(student.displayName);
      }
    }).catchError((_) {});
    return true;
  }

  void _openStory(Map<String, dynamic> storyUser) {
    final stories = storyUser['stories'] as List? ?? [];
    if (stories.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StoryViewerScreen(
          username: storyUser['username'] as String? ?? '',
          avatarBase64: storyUser['avatar_base64'] as String?,
          stories: stories
              .map((s) => Map<String, dynamic>.from(s as Map))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildStoriesBar() {
    final fallback = _myName.isNotEmpty ? _myName[0] : 'M';
    return SizedBox(
      height: 96,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _storyUsers.length + 1,
        itemBuilder: (ctx, i) {
          if (i == 0) {
            return Padding(
              padding: const EdgeInsets.only(right: 16),
              child: GestureDetector(
                onTap: () => MainNavigator.maybeOf(context)?.setTab(3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      children: [
                        AvatarWidget(
                          base64Image: _myAvatar,
                          fallbackLetter: fallback,
                          radius: 28,
                          hasActiveStory: false,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: _primaryDark,
                              shape: BoxShape.circle,
                              border: Border.all(color: _bg, width: 2),
                            ),
                            child: const Icon(Icons.add,
                                color: Colors.white, size: 10),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tu',
                      style: GoogleFonts.beVietnamPro(
                          fontSize: 10,
                          color: Colors.white54,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            );
          }
          final storyUser = _storyUsers[i - 1];
          final username = storyUser['username'] as String? ?? '';
          final avatarB64 = storyUser['avatar_base64'] as String?;
          final fbLetter = username.isNotEmpty ? username[0] : 'U';
          return GestureDetector(
            onTap: () => _openStory(storyUser),
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AvatarWidget(
                    base64Image: avatarB64,
                    fallbackLetter: fbLetter,
                    radius: 28,
                    hasActiveStory: true,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    username.isEmpty ? 'U' : username,
                    style: GoogleFonts.beVietnamPro(
                        fontSize: 10,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: Colors.white70),
          onPressed: () {},
        ),
        title: Text(
          'Incontro',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 22,
            foreground: Paint()
              ..shader = const LinearGradient(
                colors: [_primary, _secondary],
              ).createShader(const Rect.fromLTWH(0, 0, 120, 24)),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined,
                color: Colors.white70),
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_loading)
            Center(
              child: CircularProgressIndicator(
                color: _primary,
                strokeWidth: 2,
              ),
            )
          else if (_error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.redAccent, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.beVietnamPro(
                          color: Colors.white60, fontSize: 15),
                    ),
                    const SizedBox(height: 20),
                    _PillButton(
                      label: 'Riprova',
                      color: _primaryDark,
                      onTap: () {
                        setState(() {
                          _loading = true;
                          _error = null;
                        });
                        _loadStudents();
                      },
                    ),
                  ],
                ),
              ),
            )
          else if (_students.isEmpty)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.people_outline,
                      color: Colors.white24, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    'Nessuno studente compatibile\nper ora!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.beVietnamPro(
                        color: Colors.white38, fontSize: 16),
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                _buildStoriesBar(),
                Expanded(
                  child: CardSwiper(
                    controller: _swiperController,
                    cardsCount: _students.length,
                    numberOfCardsDisplayed:
                        _students.length >= 2 ? 2 : 1,
                    onSwipe: _onSwipe,
                    scale: 0.92,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 8),
                    cardBuilder: (ctx, index, h, v) =>
                        StudentCard(student: _students[index]),
                  ),
                ),
                // Action buttons
                Padding(
                  padding: const EdgeInsets.only(bottom: 24, top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _CircleAction(
                        icon: Icons.close_rounded,
                        color: Colors.white30,
                        iconColor: Colors.white70,
                        size: 56,
                        onTap: () => _swiperController
                            .swipe(CardSwiperDirection.left),
                      ),
                      const SizedBox(width: 16),
                      _CircleAction(
                        icon: Icons.favorite_rounded,
                        color: _primaryDark,
                        iconColor: Colors.white,
                        size: 68,
                        onTap: () => _swiperController
                            .swipe(CardSwiperDirection.right),
                        glow: true,
                      ),
                      const SizedBox(width: 16),
                      _CircleAction(
                        icon: Icons.star_rounded,
                        color: Colors.white12,
                        iconColor: const Color(0xFFFFB347),
                        size: 56,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Super like in arrivo.',
                                  style: GoogleFonts.beVietnamPro()),
                              backgroundColor: _surfaceHigh,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),

          // FX overlay
          if (_fx != _SwipeFx.none)
            Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _fx == _SwipeFx.like
                          ? _primaryDark.withValues(alpha: 0.25)
                          : Colors.redAccent.withValues(alpha: 0.18),
                    ),
                    child: Icon(
                      _fx == _SwipeFx.like
                          ? Icons.favorite_rounded
                          : Icons.close_rounded,
                      size: 64,
                      color: _fx == _SwipeFx.like
                          ? _primary
                          : Colors.redAccent,
                    ),
                  )
                      .animate()
                      .scaleXY(begin: 0.6, end: 1.1, duration: 220.ms)
                      .fadeIn(duration: 120.ms)
                      .then()
                      .fadeOut(duration: 200.ms),
                ),
              ),
            ),

          // Match overlay
          if (_matchStudent != null)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.7),
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      color: const Color(0xFF1C1B2E),
                      boxShadow: [
                        BoxShadow(
                          color: _primary.withValues(alpha: 0.25),
                          blurRadius: 40,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) =>
                              const LinearGradient(
                            colors: [_primary, _secondary],
                          ).createShader(bounds),
                          child: Text(
                            'È un Incontro! 🎉',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Tu e ${_matchStudent!.displayName} avete voglia di studiare.\nScrivi un "Ciao" e rompete il ghiaccio.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.beVietnamPro(
                            color: Colors.white54,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() => _matchStudent = null);
                              MainNavigator.maybeOf(context)?.setTab(2);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryDark,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(9999),
                              ),
                            ),
                            child: Text('Inizia a chattare',
                                style: GoogleFonts.beVietnamPro(
                                    fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: () =>
                              setState(() => _matchStudent = null),
                          child: Text(
                            'Non ora',
                            style: GoogleFonts.beVietnamPro(
                                color: Colors.white38),
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 200.ms)
                      .scaleXY(begin: 0.94, end: 1, duration: 250.ms),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color iconColor;
  final double size;
  final VoidCallback onTap;
  final bool glow;

  const _CircleAction({
    required this.icon,
    required this.color,
    required this.iconColor,
    required this.size,
    required this.onTap,
    this.glow = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: glow
              ? [
                  BoxShadow(
                    color: _primaryDark.withValues(alpha: 0.45),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Icon(icon, color: iconColor, size: size * 0.44),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _PillButton(
      {required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(9999),
        ),
        child: Text(
          label,
          style: GoogleFonts.beVietnamPro(
              color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
