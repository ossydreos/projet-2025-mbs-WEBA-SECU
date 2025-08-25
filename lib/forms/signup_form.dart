import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_mobility_services/screens/welcome_login_screen.dart';
import 'package:my_mobility_services/theme/theme_app.dart' show AppColors;
import 'package:my_mobility_services/widgets/authgate.dart';
import 'package:my_mobility_services/widgets/buttons/social_buttons.dart';
import 'package:my_mobility_services/widgets/divider_text.dart';
import 'package:my_mobility_services/widgets/sheet_handle.dart';
import 'package:my_mobility_services/widgets/waiting_widget.dart';

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

  var _autovalidate = AutovalidateMode.disabled;

  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
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
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Enter name',
                  labelStyle: TextStyle(color: Colors.white),
                ),
                validator: (v) => (v == null || v.isEmpty)
                    ? 'Nom requis'
                    : (v.length < 2 ? 'Nom trop court' : null),
              ),
              const SizedBox(height: 12),
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
                  return v.contains('@') ? null : 'Email invalide';
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordCtrl,
                style: const TextStyle(color: Colors.white),
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Create password',
                  labelStyle: TextStyle(color: Colors.white),
                ),
                validator: (v) =>
                    (v == null || v.length < 6) ? '6 caractères minimum' : null,
              ),
              const SizedBox(height: 14),
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
                          setState(() {
                            _isLoading = true;
                          });

                          if (!_formKey.currentState!.validate()) return;
                          final name = _nameCtrl.text.trim();
                          final email = _emailCtrl.text.trim();
                          final password = _passwordCtrl.text;

                          try {
                            final cred = await FirebaseAuth.instance
                                .createUserWithEmailAndPassword(
                                  email: email,
                                  password: password,
                                );

                            final uid = cred.user?.uid;
                            if (uid != null) {
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(uid)
                                  .set({
                                    'name': name,
                                    'email': email,
                                    'createdAt': FieldValue.serverTimestamp(),
                                  });
                            }
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Compte créé')),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Erreur: $e')),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setState(() => _isLoading = false);
                            }
                          }
                        },
                  child: _isLoading
                      ? const LoadingMBS()
                      : const Text('Get Started'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        DividerText('or sign up with'),

        const SizedBox(height: 12),
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
              text: 'Already have an account? ',
              children: [
                TextSpan(
                  style: GoogleFonts.poppins(
                    color: AppColors.accent,
                    fontWeight: FontWeight.bold,
                  ),
                  text: 'Login',
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => widget.onSwitch(PanelType.login),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
