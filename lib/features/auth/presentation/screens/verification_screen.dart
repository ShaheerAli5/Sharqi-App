import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../routes/app_routes.dart';
import '../../../splash/presentation/widgets/al_sharqi_logo.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  Timer? _timer;
  int _secondsRemaining = 19;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    setState(() {
      _secondsRemaining = 19;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onOtpChanged(int index, String value) {
    if (value.isNotEmpty) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    } else {
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }
    setState(() {});
  }

  void _onVerify() {
    final otpCode = _otpControllers.map((c) => c.text).join();
    if (otpCode.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the full 6-digit code')),
      );
      return;
    }

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.home,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    const double headerHeight = 264.0; // Header height
    const double cardTopOffset = 250.0;
    const double badgeHeight = 29.0;
    const double badgeTopOffset = cardTopOffset - (badgeHeight / 2); // 235.5px

    final formattedTimer =
        '00:${_secondsRemaining.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // 1. Layer 1: Top Gradient Header with Back Button & 160px x 160px Logo
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              height: headerHeight,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.splashGradientStart,
                    AppColors.splashGradientMiddle,
                    AppColors.splashGradientEnd,
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Stack(
                  children: [
                    // Back Chevron Button (Top Left)
                    Positioned(
                      top: 12,
                      left: 16,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(51),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.chevron_left_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ),

                    // Centered Al Sharqi Holding Logo (Exact Figma Layout: 160px x 160px)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 16.0),
                        child: AlSharqiLogo(
                          width: 160, // Exact Figma Width: 160px
                          height: 160, // Exact Figma Height: 160px
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. Layer 2: Cream Body Card Container (Fills rest of screen)
          Positioned.fill(
            top: cardTopOffset,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.background, // Exact Figma #FBF6F3
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24), // Radius: 24px
                ),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Frame 28: Title & Subtitle Block (Fill 354px x Hug 91px, Gap: 16px)
                    Text(
                      AppStrings.checkYourPhone,
                      style: const TextStyle(
                        fontSize: 20, // Exact Figma Size: 20px
                        fontWeight: FontWeight.w600, // Exact Figma Weight: 600 SemiBold
                        letterSpacing: -0.2, // Exact Figma Letter Spacing: -0.2px
                        color: Color(0xFF1A1310), // Exact Figma Hex Color: #1A1310
                        height: 1.0, // Exact Figma Line Height: 100%
                      ),
                    ),
                    const SizedBox(height: 16), // Exact Figma Gap: 16px

                    // Subtitle (354px x 50px, Size: 16px, LineHeight: 24.8px)
                    Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(
                            text: AppStrings.checkPhoneSubtitlePrefix,
                            style: TextStyle(
                              fontSize: 16, // Exact Figma Size: 16px
                              fontWeight: FontWeight.w400, // Exact Figma Weight: 400 Regular
                              color: AppColors.textSecondary,
                              height: 1.55, // Line height 24.8px / 16px = 1.55
                            ),
                          ),
                          TextSpan(
                            text: AppStrings.defaultPhoneEnding,
                            style: const TextStyle(
                              fontSize: 16, // Exact Figma Size: 16px
                              fontWeight: FontWeight.w600, // Exact Figma Weight: 600 SemiBold
                              color: AppColors.textPrimary,
                              height: 1.55,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Frame 27: Verification Code Block (Fill 354px x Hug 98px, Gap: 16px)
                    Text(
                      AppStrings.verificationCodeLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.labelText,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 6 OTP Input Boxes
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, (index) {
                        return SizedBox(
                          width: 48,
                          height: 52,
                          child: TextFormField(
                            controller: _otpControllers[index],
                            focusNode: _focusNodes[index],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 1,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              counterText: '',
                              filled: true,
                              fillColor: AppColors.inputBackground,
                              contentPadding: EdgeInsets.zero,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: AppColors.inputBorder,
                                  width: 1.0,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: AppColors.primary,
                                  width: 1.5,
                                ),
                              ),
                            ),
                            onChanged: (value) => _onOtpChanged(index, value),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 16), // Exact Figma Gap: 16px

                    // Resend Timer Row
                    Center(
                      child: _canResend
                          ? GestureDetector(
                              onTap: _startTimer,
                              child: const Text(
                                AppStrings.resendCode,
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : Text.rich(
                              TextSpan(
                                children: [
                                  const TextSpan(
                                    text: AppStrings.didntGetItResendIn,
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  TextSpan(
                                    text: formattedTimer,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),

                    const SizedBox(height: 28),

                    // button.btn-primary: Verify and Continue Button (354px x 48px, Radii: TL 26, TR 26, BR 26, BL 6)
                    SizedBox(
                      width: double.infinity,
                      height: 48, // Exact Figma Height: 48px
                      child: ElevatedButton(
                        onPressed: _onVerify,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary, // #C6134B
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            vertical: 1,
                            horizontal: 6,
                          ), // Exact Figma Padding Top 1, Right 6, Bottom 1, Left 6
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(26), // Exact Figma TL 26px
                              topRight: Radius.circular(26), // Exact Figma TR 26px
                              bottomRight: Radius.circular(26), // Exact Figma BR 26px
                              bottomLeft: Radius.circular(6), // Exact Figma BL 6px
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              AppStrings.verifyAndContinue,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16, // Exact Figma Size: 16px
                                fontWeight: FontWeight.w400, // Exact Figma Weight: 400
                                letterSpacing: 0.16, // Exact Figma Letter Spacing: 0.16px
                                height: 1.0, // Exact Figma Line Height: 100%
                              ),
                            ),
                            const SizedBox(width: 8), // Exact Figma Gap: 8px
                            const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 16, // Exact Figma Icon Size: 16px
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // div.trust: Encryption Notice (Fill 354px x Hug 15px, Gap: 8px)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.verified_user_outlined,
                          size: 16,
                          color: const Color(0xFF10B981).withValues(alpha: 0.9),
                        ),
                        const SizedBox(width: 8), // Exact Figma Gap: 8px
                        Text(
                          AppStrings.sessionEncryptedNotice,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. Layer 3: Floating Pill Badge (div.eyebrow - 163px x 29px, Radius: 999px)
          Positioned(
            top: badgeTopOffset,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                height: badgeHeight, // Exact 29px
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ), // Exact Figma Padding: Top/Bottom 8px, Left/Right 18px
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999), // Exact Figma 999px Radius
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFFC6134B).withAlpha(153), // Exact 60% opacity
                      const Color(0xFF7A0E33).withAlpha(153), // Exact 60% opacity
                      const Color(0xFFC6134B).withAlpha(153), // Exact 60% opacity
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                  border: Border.all(
                    color: Colors.white.withAlpha(51), // Glassmorphism outline
                    width: 0.8,
                  ),
                ),
                child: Text(
                  AppStrings.stepVerifyBadge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                    height: 1.0,
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
