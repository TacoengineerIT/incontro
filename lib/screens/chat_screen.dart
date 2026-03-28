import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/user_profile.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import 'widgets/avatar_widget.dart';

// Design system
const _bg = Color(0xFF131313);
const _surface = Color(0xFF1E1E1E);
const _surfaceHigh = Color(0xFF2A2A2A);
const _primary = Color(0xFFC4C0FF);
const _primaryDark = Color(0xFF8781FF);
const _secondary = Color(0xFF5CDBC0);

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _matches = const [];
  Timer? _pollingTimer;
  int _lastMatchCount = 0;

  final TextEditingController _searchCtrl = TextEditingController();
  List<UserProfile> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _load();
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkNewMatches(),
    );
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkNewMatches() async {
    try {
      final matches = await ApiService.getMatches();
      if (matches.length > _lastMatchCount && _lastMatchCount > 0) {
        final newest = matches.first as Map<String, dynamic>;
        final matchUser = newest['match_user'];
        if (matchUser is Map) {
          final username = matchUser['username'] as String?;
          final email = (matchUser['email'] ?? '') as String;
          final name = username ?? email.split('@').first;
          await NotificationService.showMatchNotification(name);
        }
      }
      _lastMatchCount = matches.length;
      if (!mounted) return;
      setState(() => _matches = List<Map<String, dynamic>>.from(
          matches.map((e) => e as Map<String, dynamic>)));
    } catch (_) {}
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final matches = await ApiService.getMyMatches();
      if (!mounted) return;
      setState(() {
        _matches = matches;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }
    setState(() => _isSearching = true);
    try {
      final results = await ApiService.searchUsers(query);
      if (!mounted) return;
      setState(() => _searchResults = results);
    } catch (_) {
      if (!mounted) return;
      setState(() => _searchResults = []);
    }
  }

  String _timeAgo(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'adesso';
    if (diff.inHours < 1) return '${diff.inMinutes} min fa';
    if (diff.inHours < 24) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }
    if (diff.inDays == 1) return 'IERI';
    const days = ['LUN', 'MAR', 'MER', 'GIO', 'VEN', 'SAB', 'DOM'];
    if (diff.inDays < 7) return days[dt.weekday - 1];
    return '${dt.day} OTT';
  }

  Map<String, dynamic> _extractUser(Map<String, dynamic> match) {
    for (final key in ['match_user', 'user', 'target_user', 'matched_user', 'other_user']) {
      if (match[key] is Map) return Map<String, dynamic>.from(match[key]);
    }
    return match;
  }

  DateTime? _extractMatchedAt(Map<String, dynamic> match) {
    final raw =
        match['matched_at'] ?? match['created_at'] ?? match['timestamp'];
    if (raw is String) return DateTime.tryParse(raw)?.toLocal();
    if (raw is num) {
      return DateTime.fromMillisecondsSinceEpoch((raw * 1000).round());
    }
    return null;
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
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [_primary, _secondary],
          ).createShader(bounds),
          child: Text(
            'Incontro',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              fontSize: 22,
              color: Colors.white,
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined,
                color: Colors.white70),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        color: _primary,
        backgroundColor: _surfaceHigh,
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            // Search bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    style: GoogleFonts.beVietnamPro(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: '@username search',
                      hintStyle: GoogleFonts.beVietnamPro(
                          color: Colors.white30, fontSize: 14),
                      prefixIcon: const Icon(Icons.search,
                          color: Colors.white30, size: 20),
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onChanged: _searchUsers,
                  ),
                ),
              ),
            ),

            if (_isSearching) ...[
              // Search results
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                sliver: _searchResults.isEmpty
                    ? SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 40),
                            child: Text(
                              'Nessun utente trovato.',
                              style: GoogleFonts.beVietnamPro(
                                  color: Colors.white38),
                            ),
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) {
                            final profile = _searchResults[i];
                            final fallback =
                                (profile.username?.isNotEmpty == true)
                                    ? profile.username![0]
                                    : profile.email.isNotEmpty
                                        ? profile.email[0]
                                        : 'U';
                            return _SearchResultTile(
                              profile: profile,
                              fallback: fallback,
                              onFollow: () async {
                                if (profile.username == null) return;
                                final messenger =
                                    ScaffoldMessenger.of(context);
                                try {
                                  await ApiService.followUser(
                                      profile.username!);
                                  messenger.showSnackBar(SnackBar(
                                    content: Text(
                                        'Ora segui @${profile.username}',
                                        style:
                                            GoogleFonts.beVietnamPro()),
                                    backgroundColor: _surfaceHigh,
                                    behavior: SnackBarBehavior.floating,
                                  ));
                                } catch (e) {
                                  messenger.showSnackBar(SnackBar(
                                    content: Text(
                                        e.toString().replaceFirst(
                                            'Exception: ', ''),
                                        style:
                                            GoogleFonts.beVietnamPro()),
                                    backgroundColor: _surfaceHigh,
                                    behavior: SnackBarBehavior.floating,
                                  ));
                                }
                              },
                            );
                          },
                          childCount: _searchResults.length,
                        ),
                      ),
              ),
            ] else ...[
              // Stories row header
              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // Match list
              if (_loading)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 80),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: _primary,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                )
              else if (_error != null)
                SliverToBoxAdapter(
                  child: _ErrorState(message: _error!, onRetry: _load),
                )
              else if (_matches.isEmpty)
                SliverToBoxAdapter(
                  child: _EmptyState(onRetry: _load),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, idx) {
                        final match = _matches[idx];
                        final user = _extractUser(match);
                        final username = user['username'] as String?;
                        final email =
                            (user['email'] ?? '').toString();
                        final nameRaw = username ??
                            (email.contains('@')
                                ? email.split('@').first
                                : email);
                        final name =
                            nameRaw.isEmpty ? 'Match' : nameRaw;
                        final displayName =
                            username != null ? '@$username' : name;
                        final fallback = name.isNotEmpty
                            ? name[0].toUpperCase()
                            : 'M';
                        final avatarB64 =
                            user['avatar_base64'] as String?;
                        final hasStory =
                            user['has_active_story'] == true;
                        final matchedAt = _extractMatchedAt(match);
                        final timeStr =
                            matchedAt == null ? '' : _timeAgo(matchedAt);

                        final hasMessages = match['has_messages'] == true ||
                            (match['last_message'] != null);
                        final subtitle = hasMessages
                            ? 'Chat disponibile'
                            : 'Dai ciao! 👋';

                        return _MatchTile(
                          fallback: fallback,
                          avatarB64: avatarB64,
                          hasStory: hasStory,
                          displayName: displayName,
                          username: username,
                          subtitle: subtitle,
                          timeStr: timeStr,
                          idx: idx,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Chat realtime in arrivo.',
                                    style: GoogleFonts.beVietnamPro()),
                                backgroundColor: _surfaceHigh,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        );
                      },
                      childCount: _matches.length,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MatchTile extends StatelessWidget {
  final String fallback;
  final String? avatarB64;
  final bool hasStory;
  final String displayName;
  final String? username;
  final String subtitle;
  final String timeStr;
  final int idx;
  final VoidCallback onTap;

  const _MatchTile({
    required this.fallback,
    required this.avatarB64,
    required this.hasStory,
    required this.displayName,
    required this.username,
    required this.subtitle,
    required this.timeStr,
    required this.idx,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            AvatarWidget(
              base64Image: avatarB64,
              fallbackLetter: fallback,
              radius: 26,
              hasActiveStory: hasStory,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (username != null)
                    Text(
                      '@$username',
                      style: GoogleFonts.beVietnamPro(
                        color: _secondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  Text(
                    subtitle,
                    style: GoogleFonts.beVietnamPro(
                      color: Colors.white38,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (timeStr.isNotEmpty)
                  Text(
                    timeStr,
                    style: GoogleFonts.beVietnamPro(
                      color: Colors.white30,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ],
        ),
      )
          .animate()
          .fadeIn(duration: 220.ms, delay: (idx * 40).ms)
          .moveX(begin: 10, end: 0),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  final UserProfile profile;
  final String fallback;
  final VoidCallback onFollow;

  const _SearchResultTile({
    required this.profile,
    required this.fallback,
    required this.onFollow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          AvatarWidget(
            base64Image: profile.avatarBase64,
            fallbackLetter: fallback,
            radius: 22,
            hasActiveStory: profile.hasActiveStory,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.username != null
                      ? '@${profile.username}'
                      : profile.email.split('@').first,
                  style: GoogleFonts.plusJakartaSans(
                    color: _primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  profile.email,
                  style: GoogleFonts.beVietnamPro(
                      color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onFollow,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _primaryDark.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Text(
                'Segui',
                style: GoogleFonts.beVietnamPro(
                  color: _primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(
        children: [
          Icon(Icons.chat_bubble_outline_rounded,
              color: Colors.white.withValues(alpha: 0.2), size: 56),
          const SizedBox(height: 16),
          Text(
            'Ancora nessun match.\nScorri su "Scopri" e trova il tuo gruppo.',
            textAlign: TextAlign.center,
            style: GoogleFonts.beVietnamPro(
                color: Colors.white38, fontSize: 15, height: 1.6),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 28, vertical: 12),
              decoration: BoxDecoration(
                color: _primaryDark,
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Text('Aggiorna',
                  style: GoogleFonts.beVietnamPro(
                      color: Colors.white,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Colors.redAccent, size: 52),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.beVietnamPro(
                color: Colors.white38, fontSize: 14),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 28, vertical: 12),
              decoration: BoxDecoration(
                color: _primaryDark,
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Text('Riprova',
                  style: GoogleFonts.beVietnamPro(
                      color: Colors.white,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
