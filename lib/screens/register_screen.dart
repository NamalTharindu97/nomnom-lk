import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_routes.dart';
import '../core/theme/context_colors.dart';
import '../providers/auth_provider.dart';
import '../utils/spacings.dart';
import '../widgets/app_logo.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  late final AnimationController _animCtrl;
  late final Animation<double> _logoAnim;
  late final Animation<double> _titleAnim;
  late final Animation<double> _formAnim;
  late final Animation<double> _btnAnim;
  late final Animation<double> _footerAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();

    _logoAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOutCubic),
    );
    _titleAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.15, 0.5, curve: Curves.easeOutCubic),
    );
    _formAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.3, 0.7, curve: Curves.easeOutCubic),
    );
    _btnAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.55, 0.85, curve: Curves.easeOutCubic),
    );
    _footerAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.7, 1.0, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String _parseAuthError(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map) {
        final error = data['error'];
        if (error is Map && error['message'] is String) {
          final msg = error['message'] as String;
          if (msg.contains('already registered')) {
            return 'An account with this email already exists.';
          }
          return msg;
        }
      }
    }
    return 'Registration failed. Try again.';
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;

    try {
      await context.read<AuthProvider>().register(email, password, name);

      if (mounted) {
        await Navigator.of(context).pushReplacementNamed(
          AppRoutes.verifyEmail,
          arguments: email,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_parseAuthError(e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              context.colors.background,
              context.colors.backgroundAlt,
              const Color(0xFF24170C),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Selector<AuthProvider, bool>(
              selector: (_, provider) => provider.isLoading,
              builder: (context, isLoading, _) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: Spacings.xl + 4),
                  child: Form(
                    key: _formKey,
                    onChanged: () => _formKey.currentState?.validate(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 32),
                        FadeTransition(
                          opacity: _logoAnim,
                          child: ScaleTransition(
                            scale: Tween<double>(begin: 0.8, end: 1).animate(
                              CurvedAnimation(
                                parent: _animCtrl,
                                curve: const Interval(
                                    0.0, 0.35, curve: Curves.easeOutBack),
                              ),
                            ),
                            child: const AppLogo(),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.3),
                            end: Offset.zero,
                          ).animate(_titleAnim),
                          child: FadeTransition(
                            opacity: _titleAnim,
                            child: Text(
                              "Create your account",
                              textAlign: TextAlign.center,
                              style: textTheme.titleLarge?.copyWith(
                                color: context.colors.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 36),
                        SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.3),
                            end: Offset.zero,
                          ).animate(_formAnim),
                          child: FadeTransition(
                            opacity: _formAnim,
                            child: Container(
                              decoration: BoxDecoration(
                                color: context.colors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.black.withValues(alpha: 0.06),
                                ),
                              ),
                              padding: const EdgeInsets.all(Spacings.lg),
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: _nameController,
                                    textInputAction: TextInputAction.next,
                                    maxLength: 255,
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty)
                                            ? 'Enter your name'
                                            : null,
                                    decoration: const InputDecoration(
                                      hintText: 'Full name',
                                      counterText: '',
                                      prefixIcon:
                                          Icon(Icons.person_outline_rounded),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    maxLength: 254,
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) {
                                        return 'Enter your email';
                                      }
                                      if (!RegExp(
                                              r'^[^@]+@[^@]+\.[^@]+$')
                                          .hasMatch(v.trim())) {
                                        return 'Enter a valid email';
                                      }
                                      return null;
                                    },
                                    decoration: const InputDecoration(
                                      hintText: 'Email address',
                                      counterText: '',
                                      prefixIcon:
                                          Icon(Icons.mail_outline_rounded),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    textInputAction: TextInputAction.next,
                                    maxLength: 128,
                                    validator: (v) {
                                      if (v == null || v.length < 8) {
                                        return 'At least 8 characters';
                                      }
                                      return null;
                                    },
                                    decoration: InputDecoration(
                                      hintText: 'Password',
                                      counterText: '',
                                      prefixIcon: const Icon(
                                          Icons.lock_outline_rounded),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_off_rounded
                                              : Icons.visibility_rounded,
                                        ),
                                        onPressed: () => setState(() =>
                                            _obscurePassword =
                                                !_obscurePassword),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _confirmController,
                                    obscureText: _obscureConfirm,
                                    textInputAction: TextInputAction.done,
                                    maxLength: 128,
                                    onFieldSubmitted: (_) => _register(),
                                    validator: (v) {
                                      if (v != _passwordController.text) {
                                        return 'Passwords do not match';
                                      }
                                      return null;
                                    },
                                    decoration: InputDecoration(
                                      hintText: 'Confirm password',
                                      counterText: '',
                                      prefixIcon: const Icon(
                                          Icons.lock_outline_rounded),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscureConfirm
                                              ? Icons.visibility_off_rounded
                                              : Icons.visibility_rounded,
                                        ),
                                        onPressed: () => setState(() =>
                                            _obscureConfirm =
                                                !_obscureConfirm),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.3),
                            end: Offset.zero,
                          ).animate(_btnAnim),
                          child: FadeTransition(
                            opacity: _btnAnim,
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: isLoading ? null : _register,
                                icon: isLoading
                                    ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: context.colors.background,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.person_add_rounded, size: 22),
                                label: Text(isLoading
                                    ? 'Creating account...'
                                    : 'Create account'),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.3),
                            end: Offset.zero,
                          ).animate(_footerAnim),
                          child: FadeTransition(
                            opacity: _footerAnim,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Already have an account? ',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: context.colors.muted,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.of(context).pop(),
                                  child: Text(
                                    'Sign In',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
