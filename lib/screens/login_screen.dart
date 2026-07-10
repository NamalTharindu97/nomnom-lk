import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

import '../core/app_routes.dart';
import '../core/theme/context_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/offer_provider.dart';
import '../providers/restaurant_provider.dart';
import 'package:nomnom_lk/l10n/app_localizations.dart';
import '../utils/spacings.dart';
import '../widgets/app_logo.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _showEmailForm = false;
  bool _obscurePassword = true;
  bool _isGoogleLoading = false;
  late final AnimationController _animCtrl;
  late final Animation<double> _logoAnim;
  late final Animation<double> _titleAnim;
  late final Animation<double> _googleBtnAnim;
  late final Animation<double> _dividerAnim;
  late final Animation<double> _emailBtnAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();

    _logoAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
    );
    _titleAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.2, 0.55, curve: Curves.easeOutCubic),
    );
    _googleBtnAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.4, 0.7, curve: Curves.easeOutCubic),
    );
    _dividerAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.55, 0.8, curve: Curves.easeOutCubic),
    );
    _emailBtnAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.65, 0.95, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _parseAuthError(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map) {
        final error = data['error'];
        if (error is Map && error['message'] is String) {
          final msg = error['message'] as String;
          if (msg.contains('invalid email or password')) {
            return AppLocalizations.of(context)!.loginErrorInvalidCredentials;
          }
          if (msg.contains('suspended')) {
            return AppLocalizations.of(context)!.loginErrorSuspended;
          }
          if (msg.contains('please sign in with Google')) {
            return AppLocalizations.of(context)!.loginErrorGoogleEmail;
          }
          if (msg.contains('verify your email')) {
            return msg;
          }
          return msg;
        }
      }
    }
    return AppLocalizations.of(context)!.loginErrorGeneric;
  }

  Future<void> _syncDataAfterLogin() async {
    try {
      await Future.wait([
        context.read<OfferProvider>().loadOffers(forceRefresh: true),
        context.read<RestaurantProvider>().loadRestaurants(forceRefresh: true),
        context.read<NotificationProvider>().loadUnreadCount(),
      ]);
    } catch (e) {
      debugPrint('Post-login data sync error: $e');
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isGoogleLoading = true);
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        if (mounted) setState(() => _isGoogleLoading = false);
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final idToken = await userCredential.user?.getIdToken();

      if (idToken != null && mounted) {
        await context.read<AuthProvider>().signInWithFirebase(idToken);
      }

      if (mounted) {
        await _syncDataAfterLogin();
      }

      if (mounted) {
        await Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.home,
          (_) => false,
        );
      }
    } catch (e) {
      debugPrint('Google sign-in error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.loginErrorGeneric)),
        );
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;

    try {
      await context.read<AuthProvider>().signInWithEmail(email, password);

      if (mounted) {
        await _syncDataAfterLogin();
      }

      if (mounted) {
        await Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.home,
          (_) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        final msg = _parseAuthError(e);
        if (msg.contains('verify your email')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.loginEmailVerificationRequired),
              action: SnackBarAction(
                label: AppLocalizations.of(context)!.loginResend,
                onPressed: () => Navigator.of(context).pushReplacementNamed(
                  AppRoutes.verifyEmail,
                  arguments: email,
                ),
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg)),
          );
        }
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
              builder: (context, isLoading, child) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: Spacings.xl + 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 24),
                      FadeTransition(
                        opacity: _logoAnim,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.8, end: 1).animate(
                            CurvedAnimation(
                              parent: _animCtrl,
                              curve: const Interval(
                                0.0, 0.4, curve: Curves.easeOutBack,
                              ),
                            ),
                          ),
                          child: const AppLogo(),
                        ),
                      ),
                      const SizedBox(height: 28),
                      SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.3),
                          end: Offset.zero,
                        ).animate(_titleAnim),
                        child: FadeTransition(
                          opacity: _titleAnim,
                          child: Text(
                            AppLocalizations.of(context)!.splashTagline,
                            textAlign: TextAlign.center,
                            style: textTheme.titleMedium?.copyWith(
                              color: context.colors.textSecondary,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 44),
                      SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.3),
                          end: Offset.zero,
                        ).animate(_googleBtnAnim),
                        child: FadeTransition(
                          opacity: _googleBtnAnim,
                                child: ElevatedButton.icon(
                                key: const ValueKey('google-sign-in-btn'),
                                onPressed: isLoading || _isGoogleLoading ? null : _signInWithGoogle,
                                icon: isLoading || _isGoogleLoading
                                    ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: context.colors.background,
                                        ),
                                      )
                                    : const Icon(Icons.g_mobiledata_rounded, size: 28),
                                label: Text(isLoading || _isGoogleLoading ? AppLocalizations.of(context)!.loginSigningIn : AppLocalizations.of(context)!.loginContinueWithGoogle),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      FadeTransition(
                        opacity: _dividerAnim,
                        child: Row(
                          children: [
                            Expanded(
                              child: Divider(color: context.colors.surfaceAlt),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: Spacings.sm + 2),
                                child: Text(
                                  AppLocalizations.of(context)!.loginOrContinueWith,
                                  style: textTheme.titleSmall?.copyWith(
                                    color: context.colors.muted,
                                  ),
                                ),
                            ),
                            Expanded(
                              child: Divider(color: context.colors.surfaceAlt),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.3),
                          end: Offset.zero,
                        ).animate(_emailBtnAnim),
                        child: FadeTransition(
                          opacity: _emailBtnAnim,
                          child: AnimatedCrossFade(
                            duration: const Duration(milliseconds: 300),
                            crossFadeState: _showEmailForm
                                ? CrossFadeState.showSecond
                                : CrossFadeState.showFirst,
                            firstChild: SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                key: const ValueKey('continue-email-btn'),
                                onPressed: () =>
                                    setState(() => _showEmailForm = true),
                                icon: const Icon(Icons.mail_outline_rounded),
                                label: Text(AppLocalizations.of(context)!.loginContinueWithEmail),
                              ),
                            ),
                            secondChild: Form(
                              key: _formKey,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: context.colors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color:
                                        Colors.black.withValues(alpha: 0.06),
                                  ),
                                ),
                                padding: const EdgeInsets.all(Spacings.lg),
                                child: Column(
                                  children: [
                                    TextFormField(
                                      key: const ValueKey('email-field'),
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
                                      maxLength: 254,
                                      validator: (v) {
                                        if (v == null || v.trim().isEmpty) {
                                          return AppLocalizations.of(context)!.loginEmailHint;
                                        }
                                        if (!RegExp(
                                                r'^[^@]+@[^@]+\.[^@]+$')
                                            .hasMatch(v.trim())) {
                                          return AppLocalizations.of(context)!.loginEmailInvalid;
                                        }
                                        return null;
                                      },
                                      decoration: InputDecoration(
                                        hintText: AppLocalizations.of(context)!.loginEmailLabel,
                                        counterText: '',
                                        prefixIcon: Icon(
                                            Icons.mail_outline_rounded),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    TextFormField(
                                      key: const ValueKey('password-field'),
                                      controller: _passwordController,
                                      obscureText: _obscurePassword,
                                      textInputAction: TextInputAction.done,
                                      maxLength: 128,
                                      onFieldSubmitted: (_) =>
                                          _signInWithEmail(),
                                      validator: (v) {
                                        if (v == null || v.isEmpty) {
                                          return AppLocalizations.of(context)!.loginPasswordHint;
                                        }
                                        if (v.length < 8) {
                                          return AppLocalizations.of(context)!.loginPasswordMinChars;
                                        }
                                        return null;
                                      },
                                      decoration: InputDecoration(
                                        hintText: AppLocalizations.of(context)!.loginPasswordLabel,
                                        counterText: '',
                                        prefixIcon: const Icon(
                                            Icons.lock_outline_rounded),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons
                                                    .visibility_off_rounded
                                                : Icons.visibility_rounded,
                                          ),
                                          onPressed: () => setState(() =>
                                              _obscurePassword =
                                                  !_obscurePassword),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        key: const ValueKey('sign-in-btn'),
                                        onPressed: isLoading || _isGoogleLoading
                                            ? null
                                            : _signInWithEmail,
                                        icon: const Icon(
                                            Icons.arrow_forward_rounded),
                                        label: Text(AppLocalizations.of(context)!.loginSignInButton),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      FadeTransition(
                        opacity: _emailBtnAnim,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.loginNoAccount,
                              style: textTheme.titleSmall?.copyWith(
                                color: context.colors.muted,
                              ),
                            ),
                            GestureDetector(
                              key: const ValueKey('sign-up-link'),
                              onTap: () => Navigator.of(context).pushNamed(
                                AppRoutes.register,
                              ),
                                  child: Text(
                                    AppLocalizations.of(context)!.loginRegisterLink,
                                  style: textTheme.titleSmall?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
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
