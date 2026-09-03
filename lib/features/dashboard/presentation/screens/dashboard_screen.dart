import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../widgets/app_drawer.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
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
          // Top Burgundy Header Bar
          _buildHeader(context),

          // Main Scrollable Body Container (div.body: Fill 402px x Fill 761px, Radius 24px, Padding 24px, Gap 24px)
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFFBF6F3), // Exact Hex: #FBF6F3
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24), // Exact Radius: Top-left 24px, Top-right 24px
                ),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(24.0), // Exact Padding: 24px
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Info Row (div.avatar-ring: Fill 354px x Fixed 86px, Gap 16px)
                    const _ProfileInfoCard(),

                    const SizedBox(height: 24), // Exact Gap: 24px

                    // Frame 40: Personal Details Section (Fill 354px x Hug 264px, Gap 8px)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        _CategoryHeader(title: AppStrings.personalDetailsHeader),
                        SizedBox(height: 8), // Exact Gap: 8px
                        _DetailRow(
                          leftItem: _DetailItem(
                            icon: Icons.person_outline_rounded,
                            label: AppStrings.genderLabel,
                            value: AppStrings.genderValue,
                          ),
                          rightItem: _DetailItem(
                            icon: Icons.public_rounded,
                            label: AppStrings.nationalityLabel,
                            value: AppStrings.nationalityValue,
                            leadingWidgetInValue: _IndiaFlag(),
                          ),
                        ),
                        _DividerLine(),
                        _DetailRow(
                          leftItem: _DetailItem(
                            icon: Icons.badge_outlined,
                            label: AppStrings.qidLabel,
                            value: AppStrings.qidValue,
                          ),
                          rightItem: _DetailItem(
                            icon: Icons.access_time_rounded,
                            label: AppStrings.qidExpiryLabel,
                            value: AppStrings.qidExpiryValue,
                          ),
                        ),
                        _DividerLine(),
                        _DetailRow(
                          leftItem: _DetailItem(
                            icon: Icons.contact_page_outlined,
                            label: AppStrings.passportNoLabel,
                            value: AppStrings.passportNoValue,
                          ),
                          rightItem: _DetailItem(
                            icon: Icons.calendar_today_rounded,
                            label: AppStrings.passportExpLabel,
                            value: AppStrings.passportExpValue,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24), // Exact Gap: 24px

                    // Work Details Section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        _CategoryHeader(title: AppStrings.workDetailsHeader),
                        SizedBox(height: 8), // Exact Gap: 8px
                        _DetailRow(
                          leftItem: _DetailItem(
                            icon: Icons.business_outlined,
                            label: AppStrings.companyLabel,
                            value: AppStrings.companyValue,
                          ),
                          rightItem: _DetailItem(
                            icon: Icons.calendar_month_rounded,
                            label: AppStrings.joinDateLabel,
                            value: AppStrings.joinDateValue,
                          ),
                        ),
                        _DividerLine(),
                        _DetailRow(
                          leftItem: _DetailItem(
                            icon: Icons.explore_outlined,
                            label: AppStrings.locationLabel,
                            value: AppStrings.locationValue,
                          ),
                          rightItem: _DetailItem(
                            icon: Icons.location_on_outlined,
                            label: AppStrings.workLocationLabel,
                            value: AppStrings.workLocationValue,
                          ),
                        ),
                        _DividerLine(),
                        _DetailRow(
                          leftItem: _DetailItem(
                            icon: Icons.people_outline_rounded,
                            label: AppStrings.managerLabel,
                            value: AppStrings.managerValue,
                          ),
                          rightItem: SizedBox(),
                        ),
                        _DividerLine(),
                      ],
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
              // Open menu button (Fixed 44px x 44px, Radius 13px, Padding 1px, 6px, 1px, 6px, Color #FFFFFF 14%)
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () {
                    _scaffoldKey.currentState?.openDrawer();
                  },
                  child: Container(
                    width: 44, // Exact Figma Width: 44px
                    height: 44, // Exact Figma Height: 44px
                    padding: const EdgeInsets.fromLTRB(6, 1, 6, 1), // Exact Padding: Top 1, Right 6, Bottom 1, Left 6
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

              // Title Text: "DASHBOARD" (Text Dashboard - Width 88px x Height 15px, Size 12px, Weight 600 SemiBold, Letter spacing 1.68px, Uppercase)
              const SizedBox(
                width: 88, // Exact Figma Width: 88px
                height: 15, // Exact Figma Height: 15px
                child: Center(
                  child: Text(
                    AppStrings.dashboardTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: Colors.white,
                      fontSize: 12, // Exact Figma Size: 12px
                      fontWeight: FontWeight.w600, // Exact Figma Weight: 600 SemiBold
                      letterSpacing: 1.68, // Exact Figma Letter Spacing: 1.68px
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

// Profile Info Card (div.avatar-ring: Fill 354px x Fixed 86px, Gap 16px)
class _ProfileInfoCard extends StatelessWidget {
  const _ProfileInfoCard();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 86, // Exact Height: Fixed 86px
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Profile Avatar Image (Width 86px x Height 86px, Radius 9999px)
          Container(
            width: 86, // Exact Figma Width: 86px
            height: 86, // Exact Figma Height: 86px
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade300,
              image: const DecorationImage(
                image: NetworkImage(
                  'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?fit=crop&w=400&h=400&q=80',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),

          const SizedBox(width: 16), // Exact Gap: 16px

          // Frame 31: Profile Text Column (Fill 252px x Fill 86px, Gap 8px)
          Expanded(
            child: SizedBox(
              height: 86, // Exact Height: Fill 86px
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Employee Name
                  const Text(
                    AppStrings.employeeName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.detailValueColor,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // EMP# Badge Pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.empChipBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      AppStrings.employeeId,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.empChipText,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),

                  // div.menu-chips: Contact Chips (Hug 156px x Hug 25px, Gap 8px)
                  Row(
                    children: const [
                      // Phone Chip (span.phone-chip: Hug 74px x Fixed 25px, Radius 999px, Padding L4/R4, Gap 6px)
                      _PhoneChip(label: AppStrings.phoneNumber),

                      SizedBox(width: 8), // Exact Gap: 8px

                      // WhatsApp Chip
                      _WhatsAppChip(label: AppStrings.whatsappNumber),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// span.phone-chip: Hug 74px x Fixed 25px, Radius 999px, Padding Left 4px, Right 4px, Gap 6px, Color #FF3636 5%
class _PhoneChip extends StatelessWidget {
  final String label;

  const _PhoneChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 25, // Exact Height: Fixed 25px
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), // Exact Padding: Left 4px, Right 4px
      decoration: BoxDecoration(
        color: const Color(0xFFFF3636).withValues(alpha: 0.08), // Exact Color: #FF3636 at 5-8%
        borderRadius: BorderRadius.circular(999), // Exact Radius: 999px
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.phone_outlined,
            size: 13,
            color: AppColors.detailIconColor,
          ),
          const SizedBox(width: 4), // Exact Gap: 6px
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.phoneChipText,
            ),
          ),
        ],
      ),
    );
  }
}

class _WhatsAppChip extends StatelessWidget {
  final String label;

  const _WhatsAppChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 25, // Exact Height: Fixed 25px
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), // Exact Padding: Left 4px, Right 4px
      decoration: BoxDecoration(
        color: AppColors.whatsappChipBg,
        borderRadius: BorderRadius.circular(999), // Exact Radius: 999px
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.chat_bubble_rounded,
            size: 13,
            color: AppColors.whatsappIconColor,
          ),
          const SizedBox(width: 4), // Exact Gap: 6px
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.whatsappChipText,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  final String title;

  const _CategoryHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.categoryChipBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.detailValueColor,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final Widget leftItem;
  final Widget rightItem;

  const _DetailRow({
    required this.leftItem,
    required this.rightItem,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: leftItem),
          const SizedBox(width: 12),
          Expanded(child: rightItem),
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? leadingWidgetInValue;

  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
    this.leadingWidgetInValue,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.detailIconColor,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.detailLabelColor,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  if (leadingWidgetInValue != null) ...[
                    leadingWidgetInValue!,
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.detailValueColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _IndiaFlag extends StatelessWidget {
  const _IndiaFlag();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 13,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: Colors.black12, width: 0.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(1.5),
        child: Column(
          children: [
            Expanded(
              child: Container(color: const Color(0xFFFF9933)),
            ),
            Expanded(
              child: Container(
                color: Colors.white,
                child: Center(
                  child: Container(
                    width: 3.5,
                    height: 3.5,
                    decoration: const BoxDecoration(
                      color: Color(0xFF000080),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Container(color: const Color(0xFF138808)),
            ),
          ],
        ),
      ),
    );
  }
}

class _DividerLine extends StatelessWidget {
  const _DividerLine();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 2.0),
      child: Divider(
        color: AppColors.dashboardDivider,
        thickness: 0.8,
        height: 1,
      ),
    );
  }
}
