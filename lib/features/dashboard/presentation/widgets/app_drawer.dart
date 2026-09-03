import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../routes/app_routes.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final currentRoute = ModalRoute.of(context)?.settings.name;

    final isDashboardSelected = currentRoute == AppRoutes.dashboard ||
        currentRoute == AppRoutes.home ||
        currentRoute == AppRoutes.splash;
    final isSelfServiceSelected = currentRoute == AppRoutes.selfServiceWeb;

    return Drawer(
      width: screenWidth, // Full width drawer as shown in design
      backgroundColor: AppColors.background,
      elevation: 0,
      child: Column(
        children: [
          // Top Burgundy Header Container (Frame 43: Fill 354px x Hug 173px)
          _buildHeader(context),

          // Main Cream Body Container
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFFBF6F3), // Exact Hex: #FBF6F3
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  child: Column(
                    children: [
                      // Menu Navigation Items
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1. DASHBOARD
                              _DrawerMenuItem(
                                icon: Icons.grid_view_rounded,
                                label: AppStrings.dashboardTitle,
                                isSelected: isDashboardSelected,
                                onTap: () {
                                  Navigator.pop(context);
                                  if (!isDashboardSelected) {
                                    Navigator.pushReplacementNamed(
                                      context,
                                      AppRoutes.dashboard,
                                    );
                                  }
                                },
                              ),

                              const SizedBox(height: 8),

                              // 2. SELF SERVICE WEB
                              _DrawerMenuItem(
                                icon: Icons.desktop_windows_outlined,
                                label: AppStrings.selfServiceWeb,
                                isSelected: isSelfServiceSelected,
                                onTap: () {
                                  Navigator.pop(context);
                                  if (!isSelfServiceSelected) {
                                    Navigator.pushReplacementNamed(
                                      context,
                                      AppRoutes.selfServiceWeb,
                                    );
                                  }
                                },
                              ),

                              const SizedBox(height: 8),

                              // 3. RECORD TIME IN
                              _DrawerMenuItem(
                                icon: Icons.more_time_rounded,
                                label: AppStrings.recordTimeIn,
                                onTap: () {
                                  Navigator.pop(context);
                                },
                              ),

                              const SizedBox(height: 8),

                              // 4. RECORD TIME OUT
                              _DrawerMenuItem(
                                icon: Icons.history_toggle_off_rounded,
                                label: AppStrings.recordTimeOut,
                                onTap: () {
                                  Navigator.pop(context);
                                },
                              ),

                              const SizedBox(height: 8),

                              // 5. ATTENDANCE LIST
                              _DrawerMenuItem(
                                icon: Icons.assignment_outlined,
                                label: AppStrings.attendanceList,
                                onTap: () {
                                  Navigator.pop(context);
                                },
                              ),

                              const SizedBox(height: 8),

                              // 6. WORK PLAN
                              _DrawerMenuItem(
                                icon: Icons.calendar_today_outlined,
                                label: AppStrings.workPlan,
                                onTap: () {
                                  Navigator.pop(context);
                                },
                              ),

                              const SizedBox(height: 8),

                              // 7. NOTIFICATIONS
                              _DrawerMenuItem(
                                icon: Icons.notifications_none_rounded,
                                label: AppStrings.notifications,
                                onTap: () {
                                  Navigator.pop(context);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      // button.btn-primary: LOGOUT Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              AppRoutes.signIn,
                              (route) => false,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color(0xFFC6134B).withValues(alpha: 0.08),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(26),
                                topRight: Radius.circular(26),
                                bottomRight: Radius.circular(26),
                                bottomLeft: Radius.circular(6),
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text(
                                AppStrings.logout,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFC6134B),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(
                                Icons.logout_rounded,
                                color: Color(0xFFC6134B),
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Right Close "X" Button
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 4),

              // Frame 42: Avatar + Name & Phone/WhatsApp Chips Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Circle Avatar
                  Container(
                    width: 53,
                    height: 53,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.22),
                    ),
                    child: const Icon(
                      Icons.person_outline_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Name & Contact Chips Column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          AppStrings.drawerNameShort,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            height: 1.0,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Row(
                          children: [
                            // Phone Chip
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(
                                    Icons.phone_outlined,
                                    size: 11,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    AppStrings.phoneNumber,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 6),

                            // WhatsApp Chip
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF25D366)
                                    .withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(
                                    Icons.chat_bubble_rounded,
                                    size: 11,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    AppStrings.whatsappNumber,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // span.phone-chip: EMP# 2225 Badge Pill
              Container(
                height: 25,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  AppStrings.employeeId,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.0,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // span.company-chip: Mr. VALET Parking Solutions Pill
              Container(
                height: 25,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFC6134B),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  AppStrings.companySolutionsValue,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.0,
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

// button.nav-item
class _DrawerMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DrawerMenuItem({
    required this.icon,
    required this.label,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        isSelected ? const Color(0xFFFBE7EE) : Colors.transparent;
    final textColor =
        isSelected ? const Color(0xFFC6134B) : const Color(0xFF1A1310);
    final iconColor =
        isSelected ? const Color(0xFFC6134B) : const Color(0xFF1A1310);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 43,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(14),
            topRight: Radius.circular(14),
            bottomRight: Radius.circular(14),
            bottomLeft: Radius.circular(4),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: iconColor,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: textColor,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
