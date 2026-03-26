import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loading = true;
  bool _saving = false;
  String? _error;

  Map<String, dynamic>? _me;

  final TextEditingController _newSubjectCtrl = TextEditingController();
  final FocusNode _subjectFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _newSubjectCtrl.dispose();
    _subjectFocus.dispose();
    super.dispose();
  }

  List<String> get _subjects {
    final raw = _me?['study_subjects'];
    if (raw is List) {
      return raw
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return <String>[];
  }

  String get _style {
    final s = (_me?['learning_style'] ?? 'Silenzioso').toString();
    return s == 'Rumoroso' ? 'Rumoroso' : 'Silenzioso';
  }

  bool get _verified => _me?['is_verified'] == true;
  String get _email => (_me?['email'] ?? '').toString();

  String get _displayName {
    if (_email.contains('@')) return _email.split('@').first;
    return _email.isEmpty ? 'Studente' : _email;
  }

  String get _initial {
    final n = _displayName;
    return n.isEmpty ? 'S' : n[0].toUpperCase();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final me = await ApiService.getMe();
      if (!mounted) return;
      setState(() {
        _me = me;
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

  void _setSubjects(List<String> subjects) {
    setState(() {
      _me = {...?_me, 'study_subjects': subjects};
    });
  }

  void _setStyle(String style) {
    setState(() {
      _me = {...?_me, 'learning_style': style};
    });
  }

  void _addSubject() {
    final text = _newSubjectCtrl.text.trim();
    if (text.isEmpty) return;

    final updated = [..._subjects];
    final lower = text.toLowerCase();
    if (!updated.map((s) => s.toLowerCase()).contains(lower)) updated.add(text);
    _setSubjects(updated);

    _newSubjectCtrl.clear();
    _subjectFocus.requestFocus();
  }

  void _removeSubject(String s) {
    _setSubjects(_subjects.where((e) => e != s).toList());
  }

  Future<void> _saveProfile() async {
    if (_subjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aggiungi almeno una materia.')),
      );
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ApiService.updateProfile(_subjects, _style);
      final me = await ApiService.getMe();
      if (!mounted) return;
      setState(() {
        _me = me;
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profilo aggiornato.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _saving = false;
      });
    }
  }

  void _logout() => ApiService.logout();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        title: const Text('Profilo'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF6C63FF),
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 120),
          children: [
            if (_loading)
              Padding(
                padding: const EdgeInsets.only(top: 70),
                child: Center(
                  child: Column(
                    children: [
                      const CircularProgressIndicator(color: Color(0xFF6C63FF)),
                      const SizedBox(height: 14),
                      Text(
                        'Carico il profilo...',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (_error != null && _me == null)
              _ErrorState(message: _error!, onRetry: _load)
            else ...[
              _HeaderCard(
                initial: _initial,
                name: _displayName,
                email: _email,
                verified: _verified,
              ).animate().fadeIn(duration: 220.ms).moveY(begin: 8, end: 0),
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Materie',
                subtitle: 'Aiuta a trovarti compagni con interessi simili.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final s in _subjects)
                          Chip(
                            label: Text(
                              s,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF6C63FF),
                              ),
                            ),
                            backgroundColor:
                                const Color(0xFF6C63FF).withValues(alpha: 0.14),
                            side: BorderSide(
                              color:
                                  const Color(0xFF6C63FF).withValues(alpha: 0.25),
                            ),
                            deleteIconColor: Colors.white70,
                            onDeleted: () => _removeSubject(s),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _newSubjectCtrl,
                            focusNode: _subjectFocus,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Aggiungi materia (es. Analisi 1)',
                              hintStyle: TextStyle(
                                color: Colors.white.withValues(alpha: 0.38),
                              ),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.06),
                            ),
                            onSubmitted: (_) => _addSubject(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          height: 52,
                          width: 52,
                          child: ElevatedButton(
                            onPressed: _addSubject,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6C63FF),
                              padding: EdgeInsets.zero,
                            ),
                            child: const Icon(Icons.add_rounded),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Stile di studio',
                subtitle: 'Ti piace il silenzio o vai di cuffie e chiacchiere?',
                child: Row(
                  children: [
                    _StyleToggle(
                      label: 'Silenzioso',
                      icon: Icons.library_books_rounded,
                      selected: _style == 'Silenzioso',
                      onTap: () => _setStyle('Silenzioso'),
                    ),
                    const SizedBox(width: 10),
                    _StyleToggle(
                      label: 'Rumoroso',
                      icon: Icons.headphones_rounded,
                      selected: _style == 'Rumoroso',
                      onTap: () => _setStyle('Rumoroso'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.redAccent)),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                  ),
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(_saving ? 'Salvo...' : 'Modifica profilo'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _logout,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Logout'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.initial,
    required this.name,
    required this.email,
    required this.verified,
  });

  final String initial;
  final String name;
  final String email;
  final bool verified;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFFFF6B6B)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6C63FF).withValues(alpha: 0.35),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    if (verified)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(99),
                          color: const Color(0xFF2ECC71).withValues(alpha: 0.16),
                          border: Border.all(
                            color: const Color(0xFF2ECC71).withValues(alpha: 0.28),
                          ),
                        ),
                        child: const Text(
                          '✓ Email verificata',
                          style: TextStyle(
                            color: Color(0xFF2ECC71),
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFF1A1A2E).withValues(alpha: 0.86),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              height: 1.25,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _StyleToggle extends StatelessWidget {
  const _StyleToggle({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? const Color(0xFF6C63FF).withValues(alpha: 0.18)
        : Colors.white.withValues(alpha: 0.05);
    final border = selected
        ? const Color(0xFF6C63FF).withValues(alpha: 0.55)
        : Colors.white.withValues(alpha: 0.12);
    final color = selected ? const Color(0xFF6C63FF) : Colors.white54;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: Column(
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
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

