import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../services/api_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _matches = const [];

  @override
  void initState() {
    super.initState();
    _load();
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

  String _timeAgo(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'adesso';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min fa';
    if (diff.inHours < 24) return '${diff.inHours} ore fa';
    if (diff.inDays == 1) return 'ieri';
    if (diff.inDays < 7) return '${diff.inDays} giorni fa';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  Map<String, dynamic> _extractUser(Map<String, dynamic> match) {
    if (match['user'] is Map) return Map<String, dynamic>.from(match['user']);
    if (match['target_user'] is Map) {
      return Map<String, dynamic>.from(match['target_user']);
    }
    if (match['matched_user'] is Map) {
      return Map<String, dynamic>.from(match['matched_user']);
    }
    if (match['other_user'] is Map) {
      return Map<String, dynamic>.from(match['other_user']);
    }
    return match;
  }

  DateTime? _extractMatchedAt(Map<String, dynamic> match) {
    final raw = match['matched_at'] ?? match['created_at'] ?? match['timestamp'];
    if (raw is String) return DateTime.tryParse(raw)?.toLocal();
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        title: const Text('Chat'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        color: const Color(0xFF6C63FF),
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 120),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: const Color(0xFF1A1A2E).withValues(alpha: 0.85),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFFFF6B6B)],
                      ),
                    ),
                    child: const Icon(Icons.favorite_rounded,
                        color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Qui trovi i tuoi match. Se non hai ancora scritto, un “Ciao!” può cambiare la giornata.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                        height: 1.25,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 220.ms).moveY(begin: 8, end: 0),
            const SizedBox(height: 14),
            if (_loading)
              Padding(
                padding: const EdgeInsets.only(top: 60),
                child: Center(
                  child: Column(
                    children: [
                      const CircularProgressIndicator(
                        color: Color(0xFF6C63FF),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Carico i match…',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (_error != null)
              _ErrorState(message: _error!, onRetry: _load)
            else if (_matches.isEmpty)
              _EmptyState(onRetry: _load)
            else
              ..._matches.asMap().entries.map((entry) {
                final idx = entry.key;
                final match = entry.value;
                final user = _extractUser(match);
                final email = (user['email'] ?? '').toString();
                final nameRaw =
                    email.contains('@') ? email.split('@').first : '';
                final name = nameRaw.isEmpty ? 'Match' : nameRaw;
                final initial = name.isEmpty ? 'M' : name[0].toUpperCase();
                final matchedAt = _extractMatchedAt(match);
                final time = matchedAt == null ? '' : _timeAgo(matchedAt);

                final hasMessages = match['has_messages'] == true ||
                    (match['last_message'] != null);

                final subtitle = hasMessages
                    ? 'Chat disponibile (in arrivo realtime)'
                    : 'Dì ciao! ??';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E).withValues(alpha: 0.86),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.22),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    leading: CircleAvatar(
                      radius: 22,
                      backgroundColor:
                          const Color(0xFF6C63FF).withValues(alpha: 0.22),
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.68),
                      ),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (time.isNotEmpty)
                          Text(
                            time,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        const SizedBox(height: 6),
                        Icon(Icons.chevron_right_rounded,
                            color: Colors.white.withValues(alpha: 0.35)),
                      ],
                    ),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Chat realtime in arrivo a breve.'),
                        ),
                      );
                    },
                  ),
                )
                    .animate()
                    .fadeIn(duration: 220.ms, delay: (idx * 40).ms)
                    .moveY(begin: 10, end: 0);
              }),
          ],
        ),
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
      padding: const EdgeInsets.only(top: 56),
      child: Column(
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            color: Colors.white.withValues(alpha: 0.35),
            size: 56,
          ),
          const SizedBox(height: 12),
          Text(
            'Ancora nessun match.\nScorri su “Scopri” e trova il tuo gruppo.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 44,
            child: ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
              ),
              child: const Text('Aggiorna'),
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
      padding: const EdgeInsets.only(top: 50),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Colors.redAccent, size: 52),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.75)),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 44,
            child: ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
              ),
              child: const Text('Riprova'),
            ),
          ),
        ],
      ),
    );
  }
}
