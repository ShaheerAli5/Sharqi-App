import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../dashboard/presentation/widgets/app_drawer.dart';

class SelfServicePortalScreen extends StatefulWidget {
  const SelfServicePortalScreen({super.key});

  @override
  State<SelfServicePortalScreen> createState() =>
      _SelfServicePortalScreenState();
}

class _SelfServicePortalScreenState extends State<SelfServicePortalScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Top Burgundy Header
          _buildHeader(context),

          // Main Scrollable Body
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFFBF6F3), // Exact Hex: #FBF6F3
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 24.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Subtitle Intro Text
                    const Text(
                      AppStrings.portalIntroSubtitle,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1310),
                        height: 1.35,
                      ),
                    ),

                    const SizedBox(height: 18),

                    // div.ssp-list: Cards List (Gap 14px)
                    // Card 1: COMPLAINT
                    _PortalServiceCard(
                      icon: Icons.add_rounded,
                      title: AppStrings.complaintTitle,
                      description: AppStrings.complaintDesc,
                      hasSeeManual: true,
                      primaryButtonLabel: AppStrings.createRequest,
                      primaryButtonIcon: Icons.add_rounded,
                      secondaryButtonLabel: AppStrings.trackCase,
                      secondaryButtonIcon: Icons.search_rounded,
                      onPrimaryTap: () {},
                      onSecondaryTap: () {},
                    ),

                    const SizedBox(height: 14), // Exact Gap: 14px

                    // Card 2: EMPLOYEE REQUEST
                    _PortalServiceCard(
                      icon: Icons.group_outlined,
                      title: AppStrings.employeeRequestTitle,
                      description: AppStrings.employeeRequestDesc,
                      hasSeeManual: true,
                      primaryButtonLabel: AppStrings.createRequest,
                      primaryButtonIcon: Icons.group_outlined,
                      secondaryButtonLabel: AppStrings.trackCase,
                      secondaryButtonIcon: Icons.search_rounded,
                      onPrimaryTap: () {},
                      onSecondaryTap: () {},
                    ),

                    const SizedBox(height: 14), // Exact Gap: 14px

                    // Card 3: LEAVE REQUEST
                    _PortalServiceCard(
                      icon: Icons.calendar_month_outlined,
                      title: AppStrings.leaveRequestTitle,
                      description: AppStrings.leaveRequestDesc,
                      hasSeeManual: false,
                      primaryButtonLabel: AppStrings.leaveRequestButton,
                      primaryButtonIcon: Icons.calendar_today_rounded,
                      secondaryButtonLabel: AppStrings.trackCase,
                      secondaryButtonIcon: Icons.search_rounded,
                      onPrimaryTap: () {},
                      onSecondaryTap: () {},
                    ),

                    const SizedBox(height: 14), // Exact Gap: 14px

                    // Card 4: BRIGHT IDEA
                    _PortalServiceCard(
                      icon: Icons.lightbulb_outline_rounded,
                      title: AppStrings.brightIdeaTitle,
                      description: AppStrings.brightIdeaDesc,
                      hasSeeManual: false,
                      primaryButtonLabel: AppStrings.brightIdeaButton,
                      primaryButtonIcon: Icons.lightbulb_outline_rounded,
                      onPrimaryTap: () {},
                    ),

                    const SizedBox(height: 14), // Exact Gap: 14px

                    // Card 5: SALARY SLIP
                    _PortalServiceCard(
                      icon: Icons.article_outlined,
                      title: AppStrings.salarySlipTitle,
                      description: AppStrings.salarySlipDesc,
                      hasSeeManual: false,
                      primaryButtonLabel: AppStrings.getSalarySlip,
                      primaryButtonIcon: Icons.article_outlined,
                      onPrimaryTap: () {},
                    ),

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
              // Open menu button (Fixed 44px x 44px, Radius 13px, Padding 1px 6px 1px 6px, Color #FFFFFF 14%)
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () {
                    _scaffoldKey.currentState?.openDrawer();
                  },
                  child: Container(
                    width: 44, // Exact Width: 44px
                    height: 44, // Exact Height: 44px
                    padding: const EdgeInsets.fromLTRB(6, 1, 6, 1), // Exact Padding: 1px 6px 1px 6px
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14), // Exact Color: #FFFFFF 14%
                      borderRadius: BorderRadius.circular(13), // Exact Radius: 13px
                    ),
                    child: const Icon(
                      Icons.menu_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),

              // Title Text: "SELF SERVICE PORTAL" (Width 157px x Height 15px, Size 12px, Weight 600 SemiBold, Letter spacing 1.68px)
              const SizedBox(
                width: 157, // Exact Width: 157px
                height: 15, // Exact Height: 15px
                child: Center(
                  child: Text(
                    AppStrings.selfServicePortalTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: Colors.white,
                      fontSize: 12, // Exact Size: 12px
                      fontWeight: FontWeight.w600, // Exact Weight: 600 SemiBold
                      letterSpacing: 1.68, // Exact Letter Spacing: 1.68px
                      height: 1.0, // Exact Line Height: 100%
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

// div.ssp-card: Fixed 354px x Hug 137.59px, Radii TL18 TR18 BR18 BL6, Padding 16px, Gap 16px, Color #FFFFFF
class _PortalServiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool hasSeeManual;
  final String primaryButtonLabel;
  final IconData primaryButtonIcon;
  final String? secondaryButtonLabel;
  final IconData? secondaryButtonIcon;
  final VoidCallback onPrimaryTap;
  final VoidCallback? onSecondaryTap;

  const _PortalServiceCard({
    required this.icon,
    required this.title,
    required this.description,
    this.hasSeeManual = false,
    required this.primaryButtonLabel,
    required this.primaryButtonIcon,
    this.secondaryButtonLabel,
    this.secondaryButtonIcon,
    required this.onPrimaryTap,
    this.onSecondaryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0), // Exact Padding: 16px
      decoration: const BoxDecoration(
        color: Colors.white, // Exact Color: #FFFFFF
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(18), // Exact TL: 18px
          topRight: Radius.circular(18), // Exact TR: 18px
          bottomRight: Radius.circular(18), // Exact BR: 18px
          bottomLeft: Radius.circular(6), // Exact BL: 6px
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Frame 45: Content Frame (Fill 322px x Hug 55.59px, Gap 8px)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Frame 44: Header Row (Fill 322px x Hug 28px, Gap 10px)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Soft pink icon badge
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCE8EE), // Soft pink badge
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      size: 16,
                      color: const Color(0xFFC6134B), // Burgundy maroon
                    ),
                  ),

                  const SizedBox(width: 10), // Exact Gap: 10px

                  // Title Text: Complaint (Width 211px x Height 18px, Font Outfit, Size 14px, Weight 500 Medium)
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14, // Exact Size: 14px
                        fontWeight: FontWeight.w500, // Exact Weight: 500 Medium
                        color: Color(0xFF1A1310), // Exact Hex: #1A1310
                        height: 1.0, // Exact Line Height: 100% (18px)
                      ),
                    ),
                  ),

                  // See Manual text button (Width 63px x Height 15px, Font Outfit, Size 12px, Weight 600 SemiBold, Color #8A5A10)
                  if (hasSeeManual)
                    GestureDetector(
                      onTap: () {},
                      child: const Text(
                        AppStrings.seeManual,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12, // Exact Size: 12px
                          fontWeight: FontWeight.w600, // Exact Weight: 600 SemiBold
                          color: Color(0xFF8A5A10), // Exact Hex: #8A5A10
                          height: 1.0, // Exact Line Height: 100% (15px)
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 8), // Exact Gap: 8px

              // Description Text
              Text(
                description,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF666666),
                  height: 1.35,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16), // Exact Gap: 16px

          // Action Buttons Row
          Row(
            children: [
              // Primary Button (Solid Burgundy)
              GestureDetector(
                onTap: onPrimaryTap,
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC6134B),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        primaryButtonIcon,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        primaryButtonLabel,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (secondaryButtonLabel != null) ...[
                const SizedBox(width: 10),

                // Secondary Button (Soft Pink)
                GestureDetector(
                  onTap: onSecondaryTap,
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCE8EE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (secondaryButtonIcon != null) ...[
                          Icon(
                            secondaryButtonIcon,
                            size: 16,
                            color: const Color(0xFFC6134B),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          secondaryButtonLabel!,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFC6134B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
