import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'services/api_service.dart';
import 'services/notification_service.dart';
import 'main_navigator.dart';
import 'screens/widgets/avatar_widget.dart';

// ── Design system ─────────────────────────────────────
const _bg = Color(0xFF131313);
const _surface = Color(0xFF1E1E1E);
const _surfaceHigh = Color(0xFF2A2A2A);
const _primary = Color(0xFFC4C0FF);
const _primaryDark = Color(0xFF8781FF);
const _secondary = Color(0xFF5CDBC0);

// ── Predefined subjects ────────────────────────────────
const _kSubjects = [
  'Architettura', 'Design', 'Ingegneria', 'Economia',
  'Medicina', 'Lettere', 'Informatica', 'Fisica',
  'Chimica', 'Storia',
];

// ──────────────────────────────────────────────────────
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  runApp(const StudyMatchApp());
}

class StudyMatchApp extends StatelessWidget {
  const StudyMatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    ApiService.onUnauthorized = () {
      ApiService.setToken(null);
      final nav = AppNav.rootNavigatorKey.currentState;
      if (nav == null) return;
      nav.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    };

    return MaterialApp(
      navigatorKey: AppNav.rootNavigatorKey,
      title: 'Incontro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: _bg,
        colorScheme: const ColorScheme.dark(primary: _primaryDark),
        textTheme: GoogleFonts.beVietnamProTextTheme(
            ThemeData.dark().textTheme),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleTextStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: _surfaceHigh.withValues(alpha: 0.96),
          contentTextStyle: GoogleFonts.beVietnamPro(color: Colors.white),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9999),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9999),
            borderSide: const BorderSide(color: _primaryDark, width: 1.5),
          ),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

// ──────────────────────────────────────────────────────
// AUTH GATE
// ──────────────────────────────────────────────────────
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return ApiService.token == null
        ? const LoginScreen()
        : const MainNavigator();
  }
}

