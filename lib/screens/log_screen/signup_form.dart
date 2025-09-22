import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:my_mobility_services/widgets/buttons/social_buttons.dart';
import 'package:my_mobility_services/widgets/divider_text.dart';
import 'package:my_mobility_services/widgets/sheet_handle.dart';
import 'package:my_mobility_services/widgets/waiting_widget.dart';
import 'package:my_mobility_services/screens/log_screen/welcome_login_screen.dart'
    show PanelType;
import 'package:my_mobility_services/theme/glassmorphism_theme.dart' hide GlassSheet;
import '../../l10n/generated/app_localizations.dart';

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
  final _phoneCtrl = TextEditingController();

  late final TapGestureRecognizer _loginTap;
  bool _isLoading = false;
  bool _obscurePassword = true;
  CountryCode? _selectedCountry;


  static final RegExp _emojiRegex = RegExp(
    r'[\u{1F300}-\u{1FAFF}\u{1F1E6}-\u{1F1FF}\u{2600}-\u{27BF}\u{FE0F}\u{200D}]',
    unicode: true,
  );
  bool _containsEmoji(String? s) => (s != null) && _emojiRegex.hasMatch(s);

  // ====== Email: format strict, pas d'emoji, pas d'Unicode exotique ======
  // - pas d'espaces
  // - au moins 1 char avant @
  // - au moins 1 char entre @ et le dernier point
  // - TLD >= 2 et l'email NE finit PAS par un point
  // - on refuse les emojis et on force ASCII imprimable de base
  bool _isValidEmail(String? v) {
    if (v == null) return false;
    final email = v.trim();
    if (email.isEmpty) return false;
    if (_containsEmoji(email)) return false;

    final asciiOk = RegExp(r'^[\x21-\x7E]+$');
    if (!asciiOk.hasMatch(email)) return false;

    final re = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s\.]{2,}$');
    return re.hasMatch(email);
  }

  // ====== Validation numéro de téléphone (chiffres seulement) ======
  bool _isValidPhone(String? v) {
    if (v == null) return false;
    final phone = v.trim().replaceAll(RegExp(r'[\s\-\.]'), '');
    if (phone.isEmpty) return false;
    if (_containsEmoji(phone)) return false;

    // Format simple : 7 à 15 chiffres seulement
    final phoneRegex = RegExp(r'^\d{7,15}$');
    return phoneRegex.hasMatch(phone);
  }

  // Petites helpers pour formatters
  List<TextInputFormatter> get _antiEmojiFormatters => [
    FilteringTextInputFormatter.deny(_emojiRegex),
  ];

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
    _phoneCtrl.dispose();
    _loginTap.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isLoading) return;

    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    // Sanitize (parano) : retire toute trace d'emoji avant envoi Firebase
    String name = _nameCtrl.text.trim().replaceAll(_emojiRegex, '');
    String email = _emailCtrl.text.trim().toLowerCase().replaceAll(
      _emojiRegex,
      '',
    );
    String password = _passwordCtrl.text.replaceAll(_emojiRegex, '');
    String phone = _phoneCtrl.text.trim().replaceAll(_emojiRegex, '');
    String fullPhone = '${_selectedCountry?.dialCode ?? '+33'}$phone';
    
    // Debug: vérifier la concaténation
    print('DEBUG - Indicatif: ${_selectedCountry?.dialCode ?? '+33'}');
    print('DEBUG - Pays: ${_selectedCountry?.name ?? 'France'}');
    print('DEBUG - Numéro: $phone');
    print('DEBUG - Numéro complet: $fullPhone');

    try {
      if (password.length < 8) {
        throw FirebaseAuthException(
          code: 'weak-password',
          message: '8 caractères minimum',
        );
      }

      // Vérifier l'unicité du numéro de téléphone
      if (phone.isNotEmpty) {
        final phoneQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('phone', isEqualTo: fullPhone)
            .get();
        
        if (phoneQuery.docs.isNotEmpty) {
          throw FirebaseAuthException(
            code: 'phone-already-in-use',
            message: 'Ce numéro de téléphone est déjà utilisé',
          );
        }
      }

      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await cred.user?.updateDisplayName(name);
      await cred.user?.reload();

      await cred.user?.sendEmailVerification();

      final uid = cred.user?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'uid': uid,
          'email': email,
          'provider': 'password',
          'emailVerified': cred.user?.emailVerified ?? false,
          'createdAt': FieldValue.serverTimestamp(),
          if (name.isNotEmpty) 'name': name,
          if (phone.isNotEmpty) 'phone': fullPhone,
          if (phone.isNotEmpty) 'countryCode': _selectedCountry?.dialCode ?? '+33',
          if (phone.isNotEmpty) 'countryName': _selectedCountry?.name ?? 'France',
        }, SetOptions(merge: true));
        
        // Debug: confirmer la sauvegarde
        print('DEBUG - Sauvegarde Firestore réussie:');
        print('  - phone: $fullPhone');
        print('  - countryCode: ${_selectedCountry?.dialCode ?? '+33'}');
        print('  - countryName: ${_selectedCountry?.name ?? 'France'}');
      }

      if (!mounted) return;
      widget.onSwitch(PanelType.login);
    } on FirebaseAuthException catch (e) {
      String msg;
      switch (e.code) {
        case 'email-already-in-use':
          msg = 'Cet email est déjà utilisé';
          break;
        case 'phone-already-in-use':
          msg = 'Ce numéro de téléphone est déjà utilisé';
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
        ).showSnackBar(SnackBar(content: Text('${AppLocalizations.of(context).errorUnknownError}: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final txt = GoogleFonts.poppins();

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.disabled,
      child: Column(
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

          TextFormField(
            controller: _nameCtrl,
            inputFormatters: _antiEmojiFormatters,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Nom complet',
              labelStyle: TextStyle(color: Colors.white),
              hintText: 'Ex: Jean Dupont',
              hintStyle: TextStyle(color: Colors.white54),
            ),
            validator: (v) {
              final s = v?.trim() ?? '';
              if (s.length < 4) return 'Minimum 4 caractères';
              if (_containsEmoji(s)) return 'Les emojis ne sont pas autorisés';
              return null;
            },
            onEditingComplete: () => FocusScope.of(context).nextFocus(),
          ),
          const SizedBox(height: 12),

          TextFormField(
            controller: _emailCtrl,
            inputFormatters: _antiEmojiFormatters,
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Adresse email',
              labelStyle: TextStyle(color: Colors.white),
              hintText: 'Ex: jean.dupont@email.com',
              hintStyle: TextStyle(color: Colors.white54),
            ),
            validator: (v) => _isValidEmail(v)
                ? null
                : 'Format email invalide',
            onEditingComplete: () => FocusScope.of(context).nextFocus(),
          ),
          const SizedBox(height: 12),

          // Numéro de téléphone avec sélecteur de pays intégré
          TextFormField(
            controller: _phoneCtrl,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(15),
            ],
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.phone,
            autofillHints: const [AutofillHints.telephoneNumber],
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Numéro de téléphone',
              labelStyle: const TextStyle(color: Colors.white),
              hintText: 'Ex: 612345678',
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: CountryCodePicker(
                onChanged: (CountryCode countryCode) {
                  setState(() {
                    _selectedCountry = countryCode;
                  });
                },
                initialSelection: _selectedCountry?.code ?? 'FR',
                favorite: const ['FR', 'US', 'GB', 'DE', 'ES', 'IT'],
                showCountryOnly: false,
                showOnlyCountryWhenClosed: false,
                alignLeft: false,
                showFlag: true,
                showFlagMain: true,
                showFlagDialog: true,
                hideMainText: false,
                showDropDownButton: true,
                flagWidth: 25.0,
                textStyle: const TextStyle(color: Colors.white, fontSize: 16),
                dialogTextStyle: const TextStyle(color: Colors.white, fontSize: 16),
                searchStyle: const TextStyle(color: Colors.white, fontSize: 16),
                dialogBackgroundColor: const Color(0xFF1E1E1E),
                barrierColor: Colors.black54,
                searchDecoration: const InputDecoration(
                  hintText: 'Rechercher un pays...',
                  hintStyle: TextStyle(color: Colors.white54),
                  border: OutlineInputBorder(),
                ),
                dialogSize: Size(MediaQuery.of(context).size.width * 0.9, MediaQuery.of(context).size.height * 0.7),
              ),
            ),
            validator: (v) => _isValidPhone(v) ? null : 'Numéro invalide',
            onEditingComplete: () => FocusScope.of(context).nextFocus(),
          ),
          const SizedBox(height: 12),

          TextFormField(
            controller: _passwordCtrl,
            inputFormatters: _antiEmojiFormatters,
            textInputAction: TextInputAction.done,
            obscureText: _obscurePassword,
            autofillHints: const [AutofillHints.newPassword],
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Mot de passe',
              labelStyle: const TextStyle(color: Colors.white),
              hintText: 'Ex: MonMotDePasse123!',
              hintStyle: const TextStyle(color: Colors.white54),
              suffixIcon: IconButton(
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                tooltip: _obscurePassword ? 'Afficher' : 'Masquer',
              ),
            ),
            validator: (v) {
              if (v == null || v.length < 8) return 'Minimum 8 caractères';
              if (_containsEmoji(v)) return 'Les emojis ne sont pas autorisés';
              return null;
            },
            onFieldSubmitted: (_) async {
              if (_isLoading) return;
              await _submit();
            },
          ),
          const SizedBox(height: 16),

          SizedBox(
            height: 54,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const LoadingMBS()
                  : Text(AppLocalizations.of(context).getStarted),
            ),
          ),

          const SizedBox(height: 24),
          DividerText(AppLocalizations.of(context).orSignUpWith),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SocialBtn(
                icon: SvgPicture.asset('assets/images/Google__G__logo.svg'),
                tooltip: 'Sign in with Google',
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
                tooltip: 'Sign in with Apple',
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context).appleSoon)),
                ),
              ),
              const SizedBox(width: 24),
              SocialBtn(
                icon: SvgPicture.asset('assets/images/2023_Facebook_icon.svg'),
                tooltip: 'Sign in with Facebook',
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
                style: txt.copyWith(color: Colors.white),
                text: 'Already have an account? ',
                children: [
                  TextSpan(
                    style: GoogleFonts.poppins(
                      color: AppColors.accent,
                      fontWeight: FontWeight.bold,
                    ),
                    text: 'Login',
                    recognizer: _loginTap,
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
