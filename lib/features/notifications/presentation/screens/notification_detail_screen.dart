import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import 'notifications_screen.dart';

class NotificationDetailScreen extends StatelessWidget {
  final NotificationItem item;

  const NotificationDetailScreen({
    super.key,
    required this.item,
  });

  String _resolveAttachmentUrl(String rawUrl) {
    if (rawUrl.isEmpty) return '';
    String fullUrl = rawUrl.trim();
    if (!fullUrl.startsWith('http://') && !fullUrl.startsWith('https://')) {
      const baseUrl = "https://erp.alsharqiholding.qa";
      fullUrl = fullUrl.startsWith('/') ? '$baseUrl$fullUrl' : '$baseUrl/$fullUrl';
    }
    if (!fullUrl.contains('download=true') && fullUrl.contains('/web/content/')) {
      fullUrl += fullUrl.contains('?') ? '&download=true' : '?download=true';
    }
    return fullUrl;
  }

  Future<void> _downloadOrOpenAttachment(
      BuildContext context, String rawUrl) async {
    final fullUrl = _resolveAttachmentUrl(rawUrl);
    if (fullUrl.isEmpty) return;

    final fileName = item.attachmentName ?? 'attachment';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading $fileName...'),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );

    try {
      final uri = Uri.parse(fullUrl);
      bool launched = false;
      try {
        if (await canLaunchUrl(uri)) {
          launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } catch (_) {}

      if (!launched) {
        try {
          launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
        } catch (_) {}
      }
    } catch (_) {}
  }

  static final RegExp _brRegExp = RegExp(r'<br\s*/?>', caseSensitive: false);
  static final RegExp _pRegExp = RegExp(r'</p>', caseSensitive: false);
  static final RegExp _divRegExp = RegExp(r'</div>', caseSensitive: false);
  static final RegExp _tagsRegExp = RegExp(r'<[^>]*>');
  static final RegExp _newlinesRegExp = RegExp(r'\n{3,}');

  String _cleanHtml(String text) {
    if (text.isEmpty) return '';
    String cleaned = text
        .replaceAll(_brRegExp, '\n')
        .replaceAll(_pRegExp, '\n\n')
        .replaceAll(_divRegExp, '\n')
        .replaceAll(_tagsRegExp, '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");

    return cleaned.replaceAll(_newlinesRegExp, '\n\n').trim();
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

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header Bar with Burgundy Gradient
          _buildHeader(context),

          // Main Body Container
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFFBF6F3),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main Detail Card
                    _buildDetailCard(context),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(BuildContext context) {
    final rawText = item.englishBody ?? item.description;
    final cleanedFullText = _cleanHtml(rawText);

    // Check if text is separated into English & Arabic using '---'
    List<String> parts = cleanedFullText.split(RegExp(r'\n?\s*---\s*\n?'));
    String englishText = parts.isNotEmpty ? parts[0].trim() : cleanedFullText;
    String? inlineArabicText = parts.length > 1 ? parts.sublist(1).join('\n\n').trim() : null;
    final arabicText = (inlineArabicText != null && inlineArabicText.isNotEmpty)
        ? inlineArabicText
        : (_cleanHtml(item.arabicBody ?? '').isNotEmpty ? _cleanHtml(item.arabicBody!) : null);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
          bottomRight: Radius.circular(18),
          bottomLeft: Radius.circular(6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge and Date Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Category Badge Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: item.badgeBgColor,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  item.badgeText,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: item.badgeTextColor,
                    letterSpacing: 0.2,
                  ),
                ),
              ),

              // Date / Time
              Text(
                item.date,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF888888),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // English Body Text
          if (englishText.isNotEmpty)
            Text(
              englishText,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF1A1310),
                height: 1.55,
              ),
            ),

          // Structured details if present
          if (item.extraDetails != null && item.extraDetails!.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFEEEEEE), thickness: 1),
            const SizedBox(height: 12),
            ...item.extraDetails!.entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 110,
                        child: Text(
                          entry.key,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF888888),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1A1310),
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],

          // Arabic Body Text if present
          if (arabicText != null && arabicText.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFEEEEEE), thickness: 1),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  arabicText,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF1A1310),
                    height: 1.6,
                  ),
                ),
              ),
            ),
          ],

          // Attachment Card if present
          if ((item.attachmentUrl != null && item.attachmentUrl!.isNotEmpty) ||
              (item.attachmentName != null && item.attachmentName!.isNotEmpty)) ...[
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () {
                final url = item.attachmentUrl ?? '';
                if (url.isNotEmpty) {
                  _downloadOrOpenAttachment(context, url);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Attachment link for ${item.attachmentName ?? "this file"} is processing.'),
                      backgroundColor: const Color(0xFFC6134B),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9ECEF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFC6134B).withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFC6134B),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.picture_as_pdf_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Attachment File',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1310),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.attachmentName ?? 'Download / View Attachment',
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF666666),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.download_rounded,
                      size: 20,
                      color: Color(0xFFC6134B),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final headerTitle = item.title.toUpperCase();

    return Container(
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
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 44,
                    height: 44,
                    padding: const EdgeInsets.fromLTRB(6, 1, 6, 1),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.chevron_left_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 15,
                child: Center(
                  child: Text(
                    headerTitle,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    softWrap: false,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.68,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
