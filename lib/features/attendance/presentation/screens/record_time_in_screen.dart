import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../dashboard/presentation/widgets/app_drawer.dart';

class RecordTimeInScreen extends StatefulWidget {
  const RecordTimeInScreen({super.key});

  @override
  State<RecordTimeInScreen> createState() => _RecordTimeInScreenState();
}

class _RecordTimeInScreenState extends State<RecordTimeInScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String _selectedWorkLocation = 'Work Location';
  final List<String> _locations = [
    'Work Location',
    'Doha Main Office',
    'Abu Sidra',
    'Rayyan Branch',
    'Wakra Site',
  ];

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

  void _showLocationModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFBF6F3),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
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
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'Select Work Location',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1310),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _locations.length,
                    separatorBuilder: (context, index) => const Divider(
                      height: 1,
                      color: AppColors.divider,
                    ),
                    itemBuilder: (context, index) {
                      final location = _locations[index];
                      final isSelected = location == _selectedWorkLocation;
                      return ListTile(
                        title: Text(
                          location,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 15,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? AppColors.primary
                                : const Color(0xFF1A1310),
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_circle,
                                color: AppColors.primary,
                              )
                            : null,
                        onTap: () {
                          setState(() {
                            _selectedWorkLocation = location;
                          });
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onTimeIn() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Time In recorded successfully!'),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 24.0,
                ),
                child: Column(
                  children: [
                    // Frame 2147224465: Top Section Frame (Fill 354px x Hug 390px, Gap 24px)
                    Column(
                      children: [
                        // Frame 2147224460: Profile Block (Fill 354px x Hug 166px, Gap 10px)
                        Column(
                          children: [
                            // div.rti-avatar: Avatar Circle (Fixed 100px x 100px, Radius 50px, Linear Gradient #FBE7EE -> #FBF6F3, Drop Shadow)
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
                                    color: const Color(0xFF1A1310).withValues(alpha: 0.28), // Exact Hex: #1A1310 28%
                                    offset: const Offset(0, 10), // Exact Y: 10
                                    blurRadius: 22, // Exact Blur: 22
                                    spreadRadius: -14, // Exact Spread: -14
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

                            const SizedBox(height: 10), // Exact Gap: 10px

                            // p#rtiName: Employee Name (Fill 354px x Hug 21px)
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

                            const SizedBox(height: 10), // Exact Gap: 10px

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

                        const SizedBox(height: 24), // Exact Gap: 24px

                        // div.ssp-list: Input Tiles Container (Fixed 354px x Hug 200px, Gap 14px)
                        Column(
                          children: [
                            // 1. Work Location Selection Tile (Fill 322px x Fixed 44px, Radius 12px, Color #FBF6F3)
                            GestureDetector(
                              onTap: _showLocationModal,
                              child: Container(
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
                                    // Icon: vuesax/bold/location (24px x 24px)
                                    const Icon(
                                      Icons.location_on_rounded,
                                      color: Color(0xFFC6134B),
                                      size: 24, // Exact Size: 24px
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _selectedWorkLocation,
                                        style: const TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 16, // Exact Size: 16px
                                          fontWeight: FontWeight.w500, // Exact Weight: 500 Medium
                                          color: Color(0xFF1A1310), // Exact Hex: #1A1310
                                          letterSpacing: -0.2, // Exact Letter Spacing: -0.2px
                                          height: 1.0, // Exact Line Height: 100%
                                        ),
                                      ),
                                    ),
                                    const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: Color(0xFFC6134B),
                                      size: 22,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 14), // Exact Gap: 14px

                            // 2. Date Display Tile (Fill 322px x Fixed 44px, Radius 12px, Color #FBF6F3)
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

                            const SizedBox(height: 14), // Exact Gap: 14px

                            // 3. Time Display Tile (Fill 322px x Fixed 44px, Radius 12px, Color #FBF6F3)
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
                      ],
                    ),

                    const SizedBox(height: 28),

                    // Frame 2147224466: Bottom Section Frame (Fixed 354px x Hug 101px, Gap 14px)
                    Column(
                      children: [
                        // HR Note Text (Width 354px x Height 39px, Size 12px, Weight 500 Medium, Line Height 19.2px, Color #6B5D58)
                        const SizedBox(
                          width: 354, // Exact Width: 354px
                          child: Text(
                            'Note: Changes on submitted records only possible through HR Department',
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12, // Exact Size: 12px
                              fontWeight: FontWeight.w500, // Exact Weight: 500 Medium
                              color: Color(0xFF6B5D58), // Exact Hex: #6B5D58
                              height: 19.2 / 12, // Exact Line Height: 19.2px
                              letterSpacing: 0.0, // Exact Letter Spacing: 0%
                            ),
                          ),
                        ),

                        const SizedBox(height: 14), // Exact Gap: 14px

                        // button.btn-primary: Time In Button (Fill 354px x Fixed 48px, Radii TL26 TR26 BR26 BL6, Padding 1px 6px 1px 6px, Gap 8px, Color #C6134B)
                        SizedBox(
                          width: double.infinity,
                          height: 48, // Exact Height: Fixed 48px
                          child: ElevatedButton(
                            onPressed: _onTimeIn,
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
                              children: const [
                                // Text: "Time In" (Width 54px x Height 20px, Size 16px, Weight 400 Regular, Letter spacing 0.16px, Color #FFFFFF)
                                Text(
                                  'Time In',
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  softWrap: false,
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    color: Colors.white,
                                    fontSize: 16, // Exact Size: 16px
                                    fontWeight: FontWeight.w400, // Exact Weight: 400 Regular
                                    letterSpacing: 0.16, // Exact Letter Spacing: 0.16px
                                    height: 1.0, // Exact Line Height: 100%
                                  ),
                                ),

                                SizedBox(width: 8), // Exact Gap: 8px (~7.99px)

                                // Frame Icon: (Width 16px x Height 16px)
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 16, // Exact Size: 16px
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

              // Title Text: "RECORD TIME IN"
              const SizedBox(
                height: 15,
                child: Center(
                  child: Text(
                    'RECORD TIME IN',
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
