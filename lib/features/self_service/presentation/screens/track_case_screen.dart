import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';

class TrackCaseArguments {
  final String labelText;
  final String hintText;
  final String buttonText;

  const TrackCaseArguments({
    this.labelText = 'INCIDENT CODE',
    this.hintText = 'e.g. INC-20481',
    this.buttonText = 'Search Case',
  });
}

class TrackCaseScreen extends StatefulWidget {
  final String? labelText;
  final String? hintText;
  final String? buttonText;

  const TrackCaseScreen({
    super.key,
    this.labelText,
    this.hintText,
    this.buttonText,
  });

  @override
  State<TrackCaseScreen> createState() => _TrackCaseScreenState();
}

class _TrackCaseScreenState extends State<TrackCaseScreen> {
  final TextEditingController _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _onSearch(String label, String buttonLabel) {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter ${label.toLowerCase()}'),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Searching for $code...'),
        backgroundColor: AppColors.primary,
      ),
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

    final args = ModalRoute.of(context)?.settings.arguments as TrackCaseArguments?;
    final effectiveLabelText = widget.labelText ?? args?.labelText ?? 'INCIDENT CODE';
    final effectiveHintText = widget.hintText ?? args?.hintText ?? 'e.g. INC-20481';
    final effectiveButtonText = widget.buttonText ?? args?.buttonText ?? 'Search Case';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header Bar with Burgundy Gradient
          _buildHeader(context),

          // Main Body Container (Fill 402px, Radius TL24 TR24, Color #FBF6F3)
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFFBF6F3), // Exact Hex: #FBF6F3
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24), // Exact Radius: 24px
                ),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 24.0,
                ),
                child: Column(
                  children: [
                    // div.ssp-card: Floating White Card (Fixed 354px x Hug 163px, Radii TL18 TR18 BR18 BL6, Padding 16px, Gap 16px, Color #FFFFFF)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16.0), // Exact Padding: 16px
                      decoration: BoxDecoration(
                        color: Colors.white, // Exact Color: #FFFFFF
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(18), // Exact TL: 18px
                          topRight: Radius.circular(18), // Exact TR: 18px
                          bottomRight: Radius.circular(18), // Exact BR: 18px
                          bottomLeft: Radius.circular(6), // Exact BL: 6px
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
                          // div.field: Fill 322px x Hug 67px, Gap 8px
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Text: "LEAVE CODE *" or "INCIDENT CODE *"
                              Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: effectiveLabelText,
                                      style: const TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 12, // Exact Size: 12px
                                        fontWeight: FontWeight.w500, // Exact Weight: 500 Medium
                                        color: Color(0xFF5E5855), // Exact Hex: #5E5855
                                        letterSpacing: 0.0, // Exact Letter Spacing: 0%
                                        height: 1.0, // Exact Line Height: 100%
                                      ),
                                    ),
                                    const TextSpan(
                                      text: ' *',
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 12, // Exact Size: 12px
                                        fontWeight: FontWeight.w500, // Exact Weight: 500 Medium
                                        color: Color(0xFFC6134B), // Exact Hex: #C6134B
                                        letterSpacing: 0.0,
                                        height: 1.0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 8), // Exact Gap: 8px

                              // Input Field Box
                              SizedBox(
                                height: 44, // 67px total - 15px label - 8px gap = 44px box
                                child: TextFormField(
                                  controller: _codeController,
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 14,
                                    color: Color(0xFF1A1310),
                                  ),
                                  decoration: InputDecoration(
                                    hintText: effectiveHintText,
                                    hintStyle: const TextStyle(
                                      fontFamily: 'Outfit',
                                      color: Color(0xFFA0A0A0),
                                      fontSize: 14,
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFFAF7F5),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE8DFE1),
                                        width: 1.0,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: AppColors.primary,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16), // Exact Gap: 16px inside ssp-card

                          // Search Button (Fill 322px x Fixed 48px, Radii TL26 TR26 BR26 BL6, Padding 1px 6px 1px 6px, Gap 8px, Color #C6134B)
                          SizedBox(
                            width: double.infinity,
                            height: 48, // Exact Height: Fixed 48px
                            child: ElevatedButton(
                              onPressed: () => _onSearch(effectiveLabelText, effectiveButtonText),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFC6134B), // Exact Color: #C6134B
                                elevation: 0,
                                padding: const EdgeInsets.fromLTRB(6, 1, 6, 1), // Exact Padding: 1px 6px 1px 6px
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(26), // Exact TL: 26px
                                    topRight: Radius.circular(26), // Exact TR: 26px
                                    bottomRight: Radius.circular(26), // Exact BR: 26px
                                    bottomLeft: Radius.circular(6), // Exact BL: 6px
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    effectiveButtonText,
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    softWrap: false,
                                    style: const TextStyle(
                                      fontFamily: 'Outfit',
                                      color: Colors.white,
                                      fontSize: 16, // Exact Size: 16px
                                      fontWeight: FontWeight.w400, // Exact Weight: 400 Regular
                                      letterSpacing: 0.16, // Exact Letter Spacing: 0.16px
                                      height: 1.0, // Exact Line Height: 100%
                                    ),
                                  ),

                                  const SizedBox(width: 8), // Exact Gap: 8px

                                  // Icon: (Width 16px x Height 16px)
                                  const Icon(
                                    Icons.search_rounded,
                                    color: Colors.white,
                                    size: 16, // Exact Size: 16px
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
              // Back Button Container
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 44, // Exact Width: 44px
                    height: 44, // Exact Height: 44px
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

              // Title Text: "TRACK CASE"
              const SizedBox(
                height: 15,
                child: Center(
                  child: Text(
                    'TRACK CASE',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(
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
