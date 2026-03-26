import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/student.dart';
import '../services/api_service.dart';
import 'main_navigator.dart';
import 'widgets/student_card.dart';

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

  @override
  void initState() {
    super.initState();
    _loadStudents();
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

  void _openMapsTab() {
    MainNavigator.maybeOf(context)?.setTab(1);
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
      if (isMatch) setState(() => _matchStudent = student);
    }).catchError((_) {});
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Incontro',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _openMapsTab,
            icon: const Icon(Icons.map_rounded, color: Color(0xFF6C63FF)),
            tooltip: 'Posti studio vicini',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          if (_loading)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
            )
          else if (_error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.redAccent, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _loading = true;
                          _error = null;
                        });
                        _loadStudents();
                      },
                      child: const Text('Riprova'),
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
                      color: Colors.white38, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    'Nessuno studente compatibile\nper ora!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                        color: Colors.white54, fontSize: 16),
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Text(
                    'Trova qualcuno con cui studiare.\nUn match oggi può diventare una compagnia domani.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.62),
                      height: 1.2,
                    ),
                  ).animate().fadeIn(duration: 260.ms),
                ),
                Expanded(
                  child: CardSwiper(
                    controller: _swiperController,
                    cardsCount: _students.length,
                    onSwipe: _onSwipe,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    cardBuilder: (ctx, index, h, v) =>
                        StudentCard(student: _students[index]),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 32, top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ActionButton(
                        icon: Icons.close,
                        color: Colors.redAccent,
                        onTap: () => _swiperController
                            .swipe(CardSwiperDirection.left),
                      ),
                      const SizedBox(width: 18),
                      _ActionButton(
                        icon: Icons.star_rounded,
                        color: const Color(0xFFFFB347),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Super like in arrivo.')),
                          );
                        },
                      ),
                      const SizedBox(width: 18),
                      _ActionButton(
                        icon: Icons.favorite,
                        color: const Color(0xFF6C63FF),
                        onTap: () => _swiperController
                            .swipe(CardSwiperDirection.right),
                        large: true,
                      ),
                      const SizedBox(width: 18),
                      _ActionButton(
                        icon: Icons.map_rounded,
                        color: const Color(0xFF43C6AC),
                        onTap: _openMapsTab,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          if (_fx != _SwipeFx.none)
            Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.25),
                    ),
                    child: Icon(
                      _fx == _SwipeFx.like
                          ? Icons.favorite_rounded
                          : Icons.close_rounded,
                      size: 76,
                      color: _fx == _SwipeFx.like
                          ? const Color(0xFFFF6B6B)
                          : Colors.redAccent,
                    ),
                  )
                      .animate()
                      .scaleXY(begin: 0.7, end: 1.12, duration: 220.ms)
                      .fadeIn(duration: 120.ms)
                      .then()
                      .fadeOut(duration: 220.ms),
                ),
              ),
            ),
          if (_matchStudent != null)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.55),
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 22),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.10),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6C63FF).withValues(alpha: 0.35),
                          blurRadius: 30,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'E un Match! 🎉',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tu e ${_matchStudent!.displayName} avete voglia di studiare.\nScrivi un "Ciao" e rompete il ghiaccio.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.72),
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 52,
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() => _matchStudent = null);
                              MainNavigator.maybeOf(context)?.setTab(2);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6C63FF),
                            ),
                            child: const Text('Inizia a chattare'),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 48,
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => setState(() => _matchStudent = null),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.18),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text('Non ora'),
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 180.ms)
                      .scaleXY(begin: 0.96, end: 1, duration: 220.ms),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool large;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = large ? 72.0 : 56.0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.12),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 12,
            ),
          ],
        ),
        child: Icon(icon, color: color, size: large ? 32 : 24),
      ),
    );
  }
}
