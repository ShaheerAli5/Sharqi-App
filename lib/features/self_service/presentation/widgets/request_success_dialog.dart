import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class RequestSuccessDialog extends StatelessWidget {
  final String requestType; // e.g. "Idea", "Complaint", "Leave", "Employee", "Salary Slip"
  final String referenceCode; // e.g. "BI-22-00102"
  final String? customMessage;

  const RequestSuccessDialog({
    super.key,
    required this.requestType,
    required this.referenceCode,
    this.customMessage,
  });

  static Future<void> show({
    required BuildContext context,
    required String requestType,
    required String referenceCode,
    String? customMessage,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => RequestSuccessDialog(
        requestType: requestType,
        referenceCode: referenceCode,
        customMessage: customMessage,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titleLabel = customMessage != null && customMessage!.contains('Thank you')
        ? customMessage!
        : 'Thank you! Your $requestType Request Has Been Registered !!';

    final refLabel = referenceCode.isNotEmpty
        ? '$requestType Reference :: $referenceCode'
        : '$requestType Request Registered';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF3F6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              titleLabel,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1310),
                height: 1.3,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFF3F8F0),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check_rounded,
                      size: 90,
                      color: Color(0xFF88C057),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              refLabel,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF88C057),
                height: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "We received your $requestType request;\nwe'll be in touch shortly!",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF555555),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
