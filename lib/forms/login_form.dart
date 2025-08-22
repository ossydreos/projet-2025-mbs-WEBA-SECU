import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_mobility_services/widgets/buttons/social_buttons.dart';
import 'package:my_mobility_services/widgets/divider_text.dart';
import 'package:my_mobility_services/widgets/sheet_handle.dart';
import '../theme/theme_app.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({required this.onClose});
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
        const Row(
          children: [
            Expanded(
              child: SocialBtn(
                label: 'Google',
                icon: Icons.g_mobiledata,
                tooltip: 'Sign in with Google',
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: SocialBtn(
                label: 'Apple',
                icon: Icons.apple,
                tooltip: 'Sign in with Apple',
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: SocialBtn(
                label: 'Facebook',
                icon: Icons.facebook,
                tooltip: 'Sign in with Facebook',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
