import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/theme_app.dart';

enum PanelType { none, login, signup }

class WelcomeLoginSignup extends StatefulWidget {
  const WelcomeLoginSignup({super.key});
  @override
  State<WelcomeLoginSignup> createState() => _WelcomeLoginSignupState();
}

class _WelcomeLoginSignupState extends State<WelcomeLoginSignup>
    with SingleTickerProviderStateMixin {
  PanelType panel = PanelType.none;
  late final AnimationController _ctl;
  late final Animation<double> _t; // pour petits fades

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _t = CurvedAnimation(parent: _ctl, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  void openPanel(PanelType type) {
    setState(() => panel = type);
    _ctl.forward(from: 0);
  }

  void closePanel() {
    _ctl.reverse().whenComplete(() {
      if (mounted) setState(() => panel = PanelType.none);
    });
  }

  @override
  Widget build(BuildContext context) {
    final txt = GoogleFonts.poppins(); // ✅ nouvelle police
    final isSheetVisible = panel != PanelType.none;

    return Scaffold(
      body: Stack(
        children: [
          // -------- FOND DEGRADE avec ta palette + halo accent
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: const [AppColors.background, AppColors.surface],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          Positioned(
            right: -60,
            top: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color.fromRGBO(
                  AppColors.accent.red,
                  AppColors.accent.green,
                  AppColors.accent.blue,
                  0.12,
                ),
              ),
            ),
          ),
          Positioned(
            left: -80,
            bottom: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color.fromRGBO(
                  AppColors.accent.red,
                  AppColors.accent.green,
                  AppColors.accent.blue,
                  0.08,
                ),
              ),
            ),
          ),

          // -------- CONTENU "WELCOME"
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // logo
                      SvgPicture.asset(
                        'assets/images/MBG-Logo.svg',
                        height: 86,
                        semanticsLabel: 'MBG Logo',
                        colorFilter: const ColorFilter.mode(
                          AppColors.accent,
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Welcome",
                        style: txt.copyWith(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Réservez votre chauffeur en quelques secondes — moderne, fluide et fiable.",
                        textAlign: TextAlign.center,
                        style: txt.copyWith(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 28),
                      // CTA pilule (Create + Log In)
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () => openPanel(PanelType.signup),
                          style: ElevatedButton.styleFrom(
                            shape: const StadiumBorder(),
                          ),
                          child: Text(
                            "Create Account",
                            style: txt.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton(
                          onPressed: () => openPanel(PanelType.login),
                          style: OutlinedButton.styleFrom(
                            shape: const StadiumBorder(),
                            foregroundColor: Colors.white,
                            side: BorderSide(
                              color: Color.fromRGBO(255, 255, 255, 0.35),
                            ),
                          ),
                          child: Text(
                            "I already have an account",
                            style: txt.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // -------- SCRIM + SHEET qui GLISSE (même page)
          // scrim (clique pour fermer)
          if (isSheetVisible)
            FadeTransition(
              opacity: _t,
              child: GestureDetector(
                onTap: closePanel,
                child: Semantics(
                  label: 'Dismiss panel',
                  child: Container(color: Color.fromRGBO(0, 0, 0, 0.45)),
                ),
              ),
            ),

          // sheet
          AnimatedSlide(
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutCubic,
            offset: isSheetVisible ? Offset.zero : const Offset(0, 1),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: _GlassSheet(
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                    child: (panel == PanelType.login)
                        ? _LoginForm(onClose: closePanel)
                        : (panel == PanelType.signup)
                        ? _SignupForm(onClose: closePanel)
                        : const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================
// SHEET + FORMULAIRES
// ============================

class _GlassSheet extends StatelessWidget {
  final Widget child;
  const _GlassSheet({required this.child});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxHeight: screenHeight * 0.8, // Limite à 80% de la hauteur écran
          ),
          decoration: BoxDecoration(
            color: Color.fromRGBO(255, 255, 255, 0.06),
            border: Border(
              top: BorderSide(color: Color.fromRGBO(255, 255, 255, 0.12)),
            ),
          ),
          child: SingleChildScrollView(
            // respect keyboard insets and allow content to scroll when needed
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _LoginForm extends StatefulWidget {
  final VoidCallback onClose;
  const _LoginForm({required this.onClose});
  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _key = GlobalKey<FormState>();
  bool _remember = false;
  bool _obscure = true;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _passwordCtrl;
  AutovalidateMode _autoValidate = AutovalidateMode.disabled;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController();
    _passwordCtrl = TextEditingController();
  }

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
        _SheetHandle(),
        Center(
          child: Text(
            "Welcome Back",
            style: txt.copyWith(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 14),

        Form(
          key: _key,
          autovalidateMode: _autoValidate,
          child: Column(
            children: [
              TextFormField(
                controller: _emailCtrl,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "Enter email",
                  labelStyle: TextStyle(color: Colors.white),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? "Email requis" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordCtrl,
                style: const TextStyle(color: Colors.white),
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: "Enter password",
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
                    (v == null || v.length < 6) ? "6 caractères minimum" : null,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Checkbox(
                    value: _remember,
                    onChanged: (v) => setState(() => _remember = v ?? false),
                    activeColor: AppColors.accent,
                    side: BorderSide(color: Color.fromRGBO(255, 255, 255, 0.6)),
                  ),
                  Text("Remember me", style: txt.copyWith(color: Colors.white)),
                  const Spacer(),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.accent,
                    ),
                    child: const Text("Forgot password?"),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 54,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() => _autoValidate = AutovalidateMode.always);
                    if (_key.currentState!.validate()) {
                      // TODO: perform login using _emailCtrl.text and _passwordCtrl.text
                    }
                  },
                  child: const Text("Log In"),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _DividerText("or sign in with"),
        const SizedBox(height: 12),
        Row(
          children: [
            const Expanded(
              child: _SocialBtn(
                label: "Google",
                icon: Icons.g_mobiledata,
                tooltip: 'Sign in with Google',
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: _SocialBtn(
                label: "Apple",
                icon: Icons.apple,
                tooltip: 'Sign in with Apple',
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: _SocialBtn(
                label: "Facebook",
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

class _SignupForm extends StatefulWidget {
  final VoidCallback onClose;
  const _SignupForm({required this.onClose});
  @override
  State<_SignupForm> createState() => _SignupFormState();
}

class _SignupFormState extends State<_SignupForm> {
  final _key = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _passwordCtrl;
  AutovalidateMode _autoValidate = AutovalidateMode.disabled;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _passwordCtrl = TextEditingController();
  }

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
        _SheetHandle(),
        Center(
          child: Text(
            "Create Your Account",
            style: txt.copyWith(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Form(
          key: _key,
          autovalidateMode: _autoValidate,
          child: Column(
            children: [
              TextFormField(
                controller: _nameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Enter name",
                  labelStyle: TextStyle(color: Colors.white),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? "Nom requis" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailCtrl,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "Enter email",
                  labelStyle: TextStyle(color: Colors.white),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? "Email requis" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordCtrl,
                style: const TextStyle(color: Colors.white),
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Create password",
                  labelStyle: TextStyle(color: Colors.white),
                ),
                validator: (v) =>
                    (v == null || v.length < 6) ? "6 caractères minimum" : null,
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 54,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() => _autoValidate = AutovalidateMode.always);
                    if (_key.currentState!.validate()) {
                      // TODO: signup using _nameCtrl.text, _emailCtrl.text, _passwordCtrl.text
                    }
                  },
                  child: const Text("Get Started"),
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
            child: const Text("I already have an account"),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ------- petites briques UI -------
class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 44,
        height: 5,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Color.fromRGBO(255, 255, 255, 0.35),
          borderRadius: BorderRadius.circular(100),
        ),
      ),
    );
  }
}

class _SocialBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? tooltip;
  const _SocialBtn({required this.label, required this.icon, this.tooltip});
  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: Color.fromRGBO(255, 255, 255, 0.35)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Tooltip(message: tooltip ?? label, child: Icon(icon, size: 20)),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _DividerText extends StatelessWidget {
  final String text;
  const _DividerText(this.text);
  @override
  Widget build(BuildContext context) {
    final c = Color.fromRGBO(255, 255, 255, 0.28);
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: c)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(text, style: GoogleFonts.poppins(color: Colors.white70)),
        ),
        Expanded(child: Container(height: 1, color: c)),
      ],
    );
  }
}
