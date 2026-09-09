import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/auth_repository.dart';
import '../../../../core/services/storage_service.dart';

class SelfServiceOtpModal extends StatefulWidget {
  final String employeeNumber;
  final String companyId;
  final String phoneNumber;
  final String requestTitle;
  final Future<Map<String, dynamic>?> Function() onVerifyAndSubmit;

  const SelfServiceOtpModal({
    super.key,
    required this.employeeNumber,
    required this.companyId,
    required this.phoneNumber,
    required this.requestTitle,
    required this.onVerifyAndSubmit,
  });

  static Future<Map<String, dynamic>?> show({
    required BuildContext context,
    required String employeeNumber,
    required String companyId,
    required String phoneNumber,
    required String requestTitle,
    required Future<Map<String, dynamic>?> Function() onVerifyAndSubmit,
  }) {
    return showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFBF6F3),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SelfServiceOtpModal(
          employeeNumber: employeeNumber,
          companyId: companyId,
          phoneNumber: phoneNumber,
          requestTitle: requestTitle,
          onVerifyAndSubmit: onVerifyAndSubmit,
        ),
      ),
    );
  }

  @override
  State<SelfServiceOtpModal> createState() => _SelfServiceOtpModalState();
}

class _SelfServiceOtpModalState extends State<SelfServiceOtpModal> {
  final List<TextEditingController> _otpControllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  final AuthRepository _authRepository = AuthRepository();

  bool _isSendingOtp = false;
  bool _isVerifying = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _sendOtp();
  }

  Future<void> _sendOtp() async {
    setState(() {
      _isSendingOtp = true;
      _errorMessage = null;
    });

    try {
      final res = await _authRepository.sendOTP(
        widget.employeeNumber,
        widget.companyId,
      );
      if (res.registerMobile != null && res.registerMobile!.isNotEmpty) {
        await StorageService.addValue(
            StorageService.keyPhone, res.registerMobile!);
        await StorageService.addValue(
            StorageService.keyWhatsAppPhone, res.registerMobile!);
      }
      if (res.error != null && res.error!.isNotEmpty) {
        setState(() {
          _errorMessage = res.error;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to send OTP: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSendingOtp = false;
        });
      }
    }
  }

  @override
  void dispose() {
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onOtpChanged(int index, String value) {
    setState(() {
      _errorMessage = null;
    });
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
  }

  Future<void> _verifyAndSubmit() async {
    final otpCode = _otpControllers.map((c) => c.text).join();
    if (otpCode.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter the OTP code.';
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      final deviceToken = StorageService.getValue(StorageService.keyDeviceId);
      final verifyResult = await _authRepository.verifyOTP(
        employeeNumber: widget.employeeNumber,
        companyId: widget.companyId,
        otp: otpCode,
        deviceToken: deviceToken,
      );

      if (!verifyResult.isSuccess) {
        setState(() {
          _errorMessage = 'Invalid OTP. Please enter the correct OTP.';
        });
        return;
      }

      // Successful OTP Verification -> Proceed to Submit Request
      final submitResult = await widget.onVerifyAndSubmit();
      if (mounted) {
        Navigator.pop(context, submitResult);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Verification error: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  String _maskPhone(String phone) {
    if (phone.length < 4) return phone;
    final last4 = phone.substring(phone.length - 4);
    return '******$last4';
  }

  @override
  Widget build(BuildContext context) {
    final maskedPhone = _maskPhone(widget.phoneNumber);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Confirm ${widget.requestTitle}',
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1310),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context, false),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFF888888),
                    size: 22,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'OTP sent to registered mobile $maskedPhone',
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Color(0xFF666666),
              ),
            ),
            const SizedBox(height: 16),
            if (_isSendingOtp)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else ...[
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
                        fontFamily: 'Outfit',
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1310),
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.zero,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFFE8DFE1),
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
                      onChanged: (val) => _onOtpChanged(index, val),
                    ),
                  );
                }),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.red.shade800,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isVerifying ? null : _verifyAndSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    elevation: 0,
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
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Verify & Process Request',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
