import 'package:flutter/material.dart';

import '../state/app_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';
import '../widgets/lime_button.dart';
import '../widgets/phone_frame.dart';

enum _AuthMode { signIn, signUp }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController(
    text: 'matt@formai.app',
  );
  final TextEditingController _passwordController = TextEditingController(
    text: 'formai24',
  );
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  _AuthMode _mode = _AuthMode.signIn;
  bool _obscurePassword = true;

  bool get _isSignUp => _mode == _AuthMode.signUp;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PhoneFrame(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: FocusScope.of(context).unfocus,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const _LoginBackdrop(),
              LayoutBuilder(
                builder: (context, constraints) {
                  return ClipRect(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.topCenter,
                      child: SizedBox(
                        width: constraints.maxWidth,
                        height: _isSignUp ? 1040 : 970,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            24,
                            _isSignUp ? 42 : 70,
                            24,
                            32,
                          ),
                          child: Column(
                            children: [
                              const _HeaderLogo(),
                              SizedBox(height: _isSignUp ? 28 : 48),
                              _TitleSection(isSignUp: _isSignUp),
                              SizedBox(height: _isSignUp ? 28 : 48),
                              _AuthForm(
                                mode: _mode,
                                nameController: _nameController,
                                emailController: _emailController,
                                passwordController: _passwordController,
                                confirmPasswordController:
                                    _confirmPasswordController,
                                obscurePassword: _obscurePassword,
                                onTogglePassword: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                                onSubmit: _submit,
                              ),
                              SizedBox(height: _isSignUp ? 26 : 48),
                              _SocialFooter(
                                isSignUp: _isSignUp,
                                onProvider: _continueWithProvider,
                                onToggleMode: () {
                                  setState(() {
                                    _mode = _isSignUp
                                        ? _AuthMode.signIn
                                        : _AuthMode.signUp;
                                    if (_isSignUp) {
                                      _confirmPasswordController.text =
                                          _passwordController.text;
                                    }
                                  });
                                },
                              ),
                              const Spacer(),
                              const _LegalLinks(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    final appState = AppScope.of(context);
    final result = _isSignUp
        ? appState.signUp(
            name: _nameController.text,
            email: _emailController.text,
            password: _passwordController.text,
            confirmPassword: _confirmPasswordController.text,
          )
        : appState.signIn(
            email: _emailController.text,
            password: _passwordController.text,
          );

    if (!result.success) {
      _showMessage(result.message);
    }
  }

  void _continueWithProvider(String provider) {
    AppScope.of(context).continueWithProvider(provider);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: AppColors.panel,
          behavior: SnackBarBehavior.floating,
          content: Text(message, style: const TextStyle(color: AppColors.text)),
        ),
      );
  }
}

class _LoginBackdrop extends StatelessWidget {
  const _LoginBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/login_backdrop.png',
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
        Container(color: AppColors.background.withValues(alpha: 0.55)),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.background.withValues(alpha: 0.08),
                AppColors.background.withValues(alpha: 0.25),
                AppColors.background,
              ],
              stops: const [0, 0.48, 1],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderLogo extends StatelessWidget {
  const _HeaderLogo();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.glass,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x33424938)),
            boxShadow: [
              BoxShadow(
                color: AppColors.lime.withValues(alpha: 0.10),
                blurRadius: 40,
              ),
            ],
          ),
          child: const Center(child: FormaiLogoMark(size: 30)),
        ),
        const SizedBox(height: 12),
        const FormaiWordmark(size: 30, color: AppColors.lime),
      ],
    );
  }
}

class _TitleSection extends StatelessWidget {
  const _TitleSection({required this.isSignUp});

  final bool isSignUp;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          isSignUp ? 'Join FORMAI' : 'Train Smarter',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 36,
            fontWeight: FontWeight.w800,
            height: 40 / 36,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          isSignUp
              ? 'Create your account and start training\nwith personal AI feedback.'
              : 'Achieve your fitness goals with your\npersonal AI coach.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 14,
            height: 22.75 / 14,
          ),
        ),
      ],
    );
  }
}

class _AuthForm extends StatelessWidget {
  const _AuthForm({
    required this.mode,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.obscurePassword,
    required this.onTogglePassword,
    required this.onSubmit,
  });

  final _AuthMode mode;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool obscurePassword;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;