// ──────────────────────────────────────────────────────
// LOGIN SCREEN
// ──────────────────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _showPass = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await ApiService.login(
          _emailCtrl.text.trim(), _passCtrl.text);
      ApiService.setToken(token);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigator()),
        );
      }
    } catch (e) {
      setState(
          () => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 48),

                // ── Logo ──
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_primaryDark, _secondary],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _primaryDark.withValues(alpha: 0.4),
                        blurRadius: 28,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.school_rounded,
                      color: Colors.white, size: 44),
                ),
                const SizedBox(height: 24),

                // ── Title ──
                Text(
                  'Incontro',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Trova il tuo compagno di studio',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 15,
                    color: Colors.white54,
                  ),
                ),
                const SizedBox(height: 40),

                // ── Email ──
                _DarkField(
                  controller: _emailCtrl,
                  hint: 'Email',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 14),

                // ── Password ──
                _DarkField(
                  controller: _passCtrl,
                  hint: 'Password',
                  prefixIcon: Icons.lock_outline_rounded,
                  obscure: !_showPass,
                  suffixIcon: GestureDetector(
                    onTap: () => setState(() => _showPass = !_showPass),
                    child: Icon(
                      _showPass
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.white38,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // ── Forgot password ──
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Hai dimenticato la password?',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 13,
                      color: Colors.white38,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // ── Error ──
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: Colors.redAccent, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: GoogleFonts.beVietnamPro(
                                color: Colors.redAccent, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // ── Accedi button ──
                _PrimaryButton(
                  label: 'Accedi',
                  loading: _loading,
                  onTap: _login,
                ),
                const SizedBox(height: 24),

                // ── Divider ──
                Row(
                  children: [
                    Expanded(
                        child: Divider(
                            color: Colors.white.withValues(alpha: 0.10),
                            thickness: 1)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        'OPPURE',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 11,
                          color: Colors.white38,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                        child: Divider(
                            color: Colors.white.withValues(alpha: 0.10),
                            thickness: 1)),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Google button ──
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    width: double.infinity,
                    height: 54,
                    decoration: BoxDecoration(
                      color: _surfaceHigh,
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _GoogleLogo(),
                        const SizedBox(width: 12),
                        Text(
                          'Accedi con Google',
                          style: GoogleFonts.beVietnamPro(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // ── Register link ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Nuovo?  ',
                      style: GoogleFonts.beVietnamPro(
                        color: Colors.white54,
                        fontSize: 14,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ProfileSetupScreen()),
                        );
                      },
                      child: Text(
                        'Registrati',
                        style: GoogleFonts.beVietnamPro(
                          color: _primaryDark,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────
// PROFILE SETUP SCREEN — 3-step wizard
// ──────────────────────────────────────────────────────
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  int _step = 0; // 0=email+pass, 1=username, 2=materie+stile

  // Step 0
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _showPass = false;

  // Step 1
  final _usernameCtrl = TextEditingController();
  String? _usernameStatus; // 'checking' | 'available' | 'taken' | null
  Timer? _debounce;
  String? _avatarBase64;

  // Step 2
  final Set<String> _selectedSubjects = {};
  final List<String> _customSubjects = [];
  String _style = 'Silenzioso';
  final _ageCtrl = TextEditingController();
  final _univCtrl = TextEditingController();

  bool _loading = false;
  String? _error;

  static final _usernameRe = RegExp(r'^[a-zA-Z0-9_]*$');

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _usernameCtrl.dispose();
    _ageCtrl.dispose();
    _univCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  List<String> get _allSubjects => [..._kSubjects, ..._customSubjects];

  List<String> get _finalSubjects => [
        ..._selectedSubjects,
        ..._customSubjects.where((s) => !_selectedSubjects.contains(s)),
      ];

  // ── Step 0: Register ──────────────────────────────
  Future<void> _doRegister() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    if (email.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Compila tutti i campi');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await ApiService.register(email, pass);
      ApiService.setToken(token);
      if (mounted) setState(() { _step = 1; _loading = false; });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  // ── Step 1: Username check + continue ────────────
  void _onUsernameChanged(String val) {
    _debounce?.cancel();
    if (!_usernameRe.hasMatch(val) || val.length < 3) {
      setState(() => _usernameStatus = null);
      return;
    }
    setState(() => _usernameStatus = 'checking');
    _debounce = Timer(const Duration(milliseconds: 600), () async {
      try {
        await ApiService.getUserByUsername(val.toLowerCase());
        if (mounted) setState(() => _usernameStatus = 'taken');
      } catch (_) {
        if (mounted) setState(() => _usernameStatus = 'available');
      }
    });
  }

  Future<void> _doStep1() async {
    final uname = _usernameCtrl.text.trim();
    if (_usernameStatus == 'taken') {
      setState(() => _error = 'Username non disponibile');
      return;
    }
    setState(() { _loading = true; _error = null; });
    if (uname.length >= 3) {
      try { await ApiService.updateUsername(uname); } catch (_) {}
    }
    if (_avatarBase64 != null) {
      try { await ApiService.updateAvatar(_avatarBase64!); } catch (_) {}
    }
    if (mounted) setState(() { _step = 2; _loading = false; });
  }

  // ── Step 2: Save profile ──────────────────────────
  Future<void> _doSave() async {
    final subjects = _finalSubjects;
    if (subjects.isEmpty) {
      setState(() => _error = 'Seleziona almeno una materia');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await ApiService.updateProfile(subjects, _style);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigator()),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _pickAvatar() async {
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
      setState(() => _avatarBase64 = base64Encode(bytes));
    } catch (_) {}
  }

  void _addCustomSubject() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surfaceHigh,
        title: Text('Aggiungi materia',
            style: GoogleFonts.plusJakartaSans(
                color: Colors.white, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          style: GoogleFonts.beVietnamPro(color: Colors.white),
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'es. Astronomia',
            hintStyle:
                GoogleFonts.beVietnamPro(color: Colors.white38),
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
              final val = ctrl.text.trim();
              if (val.isNotEmpty) {
                setState(() {
                  _customSubjects.add(val);
                  _selectedSubjects.add(val);
                });
              }
              Navigator.pop(ctx);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 9),
              decoration: BoxDecoration(
                color: _primaryDark,
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Text('Aggiungi',
                  style: GoogleFonts.beVietnamPro(
                      color: Colors.white,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Top progress bar ──────────────────────────────
  Widget _buildProgress() {
    final labels = ['INIZIA', 'USERNAME', 'QUASI FINITO'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Passaggio ${_step + 1} di 3',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 13,
                  color: Colors.white54,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                labels[_step],
                style: GoogleFonts.beVietnamPro(
                  fontSize: 11,
                  color: _primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(3, (i) {
              final filled = i <= _step;
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: filled
                        ? _primaryDark
                        : Colors.white.withValues(alpha: 0.12),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ── Step 0: Email + Password ──────────────────────
  Widget _buildStep0() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Text(
            'Crea il tuo account',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Inizia a trovare compagni di studio.',
            style: GoogleFonts.beVietnamPro(
              fontSize: 15,
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 32),
          _DarkField(
            controller: _emailCtrl,
            hint: 'Email istituzionale',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 14),
          _DarkField(
            controller: _passCtrl,
            hint: 'Password',
            prefixIcon: Icons.lock_outline_rounded,
            obscure: !_showPass,
            suffixIcon: GestureDetector(
              onTap: () => setState(() => _showPass = !_showPass),
              child: Icon(
                _showPass
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: Colors.white38,
                size: 20,
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            _ErrorBanner(message: _error!),
          ],
          const SizedBox(height: 28),
          _PrimaryButton(
              label: 'Continua', loading: _loading, onTap: _doRegister),
          const SizedBox(height: 16),
          _BackButton(onTap: () => Navigator.pop(context)),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Step 1: @username + avatar ────────────────────
  Widget _buildStep1() {
    final uname = _usernameCtrl.text;
    final fallback = uname.isNotEmpty ? uname[0].toUpperCase() : 'S';
    Widget? statusWidget;
    Widget? statusSuffix;

    if (_usernameStatus == 'checking') {
      statusSuffix = const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
            color: Colors.white38, strokeWidth: 2),
      );
    } else if (_usernameStatus == 'available') {
      statusSuffix = const Icon(Icons.check_circle_rounded,
          color: Color(0xFF5CDBC0), size: 20);
      statusWidget = Padding(
        padding: const EdgeInsets.only(top: 6, left: 4),
        child: Text('Disponibile ✓',
            style: GoogleFonts.beVietnamPro(
                color: _secondary, fontSize: 12)),
      );
    } else if (_usernameStatus == 'taken') {
      statusSuffix = const Icon(Icons.cancel_rounded,
          color: Colors.redAccent, size: 20);
      statusWidget = Padding(
        padding: const EdgeInsets.only(top: 6, left: 4),
        child: Text('Username già in uso',
            style: GoogleFonts.beVietnamPro(
                color: Colors.redAccent, fontSize: 12)),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Text(
            'Il tuo username',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Scegli come vuoi essere conosciuto.',
            style: GoogleFonts.beVietnamPro(
              fontSize: 15,
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 28),

          // Avatar picker
          Center(
            child: GestureDetector(
              onTap: _pickAvatar,
              child: Stack(
                children: [
                  AvatarWidget(
                    base64Image: _avatarBase64,
                    fallbackLetter: fallback,
                    radius: 46,
                    hasActiveStory: false,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 28,
                      height: 28,
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
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Foto profilo (opzionale)',
              style: GoogleFonts.beVietnamPro(
                  color: Colors.white38, fontSize: 12),
            ),
          ),
          const SizedBox(height: 20),

          // Username field
          Container(
            decoration: BoxDecoration(
              color: _surfaceHigh,
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 20, right: 4),
                  child: Text(
                    '@',
                    style: GoogleFonts.plusJakartaSans(
                      color: _primaryDark,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _usernameCtrl,
                    style: GoogleFonts.beVietnamPro(
                        color: Colors.white, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'username',
                      hintStyle: GoogleFonts.beVietnamPro(
                          color: Colors.white38),
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 4),
                      suffixIcon: statusSuffix != null
                          ? Padding(
                              padding: const EdgeInsets.only(right: 16),
                              child: statusSuffix,
                            )
                          : null,
                      suffixIconConstraints: const BoxConstraints(
                          minWidth: 0, minHeight: 0),
                    ),
                    onChanged: _onUsernameChanged,
                  ),
                ),
              ],
            ),
          ),
          ?statusWidget,

          if (_error != null) ...[
            const SizedBox(height: 12),
            _ErrorBanner(message: _error!),
          ],
          const SizedBox(height: 28),
          _PrimaryButton(
              label: 'Continua', loading: _loading, onTap: _doStep1),
          const SizedBox(height: 16),
          _BackButton(
              onTap: () => setState(() { _step = 0; _error = null; })),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Step 2: Materie + Stile + Età + Università ────
  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 28),
          Text(
            'Personalizza il tuo profilo',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Aiutaci a farti incontrare le persone giuste in università.',
            style: GoogleFonts.beVietnamPro(
              fontSize: 14,
              color: Colors.white54,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),

          // ── Materie di Studio ──
          Row(
            children: [
              Text(
                'Materie di Studio',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _secondary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'MULTIPLA',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 10,
                    color: _secondary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._allSubjects.map((subject) {
                final selected = _selectedSubjects.contains(subject);
                return GestureDetector(
                  onTap: () => setState(() {
                    if (selected) {
                      _selectedSubjects.remove(subject);
                    } else {
                      _selectedSubjects.add(subject);
                    }
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? _primaryDark
                          : _surfaceHigh,
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Text(
                      subject,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 13,
                        color:
                            selected ? Colors.white : Colors.white70,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }),
              // + Altro
              GestureDetector(
                onTap: _addCustomSubject,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_rounded,
                          color: Colors.white54, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Altro',
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
          const SizedBox(height: 24),

          // ── Stile di Studio ──
          Text(
            'Stile di Studio',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: _surfaceHigh,
              borderRadius: BorderRadius.circular(9999),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: ['Silenzioso', 'Rumoroso'].map((s) {
                final selected = _style == s;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _style = s),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding:
                          const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: selected ? _surface : Colors.transparent,
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            s == 'Silenzioso' ? '📚' : '🎧',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            s,
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 14,
                              color: selected
                                  ? Colors.white
                                  : Colors.white54,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // ── Età + Università (optional) ──
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ETÀ (OPZIONALE)',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 11,
                        color: Colors.white54,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: _surfaceHigh,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: TextField(
                        controller: _ageCtrl,
                        style: GoogleFonts.beVietnamPro(
                            color: Colors.white),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Es. 21',
                          hintStyle: GoogleFonts.beVietnamPro(
                              color: Colors.white38),
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'UNIVERSITÀ (OPZIONALE)',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 11,
                        color: Colors.white54,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: _surfaceHigh,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: TextField(
                        controller: _univCtrl,
                        style: GoogleFonts.beVietnamPro(
                            color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Polimi, Unimi...',
                          hintStyle: GoogleFonts.beVietnamPro(
                              color: Colors.white38),
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (_error != null) ...[
            const SizedBox(height: 14),
            _ErrorBanner(message: _error!),
          ],
          const SizedBox(height: 28),
          _PrimaryButton(
              label: 'Continua', loading: _loading, onTap: _doSave),
          const SizedBox(height: 16),
          _BackButton(
              onTap: () => setState(() { _step = 1; _error = null; })),
          const SizedBox(height: 16),

          // Footer
          Center(
            child: Text(
              'Incontro © 2024 • Progettato per l\'eccellenza accademica',
              textAlign: TextAlign.center,
              style: GoogleFonts.beVietnamPro(
                fontSize: 11,
                color: Colors.white24,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── AppBar ──
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (_step == 0) {
                        Navigator.pop(context);
                      } else {
                        setState(() { _step--; _error = null; });
                      }
                    },
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 20),
                  ),
                  ShaderMask(
                    shaderCallback: (r) => const LinearGradient(
                      colors: [_primary, _secondary],
                    ).createShader(r),
                    child: Text(
                      'Incontro',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Progress ──
            _buildProgress(),
            const SizedBox(height: 4),

            // ── Content ──
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.04, 0),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                child: KeyedSubtree(
                  key: ValueKey(_step),
                  child: _step == 0
                      ? _buildStep0()
                      : _step == 1
                          ? _buildStep1()
                          : _buildStep2(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────
// SHARED WIDGETS
// ──────────────────────────────────────────────────────

class _DarkField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData prefixIcon;
  final bool obscure;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;

  const _DarkField({
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    this.obscure = false,
    this.keyboardType,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceHigh,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: GoogleFonts.beVietnamPro(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              GoogleFonts.beVietnamPro(color: Colors.white38, fontSize: 15),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 18, right: 10),
            child: Icon(prefixIcon, color: Colors.white38, size: 20),
          ),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 0, minHeight: 0),
          suffixIcon: suffixIcon != null
              ? Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: suffixIcon,
                )
              : null,
          suffixIconConstraints:
              const BoxConstraints(minWidth: 0, minHeight: 0),
          border: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9999),
            borderSide: const BorderSide(color: _primaryDark, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 20,
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onTap;

  const _PrimaryButton({
    required this.label,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          color: loading
              ? _primaryDark.withValues(alpha: 0.5)
              : _primaryDark,
          borderRadius: BorderRadius.circular(9999),
          boxShadow: loading
              ? []
              : [
                  BoxShadow(
                    color: _primaryDark.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
              : Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Center(
        child: Text(
          'Indietro',
          style: GoogleFonts.beVietnamPro(
            fontSize: 14,
            color: Colors.white54,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Colors.redAccent, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.beVietnamPro(
                  color: Colors.redAccent, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
          Center(
            child: RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: 'G',
                    style: TextStyle(
                      color: Color(0xFF4285F4),
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
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
}
