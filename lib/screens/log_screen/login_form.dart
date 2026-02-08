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
import 'package:my_mobility_services/data/services/session_service.dart';
import '../../l10n/generated/app_localizations.dart';
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

  // Services
  final SessionService _sessionService = SessionService();

  // UI state
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
        // Mettre à jour la dernière connexion
        await _sessionService.updateLastLogin(uid);
      }

      if (!mounted) return;
      // Confirmer la connexion à l'utilisateur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).welcomeMessage)),
      );
      // Fermer la feuille
      widget.onClose();
      // Navigation immédiate vers l'accueil (en plus du routing par AuthGate)
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
      }
    } on FirebaseAuthException catch (e) {
      String msg;
      switch (e.code) {
        case 'invalid-email':
          msg = 'FORMAT EMAIL INVALIDE\nEmail fourni: ${_emailCtrl.text}\nFormat attendu: xxx@domain.com\nCode erreur Firebase: ${e.code}';
          break;
        case 'user-disabled':
          msg = 'COMPTE DÉSACTIVÉ\nEmail: ${_emailCtrl.text}\nCe compte existe mais a été désactivé par l\'administrateur.\nUID: ${e.credential?.providerId}\nCode: ${e.code}';
          break;
        case 'user-not-found':
          msg = 'AUCUN COMPTE TROUVÉ\nL\'email "${_emailCtrl.text}" n\'existe PAS dans notre base de données.\nBase consultée: Firebase Auth\nCode: ${e.code}\n\nVous pouvez créer un compte avec cet email.';
          break;
        case 'wrong-password':
          msg = 'MOT DE PASSE INCORRECT\nEmail: ${_emailCtrl.text}\n✅ Ce compte EXISTE dans notre système\n❌ Mais le mot de passe est FAUX\n\nDernière tentative de connexion: ${DateTime.now()}\nNombre de caractères du mot de passe fourni: ${_passwordCtrl.text.length}\nCode: ${e.code}\n\nAstuce: Utilisez "Mot de passe oublié"';
          break;
        case 'weak-password':
          msg = 'MOT DE PASSE TROP FAIBLE\nLongueur: ${_passwordCtrl.text.length} caractères\nMinimum requis: 8 caractères\nCode: ${e.code}';
          break;
        case 'network-request-failed':
          msg = 'ERREUR RÉSEAU\nImpossible de contacter Firebase Auth\nServeur: firebaseauth.googleapis.com\nCode: ${e.code}\nVérifiez votre connexion internet';
          break;
        case 'too-many-requests':
          msg = 'TROP DE TENTATIVES\nEmail: ${_emailCtrl.text}\nNombre de tentatives détecté: Limite atteinte\nBlocage temporaire de: 15 minutes\nCode: ${e.code}';
          break;
        default:
          msg = 'ERREUR FIREBASE COMPLÈTE\n\nCode: ${e.code}\nMessage: ${e.message}\nEmail testé: ${_emailCtrl.text}\nStackTrace: ${e.stackTrace}\n\nDétails techniques pour debug:\n${e.toString()}';
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content: Text(msg),
            duration: Duration(seconds: 10),  // Plus long pour lire
            backgroundColor: Colors.red.shade900,
          ),
        );
      }
    } catch (e, stackTrace) {
      // ⚠️ EXPOSITION MAXIMALE DE L'ERREUR ⚠️
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content: Text(
              '💥 ERREUR SYSTÈME COMPLÈTE\n\n'
              'Type: ${e.runtimeType}\n'
              'Message: $e\n'
              'Email: ${_emailCtrl.text}\n'
              'Password length: ${_passwordCtrl.text.length}\n\n'
              'STACK TRACE:\n$stackTrace'
            ),
            duration: Duration(seconds: 15),
            backgroundColor: Colors.red.shade900,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final txt = GoogleFonts.poppins();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        const SheetHandle(),
        Center(
          child: Text(
            AppLocalizations.of(context).welcomeBack,
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
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).enterEmail,
                  labelStyle: const TextStyle(color: Colors.white),
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
                  labelText: AppLocalizations.of(context).enterPassword,
                  labelStyle: const TextStyle(color: Colors.white),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    tooltip: _obscure ? AppLocalizations.of(context).showPassword : AppLocalizations.of(context).hidePassword,
                    icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off, color: AppColors.text),
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
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      // TODO: navigation vers la récupération de mot de passe
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.accent,
                    ),
                    child: Text(AppLocalizations.of(context).forgotPassword),
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
                  child: _isLoading ? const LoadingMBS() : Text(AppLocalizations.of(context).logIn),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        DividerText(AppLocalizations.of(context).orSignInWith),
        const SizedBox(height: 12),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SocialBtn(
              icon: SvgPicture.asset('assets/images/Google__G__logo.svg'),
              tooltip: AppLocalizations.of(context).signInWithGoogle,
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocalizations.of(context).googleSoon)),
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
              tooltip: AppLocalizations.of(context).signInWithApple,
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocalizations.of(context).appleSoon)),
              ),
            ),
            const SizedBox(width: 24),
            SocialBtn(
              icon: SvgPicture.asset('assets/images/2023_Facebook_icon.svg'),
              tooltip: AppLocalizations.of(context).signInWithFacebook,
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocalizations.of(context).facebookSoon)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Center(
          child: RichText(
            text: TextSpan(
              style: txt,
              text: AppLocalizations.of(context).dontHaveAccount,
              children: [
                TextSpan(
                  style: GoogleFonts.poppins(
                    color: AppColors.accent,
                    fontWeight: FontWeight.bold,
                  ),
                  text: AppLocalizations.of(context).signUp,
                  recognizer: _signupTap,
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
