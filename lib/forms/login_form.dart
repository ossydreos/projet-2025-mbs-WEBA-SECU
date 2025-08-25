import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_mobility_services/screens/welcome_login_screen.dart';
import 'package:my_mobility_services/widgets/buttons/social_buttons.dart';
import 'package:my_mobility_services/widgets/divider_text.dart';
import 'package:my_mobility_services/widgets/sheet_handle.dart';
import '../theme/theme_app.dart';

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

  // UI state
  var _rememberMe = false;
  var _obscure = true;
  var _autovalidate = AutovalidateMode.disabled;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final txt = GoogleFonts.poppins();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetHandle(),
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

        // ----------- Formulaire -----------
        Form(
          key: _formKey,
          autovalidateMode: _autovalidate,
          child: Column(
            children: [
              // Champ email
              TextFormField(
                controller: _emailCtrl,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Enter email',
                  labelStyle: TextStyle(color: Colors.white),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Email requis';
                  // Très simple check — à remplacer par une vraie validation si besoin
                  final hasAt = v.contains('@');
                  return hasAt ? null : 'Email invalide';
                },
              ),
              const SizedBox(height: 12),

              // Champ mot de passe
              TextFormField(
                controller: _passwordCtrl,
                style: const TextStyle(color: Colors.white),
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Enter password',
                  labelStyle: const TextStyle(color: Colors.white),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    tooltip: _obscure ? 'Show password' : 'Hide password',
                    icon: Icon(
                      _obscure ? Icons.visibility : Icons.visibility_off,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                validator: (v) =>
                    (v == null || v.length < 6) ? '6 caractères minimum' : null,
              ),
              const SizedBox(height: 8),

              // Options: remember + forgot
              Row(
                children: [
                  Checkbox(
                    value: _rememberMe,
                    onChanged: (v) => setState(() => _rememberMe = v ?? false),
                    activeColor: AppColors.accent,
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
                      foregroundColor: AppColors.accent,
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
                  onPressed: () {
                    setState(() => _autovalidate = AutovalidateMode.always);
                    if (_formKey.currentState!.validate()) {
                      // TODO: Implémente la logique de login
                      // final email = _emailCtrl.text;
                      // final password = _passwordCtrl.text;
                    }
                  },
                  child: const Text('Log In'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Divider text
        const DividerText('or sign in with'),
        const SizedBox(height: 12),

        // Boutons sociaux
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SocialBtn(
              icon: SvgPicture.asset('assets/images/Google__G__logo.svg'),
              tooltip: 'Sign in with Google',
            ),
            const SizedBox(width: 24),
            SocialBtn(
              icon: SvgPicture.asset(
                'assets/images/Apple_logo_black.svg',
                // color: Colors.white,
                colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn),
              ),
              tooltip: 'Sign in with Apple',
            ),
            const SizedBox(width: 24),
            SocialBtn(
              icon: SvgPicture.asset('assets/images/2023_Facebook_icon.svg'),
              tooltip: 'Sign in with Facebook',
              onTap: () {},
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
                    color: AppColors.accent,
                    fontWeight: FontWeight.bold,
                  ),
                  text: 'Sign up',
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
