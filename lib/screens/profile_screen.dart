import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

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

  bool _isStudying = false;
  String? _studyLocationName;

  String? _avatarBase64;
  int _matchCount = 0;
  int _followersCount = 0;
  int _followingCount = 0;
  bool _hasActiveStory = false;

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
  String? get _username => _me?['username'] as String?;

  String get _displayName {
    if (_username != null && _username!.isNotEmpty) return _username!;
    if (_email.contains('@')) return _email.split('@').first;
    return _email.isEmpty ? 'Studente' : _email;
  }

  String get _initial {
    final n = _displayName;
    return n.isEmpty ? 'S' : n[0].toUpperCase();
  }

  String get _universityLabel {
    final domain = _email.contains('@') ? _email.split('@').last : '';
    const map = <String, String>{
      'unina.it': 'Univ. Federico II',
      'unipi.it': 'Univ. di Pisa',
      'unibo.it': 'Univ. di Bologna',
      'uniroma1.it': 'Sapienza',
      'polimi.it': 'Politecnico di Milano',
      'polito.it': 'Politecnico di Torino',
    };
    return map[domain] ?? (domain.isEmpty ? '' : 'Università $domain');
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
        _avatarBase64 = me['avatar_base64'] as String?;
        _followersCount = me['followers_count'] as int? ?? 0;
        _followingCount = me['following_count'] as int? ?? 0;
        _hasActiveStory = me['has_active_story'] as bool? ?? false;
        _loading = false;
      });
      try {
        final matches = await ApiService.getMyMatches();
        if (mounted) setState(() => _matchCount = matches.length);
      } catch (_) {}
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
    if (!updated.map((s) => s.toLowerCase()).contains(lower)) {
      updated.add(text);
    }
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

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      final b64 = base64Encode(bytes);
      await ApiService.updateAvatar(b64);
      if (!mounted) return;
      setState(() => _avatarBase64 = b64);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto profilo aggiornata.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _postStory() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1920,
        imageQuality: 80,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      final b64 = base64Encode(bytes);

      String? caption;
      if (mounted) {
        final captionCtrl = TextEditingController();
        caption = await showDialog<String>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: _surfaceHigh,
            title: Text('Aggiungi una didascalia',
                style: GoogleFonts.plusJakartaSans(
                    color: Colors.white, fontWeight: FontWeight.w700)),
            content: TextField(
              controller: captionCtrl,
              style: GoogleFonts.beVietnamPro(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Opzionale...',
                hintStyle: GoogleFonts.beVietnamPro(
                    color: Colors.white.withValues(alpha: 0.4)),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.06),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, null),
                child: Text('Salta',
                    style:
                        GoogleFonts.beVietnamPro(color: Colors.white54)),
              ),
              GestureDetector(
                onTap: () =>
                    Navigator.pop(ctx, captionCtrl.text.trim()),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: _secondary,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Text(
                    'Pubblica',
                    style: GoogleFonts.beVietnamPro(
                        color: Colors.white,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        );
      }

      await ApiService.postStory(b64, caption);
      if (!mounted) return;
      setState(() => _hasActiveStory = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Storia pubblicata! Scade in 24h')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  void _showUsernameDialog() {
    final usernameCtrl = TextEditingController(text: _username ?? '');
    final usernameRe = RegExp(r'^[a-zA-Z0-9_]*$');
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) {
          String? fieldError;
          return AlertDialog(
            backgroundColor: _surfaceHigh,
            title: Text('Imposta @username',
                style: GoogleFonts.plusJakartaSans(
                    color: Colors.white, fontWeight: FontWeight.w700)),
            content: TextField(
              controller: usernameCtrl,
              style: GoogleFonts.beVietnamPro(color: Colors.white),
              decoration: InputDecoration(
                prefixText: '@',
                prefixStyle:
                    GoogleFonts.beVietnamPro(color: _primaryDark),
                hintText: 'username',
                hintStyle: GoogleFonts.beVietnamPro(
                    color: Colors.white.withValues(alpha: 0.4)),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.06),
                errorText: fieldError,
              ),
              onChanged: (val) {
                if (!usernameRe.hasMatch(val)) {
                  setDlg(() =>
                      fieldError = 'Solo lettere, numeri e underscore');
                } else {
                  setDlg(() => fieldError = null);
                }
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Annulla',
                    style:
                        GoogleFonts.beVietnamPro(color: Colors.white54)),
              ),
              GestureDetector(
                onTap: () async {
                  final val = usernameCtrl.text.trim();
                  if (val.length < 3) return;
                  Navigator.pop(ctx);
                  try {
                    await ApiService.updateUsername(val);
                    final me = await ApiService.getMe();
                    if (!mounted) return;
                    setState(() => _me = me);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Username @$val salvato.')),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(e
                              .toString()
                              .replaceFirst('Exception: ', ''))),
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: _primaryDark,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Text(
                    'Salva',
                    style: GoogleFonts.beVietnamPro(
                        color: Colors.white,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showStartSessionDialog() {
    final locationCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surfaceHigh,
        title: Text(
          'Avvia sessione di studio',
          style: GoogleFonts.plusJakartaSans(
              color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: locationCtrl,
          style: GoogleFonts.beVietnamPro(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Nome del posto (es. Biblioteca Nazionale)',
            hintStyle: GoogleFonts.beVietnamPro(
                color: Colors.white.withValues(alpha: 0.4)),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.06),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Annulla',
                style:
                    GoogleFonts.beVietnamPro(color: Colors.white54)),
          ),
          GestureDetector(
            onTap: () {
              final name = locationCtrl.text.trim();
              Navigator.pop(ctx);
              _startSession(name);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: _secondary,
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Text(
                'Avvia',
                style: GoogleFonts.beVietnamPro(
                    color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startSession(String locationName) async {
    if (locationName.isEmpty) return;
    double lat = 40.8518;
    double lon = 14.2681;
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition();
        lat = pos.latitude;
        lon = pos.longitude;
      }
    } catch (_) {}
    try {
      await ApiService.startStudySession(locationName, lat, lon);
      await NotificationService.showStudySessionNotification(locationName);
      if (!mounted) return;
      setState(() {
        _isStudying = true;
        _studyLocationName = locationName;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _stopSession() async {
    try {
      await ApiService.stopStudySession();
      if (!mounted) return;
      setState(() {
        _isStudying = false;
        _studyLocationName = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  void _logout() => ApiService.logout();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: RefreshIndicator(
        color: _primary,
        backgroundColor: _surfaceHigh,
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            // App bar
            SliverAppBar(
              backgroundColor: _bg,
              elevation: 0,
              floating: true,
              snap: true,
              title: ShaderMask(
                shaderCallback: (r) => const LinearGradient(
                  colors: [_primary, _secondary],
                ).createShader(r),
                child: Text(
                  'Profilo',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              actions: [
                IconButton(
                  tooltip: 'Logout',
                  onPressed: _logout,
                  icon: const Icon(Icons.logout_rounded,
                      color: Colors.white54),
                ),
                const SizedBox(width: 4),
              ],
            ),

            if (_loading)
              SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(
                    color: _primary.withValues(alpha: 0.8),
                  ),
                ),
              )
            else if (_error != null && _me == null)
              SliverFillRemaining(
                child: _ErrorState(message: _error!, onRetry: _load),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // --- PROFILE HEADER ---
                    _buildProfileHeader(),
                    const SizedBox(height: 16),

                    // --- USERNAME BANNER ---
                    if (_username == null) ...[
                      _buildUsernameBanner(),
                      const SizedBox(height: 16),
                    ],

                    // --- MOMENTI (Stories row) ---
                    _buildMomentiRow(),
                    const SizedBox(height: 16),

                    // --- BIO ---
                    _buildBioSection(),
                    const SizedBox(height: 16),

                    // --- INTERESSI DI STUDIO ---
                    _buildInteressiSection(),
                    const SizedBox(height: 16),

                    // --- STILE DI STUDIO ---
                    _buildStileSection(),
                    const SizedBox(height: 16),

                    // --- SESSIONE DI STUDIO ---
                    _buildSessioneSection(),
                    const SizedBox(height: 16),

                    // --- ISCRITTO A ---
                    _buildIscrittoSection(),
                    const SizedBox(height: 24),

                    // --- ACTION BUTTONS ---
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(_error!,
                            style: const TextStyle(
                                color: Colors.redAccent)),
                      ),
                    _buildActionButtons(),
                    const SizedBox(height: 12),
                    _buildLogoutButton(),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: _surface,
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.06),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    AvatarWidget(
                      base64Image: _avatarBase64,
                      fallbackLetter: _initial,
                      radius: 46,
                      hasActiveStory: _hasActiveStory,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: _primaryDark,
                          shape: BoxShape.circle,
                          border: Border.all(color: _bg, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt,
                            color: Colors.white, size: 14),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              // Stats
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _StatItem(_matchCount.toString(), 'Match'),
                    _StatItem(_followersCount.toString(), 'Follower'),
                    _StatItem(_followingCount.toString(), 'Seguiti'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Name
          Text(
            _displayName,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 20,
              height: 1.1,
            ),
          ),
          if (_username != null) ...[
            const SizedBox(height: 2),
            Text(
              '@$_username',
              style: GoogleFonts.beVietnamPro(
                color: _secondary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
          if (_verified) ...[
            const SizedBox(height: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9999),
                color: const Color(0xFF2ECC71).withValues(alpha: 0.14),
              ),
              child: Text(
                '✓ Email verificata',
                style: GoogleFonts.beVietnamPro(
                  color: const Color(0xFF2ECC71),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 220.ms).moveY(begin: 8, end: 0);
  }

  Widget _buildUsernameBanner() {
    return GestureDetector(
      onTap: _showUsernameDialog,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFB347).withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Color(0xFFFFB347), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Imposta il tuo @username',
                style: GoogleFonts.beVietnamPro(
                  color: const Color(0xFFFFB347),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Color(0xFFFFB347)),
          ],
        ),
      ),
    );
  }

  Widget _buildMomentiRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Momenti',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 90,
          child: Row(
            children: [
              // Add story button
              GestureDetector(
                onTap: _postStory,
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: _surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: _secondary.withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(Icons.add_rounded,
                          color: _secondary, size: 28),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Aggiungi',
                      style: GoogleFonts.beVietnamPro(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (_hasActiveStory) ...[
                const SizedBox(width: 12),
                Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: LinearGradient(
                          colors: [
                            _primary.withValues(alpha: 0.3),
                            _secondary.withValues(alpha: 0.3),
                          ],
                        ),
                        border: Border.all(
                          color: _primary.withValues(alpha: 0.6),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(Icons.auto_stories_rounded,
                          color: _primary, size: 28),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Attiva',
                      style: GoogleFonts.beVietnamPro(
                        color: _primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBioSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('✨', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                'Bio',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _username != null
                ? 'Studente universitario appassionato di sapere. 📚'
                : 'Aggiungi una bio per presentarti ai tuoi compagni.',
            style: GoogleFonts.beVietnamPro(
              color: Colors.white60,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteressiSection() {
    const tagColors = [
      Color(0xFFC4C0FF),
      Color(0xFF5CDBC0),
      Color(0xFFFFB347),
      Color(0xFFFF6584),
      Color(0xFF56CCF2),
    ];
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Interessi di studio',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._subjects.asMap().entries.map((e) {
                final color = tagColors[e.key % tagColors.length];
                return GestureDetector(
                  onLongPress: () => _removeSubject(e.value),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Text(
                      e.value,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 13,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }),
              // Add chip
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: _surfaceHigh,
                      title: Text('Aggiungi materia',
                          style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                      content: TextField(
                        controller: _newSubjectCtrl,
                        focusNode: _subjectFocus,
                        style:
                            GoogleFonts.beVietnamPro(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'es. Analisi 1',
                          hintStyle: GoogleFonts.beVietnamPro(
                              color: Colors.white38),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.06),
                        ),
                        onSubmitted: (_) {
                          _addSubject();
                          Navigator.pop(ctx);
                        },
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text('Annulla',
                              style: GoogleFonts.beVietnamPro(
                                  color: Colors.white54)),
                        ),
                        GestureDetector(
                          onTap: () {
                            _addSubject();
                            Navigator.pop(ctx);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: _primaryDark,
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            child: Text(
                              'Aggiungi',
                              style: GoogleFonts.beVietnamPro(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_rounded,
                          color: Colors.white54, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Aggiungi',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 13,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStileSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Stile di studio',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ti piace il silenzio o vai di cuffie e chiacchiere?',
            style: GoogleFonts.beVietnamPro(
              color: Colors.white54,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Row(
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
        ],
      ),
    );
  }

  Widget _buildSessioneSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sessione di studio',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Avvia una sessione per segnalarti come attivo nel tuo spot.',
            style: GoogleFonts.beVietnamPro(
              color: Colors.white54,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          if (_isStudying) ...[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _secondary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: _secondary,
                      shape: BoxShape.circle,
                    ),
                  )
                      .animate(onPlay: (c) => c.repeat())
                      .fadeOut(duration: 800.ms)
                      .then()
                      .fadeIn(duration: 800.ms),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Stai studiando a ${_studyLocationName ?? ""}',
                      style: GoogleFonts.beVietnamPro(
                          color: _secondary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _stopSession,
              child: Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.stop_rounded,
                        color: Colors.redAccent, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Termina sessione',
                      style: GoogleFonts.beVietnamPro(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else
            GestureDetector(
              onTap: _showStartSessionDialog,
              child: Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  color: _secondary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.play_arrow_rounded,
                        color: _secondary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Avvia sessione di studio',
                      style: GoogleFonts.beVietnamPro(
                        color: _secondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIscrittoSection() {
    final univ = _universityLabel;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Iscritto a',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          if (univ.isNotEmpty)
            Row(
              children: [
                const Icon(Icons.school_outlined,
                    color: Colors.white38, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    univ,
                    style: GoogleFonts.beVietnamPro(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.workspace_premium_rounded,
                  color: Color(0xFFFFB347), size: 18),
              const SizedBox(width: 10),
              Text(
                'Premium Member',
                style: GoogleFonts.beVietnamPro(
                  color: const Color(0xFFFFB347),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _saving ? null : _saveProfile,
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: _secondary,
                borderRadius: BorderRadius.circular(9999),
                boxShadow: [
                  BoxShadow(
                    color: _secondary.withValues(alpha: 0.30),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_saving)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  else
                    const Icon(Icons.edit_rounded,
                        color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    _saving ? 'Salvo...' : 'Modifica Profilo',
                    style: GoogleFonts.beVietnamPro(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: _showUsernameDialog,
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: _primaryDark.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.settings_rounded,
                      color: _primaryDark, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Impostazioni',
                    style: GoogleFonts.beVietnamPro(
                      color: _primaryDark,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: _logout,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(9999),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout_rounded,
                color: Colors.white38, size: 18),
            const SizedBox(width: 8),
            Text(
              'Logout',
              style: GoogleFonts.beVietnamPro(
                color: Colors.white38,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.beVietnamPro(
            color: Colors.white54,
            fontSize: 12,
          ),
        ),
      ],
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
        ? _primaryDark.withValues(alpha: 0.18)
        : Colors.white.withValues(alpha: 0.04);
    final color = selected ? _primary : Colors.white38;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 6),
              Text(
                label,
                style: GoogleFonts.beVietnamPro(
                  color: color,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
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
            style: GoogleFonts.beVietnamPro(
                color: Colors.white.withValues(alpha: 0.75)),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                color: _primaryDark,
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Center(
                child: Text(
                  'Riprova',
                  style: GoogleFonts.beVietnamPro(
                      color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
