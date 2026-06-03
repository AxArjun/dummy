// FuelIQ — Email OTP Verification Screen
// Shown after signup. User enters 6-digit code sent to their email.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';

class VerifyScreen extends ConsumerStatefulWidget {
  const VerifyScreen({super.key});

  @override
  ConsumerState<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends ConsumerState<VerifyScreen> {
  // ── OTP input ──────────────────────────────────────────────────────────────
  final _otpController = TextEditingController();
  final _otpFocusNode = FocusNode();

  // ── Resend countdown ───────────────────────────────────────────────────────
  Timer? _resendTimer;
  int _resendCountdown = 60;
  bool _canResend = false;

  // ── Design tokens ──────────────────────────────────────────────────────────
  static const Color _bg = Color(0xFF0B0B0B);
  static const Color _surface = Color(0xFF121212);
  static const Color _card = Color(0xFF1A1A1A);
  static const Color _border = Color(0xFF262626);
  static const Color _gold = Color(0xFFD4AF37);
  static const Color _textPrimary = Color(0xFFF5F5F5);
  static const Color _textSub = Color(0xFF9E9E9E);
  static const Color _error = Color(0xFFF44336);
  static const Color _success = Color(0xFF4CAF50);

  @override
  void initState() {
    super.initState();
    _otpFocusNode.addListener(() => setState(() {}));
    _otpController.addListener(() => setState(() {}));
    _startResendCountdown();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _otpFocusNode.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendCountdown() {
    _resendCountdown = 60;
    _canResend = false;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_resendCountdown > 0) {
          _resendCountdown--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  String get _otp => _otpController.text;
  bool get _isComplete => _otp.length == 6;

  void _onOtpChanged(String value) {
    // Filter to digits only
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits != value) {
      _otpController.value = TextEditingValue(
        text: digits,
        selection: TextSelection.collapsed(offset: digits.length),
      );
      return;
    }
    setState(() {});
    if (_isComplete) {
      _submitOtp();
    }
  }

  Future<void> _submitOtp() async {
    if (!_isComplete) return;
    _otpFocusNode.unfocus();
    await ref.read(authNotifierProvider.notifier).verifyEmailOtp(_otp);
  }

  Future<void> _handleResend() async {
    if (!_canResend) return;
    _otpController.clear();
    setState(() {});
    await ref.read(authNotifierProvider.notifier).resendEmailOtp();
    _startResendCountdown();
  }

  @override
  Widget build(BuildContext context) {
    final authStatus = ref.watch(authNotifierProvider);

    final email = switch (authStatus) {
      AuthVerificationPending(:final email) => email,
      _ => '',
    };
    final isLoading = authStatus is AuthLoading;
    final errorMessage = switch (authStatus) {
      AuthError(:final failure) => failure.userMessage,
      _ => null,
    };

    // Show error as a SnackBar
    ref.listen<AuthStatus>(authNotifierProvider, (prev, next) {
      if (next is AuthError && mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text(
                next.failure.userMessage,
                style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
              ),
              backgroundColor: _error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              action: SnackBarAction(
                label: 'Dismiss',
                textColor: Colors.white,
                onPressed: () {
                  ref.read(authNotifierProvider.notifier).clearError();
                },
              ),
            ),
          );
      }
    });

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // Background gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.0,
                  colors: [Color(0x10D4AF37), Color(0x00000000)],
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // Back button
                  _buildBackButton(),

                  const SizedBox(height: 32),

                  // Header
                  _buildHeader(email).animate().fadeIn(duration: 400.ms),

                  const SizedBox(height: 48),

                  // OTP card
                  _buildOtpCard(isLoading, errorMessage)
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 500.ms)
                      .slideY(begin: 0.15, end: 0),

                  const SizedBox(height: 32),

                  // Resend section
                  _buildResendSection().animate().fadeIn(delay: 400.ms),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => Navigator.of(context).maybePop(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _border),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: _textPrimary,
          size: 16,
        ),
      ),
    );
  }

  Widget _buildHeader(String email) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo row
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [Color(0xFFD4AF37), Color(0xFF8B6914)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _gold.withOpacity(0.3),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.local_gas_station_rounded,
                color: Color(0xFF0B0B0B),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'FuelIQ',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        const Text(
          'Check Your Email',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: _textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 8),

        if (email.isNotEmpty) ...[
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: _textSub,
                height: 1.5,
              ),
              children: [
                const TextSpan(text: 'We sent a 6-digit code to\n'),
                TextSpan(
                  text: email,
                  style: const TextStyle(
                    color: _gold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ] else
          const Text(
            'We sent a 6-digit verification code to your email.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: _textSub,
              height: 1.5,
            ),
          ),
      ],
    );
  }

  Widget _buildOtpCard(bool isLoading, String? errorMessage) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          // OTP boxes (tap anywhere on row to focus hidden field)
          GestureDetector(
            onTap: () => _otpFocusNode.requestFocus(),
            behavior: HitTestBehavior.opaque,
            child: Column(
              children: [
                // The hidden TextField that captures input
                SizedBox(
                  height: 0,
                  child: TextField(
                    controller: _otpController,
                    focusNode: _otpFocusNode,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      counterText: '',
                    ),
                    onChanged: _onOtpChanged,
                    style: const TextStyle(height: 0, color: Colors.transparent),
                    cursorColor: Colors.transparent,
                    autofocus: true,
                  ),
                ),

                // Visual OTP boxes
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(6, (i) {
                    final char = i < _otp.length ? _otp[i] : '';
                    final isFilled = char.isNotEmpty;
                    final isActive =
                        _otpFocusNode.hasFocus && i == _otp.length && !isLoading;
                    final hasErr = errorMessage != null;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      curve: Curves.easeOut,
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      width: 44,
                      height: 54,
                      decoration: BoxDecoration(
                        color: isFilled
                            ? _gold.withOpacity(0.08)
                            : const Color(0xFF0F0F0F),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: hasErr && isFilled
                              ? _error
                              : isActive
                                  ? _gold
                                  : isFilled
                                      ? _gold.withOpacity(0.5)
                                      : _border,
                          width: isActive ? 2.0 : 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          char,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            color: _textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Verify button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: isLoading || !_isComplete ? null : _submitOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: const Color(0xFF0B0B0B),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: _gold.withOpacity(0.4),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Color(0xFF0B0B0B),
                      ),
                    )
                  : const Text(
                      'Verify Email',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResendSection() {
    return Center(
      child: Column(
        children: [
          Text(
            "Didn't receive the code?",
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: _textSub,
            ),
          ),
          const SizedBox(height: 8),

          if (_canResend)
            GestureDetector(
              onTap: _handleResend,
              child: const Text(
                'Resend Code',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _gold,
                ),
              ),
            )
          else
            Text(
              'Resend in ${_resendCountdown}s',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: _textSub.withOpacity(0.7),
              ),
            ),

          const SizedBox(height: 16),

          // Info note
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F0F0F),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _border),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: _textSub.withOpacity(0.7),
                  size: 16,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Check your spam folder if you don\'t see it.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: _textSub.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
