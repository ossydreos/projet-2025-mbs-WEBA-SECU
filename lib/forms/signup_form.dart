import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_mobility_services/theme/theme_app.dart' show AppColors;
import 'package:my_mobility_services/widgets/sheet_handle.dart';

class SignupForm extends StatefulWidget {
  const SignupForm({required this.onClose});
  final VoidCallback onClose;

  @override
  State<SignupForm> createState() => SignupFormState();
}

class SignupFormState extends State<SignupForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  var _autovalidate = AutovalidateMode.disabled;

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
                  onPressed: () {
                    setState(() => _autovalidate = AutovalidateMode.always);
                    if (_formKey.currentState!.validate()) {
                      // TODO: Implémente la logique de signup
                      // final name = _nameCtrl.text;
                      // final email = _emailCtrl.text;
                      // final password = _passwordCtrl.text;
                    }
                  },
                  child: const Text('Get Started'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: widget.onClose,
            style: TextButton.styleFrom(foregroundColor: AppColors.accent),
            child: const Text('I already have an account'),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
