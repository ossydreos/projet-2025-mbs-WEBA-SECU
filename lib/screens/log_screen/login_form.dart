import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_mobility_services/screens/log_screen/welcome_login_screen.dart' show PanelType;
import 'package:my_mobility_services/widgets/buttons/social_buttons.dart';
import 'package:my_mobility_services/widgets/divider_text.dart';
import 'package:my_mobility_services/widgets/sheet_handle.dart';
import 'package:my_mobility_services/widgets/waiting_widget.dart';
import 'package:my_mobility_services/theme/glassmorphism_theme.dart' hide GlassSheet;
class LoginForm extends StatefulWidget {
  const LoginForm({required this.onClose, required this.onSwitch, super.key});

  final void Function(PanelType) onSwitch;
  final VoidCallback onClose;

  @override
  State<LoginForm> createState() => LoginFormState();
}

class LoginFormState extends State<LoginForm> {
  // Clé de Form + contrôleurs de champs
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  // Tap recognizer pour le lien "Sign up"
  late final TapGestureRecognizer _signupTap;

  // UI state
  var _rememberMe = false;
  var _obscure = true;
  var _autovalidate = AutovalidateMode.disabled;
  var _isLoading = false;

  // ====== Anti-emoji ======
  static final RegExp _emojiRegex = RegExp(
    r'[\u{1F300}-\u{1FAFF}\u{1F1E6}-\u{1F1FF}\u{2600}-\u{27BF}\u{FE0F}\u{200D}]',
    unicode: true,
  );
  bool _containsEmoji(String? s) => (s != null) && _emojiRegex.hasMatch(s);
  List<TextInputFormatter> get _antiEmojiFormatters => [
    FilteringTextInputFormatter.deny(_emojiRegex),
  ];

  // ====== Email: format strict (comme signup) ======
  bool _isValidEmail(String? v) {
    if (v == null) return false;
    final email = v.trim();
    if (email.isEmpty) return false;
    if (_containsEmoji(email)) return false;
    final asciiOk = RegExp(r'^[\x21-\x7E]+$');
    if (!asciiOk.hasMatch(email)) return false;
    // qqch@qqch.qq (TLD ≥ 2) et NE finit pas par un point
    final re = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s\.]{2,}$');
    return re.hasMatch(email);
  }

  @override
  void initState() {
    super.initState();
    _signupTap = TapGestureRecognizer()
      ..onTap = () => widget.onSwitch(PanelType.signup);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _signupTap.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_isLoading) return;

    FocusScope.of(context).unfocus();
    setState(() => _autovalidate = AutovalidateMode.always);

    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    final email = _emailCtrl.text.trim().toLowerCase().replaceAll(
      _emojiRegex,
      '',
    );
    final password = _passwordCtrl.text.replaceAll(_emojiRegex, '');

    try {
      if (password.length < 8) {
        throw FirebaseAuthException(
          code: 'weak-password',
          message: '8 caractères minimum',
        );
      }

      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = cred.user?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'lastLoginAt': FieldValue.serverTimestamp(),
          if (_rememberMe) 'rememberMe': true,
        }, SetOptions(merge: true));
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Bienvenue 👋')));

      widget.onClose();
    } on FirebaseAuthException catch (e) {
      String msg;
      switch (e.code) {
        case 'invalid-email':
          msg = 'Email invalide';
          break;
        case 'user-disabled':
          msg = 'Compte désactivé';
          break;
        case 'user-not-found':
          msg = 'Aucun compte pour cet email';
          break;
        case 'wrong-password':
          msg = 'Mot de passe incorrect';
          break;
        case 'weak-password':
          msg = 'Mot de passe trop faible';
          break;
        case 'network-request-failed':
          msg = 'Pas de connexion réseau';
          break;
        case 'too-many-requests':
          msg = 'Trop de tentatives, réessaie plus tard';
          break;
        default:
          msg = 'Erreur: ${e.message ?? e.code}';
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final txt = GoogleFonts.poppins();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SheetHandle(),
        Center(
          child: Text(
            'Welcome Back',
            style: txt.copyWith(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 14),

        Form(
          key: _formKey,
          autovalidateMode: _autovalidate,
          child: Column(
            children: [
              TextFormField(
                controller: _emailCtrl,
                inputFormatters: _antiEmojiFormatters,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Enter email',
                  labelStyle: TextStyle(color: Colors.white),
                ),
                validator: (v) => _isValidEmail(v)
                    ? null
                    : 'Email invalide (ex: nom@domaine.tld)',
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _passwordCtrl,
                inputFormatters: _antiEmojiFormatters,
                style: const TextStyle(color: Colors.white),
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Enter password',
                  labelStyle: const TextStyle(color: Colors.white),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    tooltip: _obscure ? 'Show password' : 'Hide password',
                    icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off, color: Brand.text),
                  ),
                ),
                validator: (v) =>
                    (v == null || v.length < 8) ? '8 caractères minimum' : null,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) async => _isLoading ? null : _login(),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Checkbox(
                    value: _rememberMe,
                    onChanged: (v) => setState(() => _rememberMe = v ?? false),
                    activeColor: Brand.accent,
                    side: const BorderSide(
                      color: Color.fromRGBO(255, 255, 255, 0.6),
                    ),
                  ),
                  Text('Remember me', style: txt.copyWith(color: Colors.white)),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      // TODO: navigation vers la récupération de mot de passe
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Brand.accent,
                    ),
                    child: const Text('Forgot password?'),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Bouton de connexion
              SizedBox(
                height: 54,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          setState(
                            () => _autovalidate = AutovalidateMode.always,
                          );
                          await _login();
                        },
                  child: _isLoading ? const LoadingMBS() : const Text('Log In'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        const DividerText('or sign in with'),
        const SizedBox(height: 12),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SocialBtn(
              icon: SvgPicture.asset('assets/images/Google__G__logo.svg'),
              tooltip: 'Sign in with Google',
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Google: bientôt dispo')),
              ),
            ),
            const SizedBox(width: 24),
            SocialBtn(
              icon: SvgPicture.asset(
                'assets/images/Apple_logo_black.svg',
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
              tooltip: 'Sign in with Apple',
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Apple: bientôt dispo')),
              ),
            ),
            const SizedBox(width: 24),
            SocialBtn(
              icon: SvgPicture.asset('assets/images/2023_Facebook_icon.svg'),
              tooltip: 'Sign in with Facebook',
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Facebook: bientôt dispo')),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Center(
          child: RichText(
            text: TextSpan(
              style: txt,
              text: 'Dont have an account? ',
              children: [
                TextSpan(
                  style: GoogleFonts.poppins(
                    color: Brand.accent,
                    fontWeight: FontWeight.bold,
                  ),
                  text: 'Sign up',
                  recognizer: _signupTap,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
