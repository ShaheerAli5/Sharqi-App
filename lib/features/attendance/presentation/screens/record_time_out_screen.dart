import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../dashboard/presentation/widgets/app_drawer.dart';

class RecordTimeOutScreen extends StatefulWidget {
  const RecordTimeOutScreen({super.key});

  @override
  State<RecordTimeOutScreen> createState() => _RecordTimeOutScreenState();
}

class _RecordTimeOutScreenState extends State<RecordTimeOutScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late Timer _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _onTimeOut() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Time Out recorded successfully!'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]}, ${dt.year}';
  }

  String _formatTime(DateTime dt) {
    final hourOfPeriod = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final hour = hourOfPeriod.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    final second = dt.second.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute:$second $period';
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
      key: _scaffoldKey,
      drawer: const AppDrawer(),
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
                color: Color(0xFFFBF6F3), // Exact Hex: #FBF6F3
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24), // Exact Radius: 24px
                ),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                child: Column(
                  children: [
                    // Profile Block
                    Column(
                      children: [
                        // Avatar Circle
                        Container(
                          width: 100, // Exact Width: 100px
                          height: 100, // Exact Height: 100px
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0xFFFBE7EE), // Exact Hex: #FBE7EE
                                Color(0xFFFBF6F3), // Exact Hex: #FBF6F3
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF1A1310).withValues(alpha: 0.28),
                                offset: const Offset(0, 10),
                                blurRadius: 22,
                                spreadRadius: -14,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.person_outline_rounded,
                              size: 48,
                              color: Color(0xFFC6134B),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Employee Name
                        const Text(
                          'Manpreet Singh Ranjeet Singh(2225)',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1310),
                            height: 21 / 16,
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Phone & EMP Badges Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Phone Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFDE8EE),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(
                                    Icons.phone_outlined,
                                    size: 12,
                                    color: Color(0xFFC6134B),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    AppStrings.phoneNumber,
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFC6134B),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 8),

                            // Employee ID Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFECE8),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                AppStrings.employeeId,
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF666666),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Input Tiles Card Container (Date & Time) (Fixed 354px x Hug 138px, Radius 12px, Padding 16px, Gap 16px, Color #FFFFFF)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16.0),
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
                        children: [
                          // 1. Date Display Tile (Fill 322px x Fixed 44px, Radius 12px, Color #FBF6F3)
                          Container(
                            height: 44, // Exact Height: Fixed 44px
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16), // Exact Padding: 16px
                            decoration: BoxDecoration(
                              color: const Color(0xFFFBF6F3), // Exact Hex: #FBF6F3
                              borderRadius: BorderRadius.circular(12), // Exact Radius: 12px
                              border: Border.all(
                                color: const Color(0xFFE8DFE1),
                                width: 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_month_outlined,
                                  color: Color(0xFF1A1310),
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _formatDate(_now),
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1A1310),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16), // Exact Gap: 16px

                          // 2. Time Display Tile (Fill 322px x Fixed 44px, Radius 12px, Color #FBF6F3)
                          Container(
                            height: 44, // Exact Height: Fixed 44px
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16), // Exact Padding: 16px
                            decoration: BoxDecoration(
                              color: const Color(0xFFFBF6F3), // Exact Hex: #FBF6F3
                              borderRadius: BorderRadius.circular(12), // Exact Radius: 12px
                              border: Border.all(
                                color: const Color(0xFFE8DFE1),
                                width: 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.access_time_rounded,
                                  color: Color(0xFF1A1310),
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _formatTime(_now),
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1A1310),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24), // Exact Gap: 24px

                    // Total Work Hours Section
                    Column(
                      children: const [
                        // Label: "Total Work Hours" (Width 120px x Height 20px, Size 16px, Weight 500 Medium, Letter spacing -0.2px, Color #C6134B)
                        Text(
                          'Total Work Hours',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 16, // Exact Size: 16px
                            fontWeight: FontWeight.w500, // Exact Weight: 500 Medium
                            color: Color(0xFFC6134B), // Exact Hex: #C6134B
                            letterSpacing: -0.2, // Exact Letter Spacing: -0.2px
                            height: 1.0, // Exact Line Height: 100%
                          ),
                        ),

                        SizedBox(height: 8), // Exact Gap: 8px

                        // Value: "5 Hours 0 Minutes" (Width 158px x Height 25px, Size 20px, Weight 600 SemiBold, Letter spacing -0.2px, Color #1A1310)
                        Text(
                          '5 Hours 0 Minutes',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 20, // Exact Size: 20px
                            fontWeight: FontWeight.w600, // Exact Weight: 600 SemiBold
                            color: Color(0xFF1A1310), // Exact Hex: #1A1310
                            letterSpacing: -0.2, // Exact Letter Spacing: -0.2px
                            height: 1.0, // Exact Line Height: 100%
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // HR Note & Time Out Button
                    Column(
                      children: [
                        const SizedBox(
                          width: 354,
                          child: Text(
                            'Note: Changes on submitted records only possible through HR Department',
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF6B5D58),
                              height: 19.2 / 12,
                              letterSpacing: 0.0,
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Time Out Button with Left Arrow
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _onTimeOut,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFC6134B),
                              elevation: 0,
                              padding: const EdgeInsets.fromLTRB(6, 1, 6, 1),
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
                                  'Time Out',
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  softWrap: false,
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: 0.16,
                                    height: 1.0,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(
                                  Icons.arrow_back_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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
              // Open Drawer Menu Button
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () {
                    _scaffoldKey.currentState?.openDrawer();
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    padding: const EdgeInsets.fromLTRB(6, 1, 6, 1),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.menu_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),

              // Title Text: "RECORD TIME OUT"
              const SizedBox(
                height: 15,
                child: Center(
                  child: Text(
                    'RECORD TIME OUT',
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
