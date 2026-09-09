import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/auth_repository.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../routes/app_routes.dart';
import '../../../splash/presentation/widgets/al_sharqi_logo.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final List<TextEditingController> _otpControllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  final AuthRepository _authRepository = AuthRepository();

  Timer? _timer;
  int _secondsRemaining = 19;
  bool _canResend = false;
  bool _isVerifying = false;

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
        timer.cancel();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(AppStrings.otpTimeoutMessage),
              duration: Duration(seconds: 3),
            ),
          );
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            Navigator.pushReplacementNamed(context, AppRoutes.signIn);
          }
        }
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
      if (index < 3) {
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

  Future<void> _onVerify() async {
    final otpCode = _otpControllers.map((c) => c.text).join();
    if (otpCode.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the full 4-digit code')),
      );
      return;
    }

    final empNumber = StorageService.getValue(StorageService.keyEmpNo);
    final companyId = StorageService.getValue(StorageService.keyCompanyId);

    setState(() => _isVerifying = true);

    try {
      final result = await _authRepository.verifyOTP(
        employeeNumber: empNumber,
        companyId: companyId,
        otp: otpCode,
        deviceToken: StorageService.getValue(StorageService.keyDeviceId),
      );

      if (result.isSuccess) {
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.home,
            (route) => false,
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.error ?? 'Invalid OTP. Please try again.'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  Future<void> _resendCode() async {
    _startTimer();
    try {
      final empNumber = StorageService.getValue(StorageService.keyEmpNo);
      final companyId = StorageService.getValue(StorageService.keyCompanyId);
      if (empNumber.isNotEmpty && companyId.isNotEmpty) {
        final res = await _authRepository.sendOTP(empNumber, companyId);
        if (res.registerMobile != null && res.registerMobile!.isNotEmpty) {
          await StorageService.addValue(
              StorageService.keyPhone, res.registerMobile!);
          await StorageService.addValue(
              StorageService.keyWhatsAppPhone, res.registerMobile!);
          if (mounted) {
            setState(() {});
          }
        }
      }
    } catch (_) {}
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

    const double headerHeight = 264.0;
    const double cardTopOffset = 250.0;
    const double badgeHeight = 29.0;
    const double badgeTopOffset = cardTopOffset - (badgeHeight / 2);

    final formattedTimer =
        '00:${_secondsRemaining.toString().padLeft(2, '0')}';

    final savedPhone = StorageService.getValue(StorageService.keyPhone);
    final phoneEnding = savedPhone.length >= 4
        ? '${savedPhone.substring(savedPhone.length - 4)}.'
        : AppStrings.defaultPhoneEnding;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
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
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 16.0),
                        child: AlSharqiLogo(
                          width: 160,
                          height: 160,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            top: cardTopOffset,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.checkYourPhone,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                        color: Color(0xFF1A1310),
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(
                            text: AppStrings.checkPhoneSubtitlePrefix,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: AppColors.textSecondary,
                              height: 1.55,
                            ),
                          ),
                          TextSpan(
                            text: phoneEnding,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              height: 1.55,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      AppStrings.verificationCodeLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.labelText,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (index) {
                        return Container(
                          width: 58,
                          height: 58,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          child: TextFormField(
                            controller: _otpControllers[index],
                            focusNode: _focusNodes[index],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 1,
                            style: const TextStyle(
                              fontSize: 22,
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
                    const SizedBox(height: 20),
                    Center(
                      child: _canResend
                          ? GestureDetector(
                              onTap: _resendCode,
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
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isVerifying ? null : _onVerify,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            vertical: 1,
                            horizontal: 6,
                          ),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(26),
                              topRight: Radius.circular(26),
                              bottomRight: Radius.circular(26),
                              bottomLeft: Radius.circular(6),
                            ),
                          ),
                        ),
                        child: _isVerifying
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    AppStrings.verifyAndContinue,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400,
                                      letterSpacing: 0.16,
                                      height: 1.0,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.verified_user_outlined,
                          size: 16,
                          color: const Color(0xFF10B981).withValues(alpha: 0.9),
                        ),
                        const SizedBox(width: 8),
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
          Positioned(
            top: badgeTopOffset,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                height: badgeHeight,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFFC6134B).withAlpha(153),
                      const Color(0xFF7A0E33).withAlpha(153),
                      const Color(0xFFC6134B).withAlpha(153),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                  border: Border.all(
                    color: Colors.white.withAlpha(51),
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
