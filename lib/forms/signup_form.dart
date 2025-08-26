import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_mobility_services/theme/theme_app.dart' show AppColors;
import 'package:my_mobility_services/widgets/buttons/social_buttons.dart';
import 'package:my_mobility_services/widgets/divider_text.dart';
import 'package:my_mobility_services/widgets/sheet_handle.dart';
import 'package:my_mobility_services/widgets/waiting_widget.dart';
import 'package:my_mobility_services/screens/welcome_login_screen.dart'
    show PanelType;

class SignupForm extends StatefulWidget {
  const SignupForm({required this.onClose, required this.onSwitch, super.key});
  final VoidCallback onClose;
  final void Function(PanelType) onSwitch;

  @override
  State<SignupForm> createState() => SignupFormState();
}

class SignupFormState extends State<SignupForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  late final TapGestureRecognizer _loginTap;
  var _autovalidate = AutovalidateMode.disabled;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loginTap = TapGestureRecognizer()
      ..onTap = () => widget.onSwitch(PanelType.login);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _loginTap.dispose();
    super.dispose();
  }

  bool _isEmailValid(String email) {
    final emailRegex = RegExp(
      r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@"
      r"[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?"
      r"(?:\.[a-zA-Z]{2,})+$",
    );
    return emailRegex.hasMatch(email);
  }

  String? _passwordError(String? v) {
    if (v == null || v.isEmpty) return 'Mot de passe requis';
    if (v.length < 8) return 'Au moins 8 caractères';
    if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Doit contenir une majuscule';
    if (!RegExp(r'[a-z]').hasMatch(v)) return 'Doit contenir une minuscule';
    if (!RegExp(r'\d').hasMatch(v)) return 'Doit contenir un chiffre';
    if (!RegExp(
      "[~!@#\\\$%\\^&*()\\-+=\\[\\]{}|\\\\:;\"'<>,\\.\\?/]",
    ).hasMatch(v)) {
      return 'Doit contenir un caractère spécial';
    }
    return null;
  }

  Future<void> _submit() async {
    setState(() {
      _autovalidate = AutovalidateMode.always;
      _isLoading = true;
    });

    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim().toLowerCase();
    final password = _passwordCtrl.text;

    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await cred.user?.updateDisplayName(name);

      final uid = cred.user?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'name': name,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Compte créé ✔')));
      }
    } on FirebaseAuthException catch (e) {
      String msg;
      switch (e.code) {
        case 'email-already-in-use':
          msg = 'Cet email est déjà utilisé';
          break;
        case 'weak-password':
          msg = 'Mot de passe trop faible';
          break;
        case 'invalid-email':
          msg = 'Email invalide';
          break;
        case 'operation-not-allowed':
          msg = 'Inscription désactivée pour ce projet';
          break;
        default:
          msg = 'Erreur: ${e.message ?? e.code}';
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
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
            'Create Your Account',
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
                controller: _nameCtrl,
                textInputAction: TextInputAction.next,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Enter name',
                  labelStyle: TextStyle(color: Colors.white),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Nom requis';
                  if (v.trim().length < 2) return 'Nom trop court';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailCtrl,
                textInputAction: TextInputAction.next,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  labelText: 'Enter email',
                  labelStyle: TextStyle(color: Colors.white),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Email requis';
                  return _isEmailValid(v.trim()) ? null : 'Email invalide';
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordCtrl,
                textInputAction: TextInputAction.done,
                style: const TextStyle(color: Colors.white),
                obscureText: _obscurePassword,
                autofillHints: const [AutofillHints.newPassword],
                onFieldSubmitted: (_) => !_isLoading ? _submit() : null,
                decoration: InputDecoration(
                  labelText: 'Create password',
                  labelStyle: const TextStyle(color: Colors.white),
                  suffixIcon: IconButton(
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                  ),
                ),
                validator: _passwordError,
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 54,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const LoadingMBS()
                      : const Text('Get Started'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const DividerText('or sign up with'),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SocialBtn(
              icon: SvgPicture.asset('assets/images/Google__G__logo.svg'),
              tooltip: 'Sign in with Google',
              // onTap: () => signInWithGoogle(),
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
              // onTap: () => signInWithApple(),
            ),
            const SizedBox(width: 24),
            SocialBtn(
              icon: SvgPicture.asset('assets/images/2023_Facebook_icon.svg'),
              tooltip: 'Sign in with Facebook',
              onTap: () {}, // TODO: implémenter
            ),
          ],
        ),
        const SizedBox(height: 12),
        Center(
          child: RichText(
            text: TextSpan(
              style: txt.copyWith(color: Colors.white),
              text: 'Already have an account? ',
              children: [
                TextSpan(
                  style: GoogleFonts.poppins(
                    color: AppColors.accent,
                    fontWeight: FontWeight.bold,
                  ),
                  text: 'Login',
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => widget.onSwitch(PanelType.signup),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