  bool get _isSignUp => mode == _AuthMode.signUp;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_isSignUp) ...[
          _LabeledInput(
            label: 'FULL NAME',
            child: _PlainTextField(
              controller: nameController,
              hintText: 'Matt Johnson',
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
            ),
          ),
          const SizedBox(height: 12),
        ],
        _LabeledInput(
          label: 'EMAIL ADDRESS',
          child: _PlainTextField(
            controller: emailController,
            hintText: 'name@example.com',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
        ),
        const SizedBox(height: 12),
        _LabeledInput(
          label: 'PASSWORD',
          trailing: IconButton(
            tooltip: obscurePassword ? 'Show password' : 'Hide password',
            onPressed: onTogglePassword,
            visualDensity: VisualDensity.compact,
            icon: Icon(
              obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              size: 20,
              color: AppColors.muted.withValues(alpha: 0.70),
            ),
          ),
          child: _PlainTextField(
            controller: passwordController,
            hintText: '••••••••',
            obscureText: obscurePassword,
            textInputAction: _isSignUp
                ? TextInputAction.next
                : TextInputAction.done,
            onSubmitted: _isSignUp ? null : (_) => onSubmit(),
          ),
        ),
        if (_isSignUp) ...[
          const SizedBox(height: 12),
          _LabeledInput(
            label: 'CONFIRM PASSWORD',
            child: _PlainTextField(
              controller: confirmPasswordController,
              hintText: '••••••••',
              obscureText: obscurePassword,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onSubmit(),
            ),
          ),
        ] else ...[
          const SizedBox(height: 8),
          const Align(
            alignment: Alignment.centerRight,
            child: Text(
              'FORGOT PASSWORD?',
              style: TextStyle(
                color: Color(0xCCB6F36A),
                fontSize: 10,
                letterSpacing: 1,
                height: 1.5,
              ),
            ),
          ),
        ],
        SizedBox(height: _isSignUp ? 26 : 40),
        LimeButton(
          label: _isSignUp ? 'CREATE ACCOUNT' : 'START TRAINING',
          onPressed: onSubmit,
        ),
      ],
    );
  }
}

class _PlainTextField extends StatelessWidget {
  const _PlainTextField({
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.obscureText = false,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      onSubmitted: onSubmitted,
      cursorColor: AppColors.lime,
      style: const TextStyle(color: AppColors.text, fontSize: 16),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Color(0x808C937F), fontSize: 16),
      ),
    );
  }
}

class _LabeledInput extends StatelessWidget {
  const _LabeledInput({
    required this.label,
    required this.child,
    this.trailing,
  });

  final String label;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 10,
              letterSpacing: 1,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 55,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.input,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(child: child),
              ?trailing,
            ],
          ),
        ),
      ],
    );
  }
}

class _SocialFooter extends StatelessWidget {
  const _SocialFooter({
    required this.isSignUp,
    required this.onProvider,
    required this.onToggleMode,
  });

  final bool isSignUp;
  final ValueChanged<String> onProvider;
  final VoidCallback onToggleMode;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _DividerLine()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                isSignUp ? 'OR SIGN UP WITH' : 'OR CONTINUE WITH',
                style: const TextStyle(
                  color: Color(0x808C937F),
                  fontSize: 10,
                  letterSpacing: 1,
                  height: 1.5,
                ),
              ),
            ),
            Expanded(child: _DividerLine()),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _SocialButton(
                asset: 'assets/images/google.png',
                onTap: () => onProvider('Google'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _SocialButton(
                asset: 'assets/images/apple.png',
                onTap: () => onProvider('Apple'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isSignUp
                    ? 'Already have an account? '
                    : "Don't have an account? ",
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 14,
                  height: 20 / 14,
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onToggleMode,
                child: Text(
                  isSignUp ? 'Sign In' : 'Sign Up',
                  style: const TextStyle(
                    color: AppColors.lime,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    height: 20 / 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DividerLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: const Color(0x4D424938));
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({required this.asset, required this.onTap});

  final String asset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.glass.withValues(alpha: 0.40),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x1A424938)),
          ),
          child: Center(
            child: Image.asset(
              asset,
              width: 20,
              height: 20,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}

class _LegalLinks extends StatelessWidget {
  const _LegalLinks();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'PRIVACY POLICY',
          style: TextStyle(color: Color(0x668C937F), fontSize: 10, height: 1.5),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '*',
            style: TextStyle(color: Color(0x668C937F), fontSize: 10),
          ),
        ),
        Text(
          'TERMS OF SERVICE',
          style: TextStyle(color: Color(0x668C937F), fontSize: 10, height: 1.5),
        ),
      ],
    );
  }
}
