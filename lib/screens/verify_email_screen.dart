import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_routes.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/context_colors.dart';
import '../providers/auth_provider.dart';
import 'package:nomnom_lk/l10n/app_localizations.dart';
import '../utils/spacings.dart';
import '../widgets/app_logo.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;
  const VerifyEmailScreen({super.key, required this.email});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen>
    with SingleTickerProviderStateMixin {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  int _resendCooldown = 0;
  late final AnimationController _animCtrl;
  late final Animation<double> _logoAnim;
  late final Animation<double> _titleAnim;
  late final Animation<double> _codeAnim;
  late final Animation<double> _btnAnim;
  late final Animation<double> _footerAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _logoAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.0, 0.3, curve: Curves.easeOutCubic),
    );
    _titleAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.15, 0.5, curve: Curves.easeOutCubic),
    );
    _codeAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.3, 0.65, curve: Curves.easeOutCubic),
    );
    _btnAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.5, 0.8, curve: Curves.easeOutCubic),
    );
    _footerAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.65, 1.0, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _animCtrl.dispose();
    _codeController.dispose();
    super.dispose();
  }

  String _parseError(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map) {
        final error = data['error'];
        if (error is Map && error['message'] is String) {
          return error['message'] as String;
        }
      }
    }
    return AppLocalizations.of(context)!.verifyErrorGeneric;
  }

  Future<void> _verify() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await context
          .read<AuthProvider>()
          .verifyEmail(widget.email, _codeController.text.trim());

      if (mounted) {
        await Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.home,
          (_) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_parseError(e))),
        );
      }
    }
  }

  Timer? _cooldownTimer;

  Future<void> _resend() async {
    setState(() => _resendCooldown = 30);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _resendCooldown = _resendCooldown - 1;
        if (_resendCooldown <= 0) {
          timer.cancel();
        }
      });
    });

    try {
      await context.read<AuthProvider>().sendVerificationCode(widget.email);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.verifyCodeResent)),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_parseError(e))),
      );
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
              context.colors.surface,
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
                                    0.0, 0.3, curve: Curves.easeOutBack),
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
                              AppLocalizations.of(context)!.verifyCheckYourEmail,
                              textAlign: TextAlign.center,
                              style: textTheme.titleLarge?.copyWith(
                                color: context.colors.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.3),
                            end: Offset.zero,
                          ).animate(_titleAnim),
                          child: FadeTransition(
                            opacity: _titleAnim,
                            child: Text(
                              AppLocalizations.of(context)!.verifyWeSentCodeTo,
                              textAlign: TextAlign.center,
                              style: textTheme.bodyMedium?.copyWith(
                                color: context.colors.muted,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.3),
                            end: Offset.zero,
                          ).animate(_titleAnim),
                          child: FadeTransition(
                            opacity: _titleAnim,
                            child: Text(
                              widget.email,
                              textAlign: TextAlign.center,
                              style: textTheme.bodyMedium?.copyWith(
                                color: AppColors.curry,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 36),
                        SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.3),
                            end: Offset.zero,
                          ).animate(_codeAnim),
                          child: FadeTransition(
                            opacity: _codeAnim,
                            child: Container(
                              decoration: BoxDecoration(
                                color: context.colors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: context.colors.border,
                                ),
                              ),
                              padding: const EdgeInsets.all(Spacings.lg),
                              child: TextFormField(
                                controller: _codeController,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.done,
                                maxLength: 6,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 28,
                                  letterSpacing: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                                onFieldSubmitted: (_) => _verify(),
                                validator: (v) {
                                  if (v == null || v.trim().length != 6) {
                                    return AppLocalizations.of(context)!.verifyEnterCode;
                                  }
                                  return null;
                                },
                                decoration: InputDecoration(
                                  hintText: '000000',
                                  hintStyle: TextStyle(
                              color: context.colors.muted,
                              fontSize: 28,
                              letterSpacing: 12,
                                  ),
                                  counterText: '',
                                  border: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  errorBorder: InputBorder.none,
                                  focusedErrorBorder: InputBorder.none,
                                ),
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
                                onPressed: isLoading ? null : _verify,
                                icon: isLoading
                                     ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: context.colors.background,
                                        ),
                                      )
                                    : const Icon(Icons.check_rounded, size: 22),
                                label: Text(
                                    isLoading ? AppLocalizations.of(context)!.verifyVerifying : AppLocalizations.of(context)!.verifyVerifyAndLogin),
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
                            child: Column(
                              children: [
                                GestureDetector(
                                  onTap:
                                      _resendCooldown > 0 ? null : _resend,
                                  child: Text(
                                    _resendCooldown > 0
                                        ? AppLocalizations.of(context)!.verifyResendCodeIn(_resendCooldown)
                                        : AppLocalizations.of(context)!.verifyResendCode,
                                    style: textTheme.bodySmall?.copyWith(
                                      color: _resendCooldown > 0
                                          ? context.colors.muted
                                          : AppColors.curry,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                GestureDetector(
                                  onTap: () =>
                                      Navigator.of(context).pushNamedAndRemoveUntil(
                                    AppRoutes.login,
                                    (_) => false,
                                  ),
                                  child: Text(
                                    AppLocalizations.of(context)!.verifyUseDifferentEmail,
                                    style: textTheme.bodySmall?.copyWith(
                                      color: context.colors.muted,
                                      fontWeight: FontWeight.w500,
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
