import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/attendance_repository.dart';
import '../../../../core/services/storage_service.dart';
import '../widgets/app_drawer.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final AttendanceRepository _attendanceRepository = AttendanceRepository();

  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic> _dashboardData = {};

  @override
  void initState() {
    super.initState();
    _fetchDashboard();
  }

  Future<void> _fetchDashboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dashData = await _attendanceRepository.getDashboardData();
      if (!mounted) return;

      if (dashData.error != null &&
          dashData.error!.isNotEmpty &&
          !dashData.success) {
        setState(() {
          _errorMessage = dashData.error;
          _isLoading = false;
        });
      } else {
        if (dashData.fullName.isNotEmpty) {
          await StorageService.addValue(
              StorageService.keyFullName, dashData.fullName);
        }
        if (dashData.phone.isNotEmpty) {
          await StorageService.addValue(
              StorageService.keyPhone, dashData.phone);
        }
        if (dashData.whatsapp.isNotEmpty) {
          await StorageService.addValue(
              StorageService.keyWhatsAppPhone, dashData.whatsapp);
        }
        if (dashData.profileImage.isNotEmpty &&
            dashData.profileImage != 'N/A') {
          await StorageService.addValue(
              StorageService.keyProfileImage, dashData.profileImage);
        }
        if (dashData.company.isNotEmpty) {
          await StorageService.addValue(
              StorageService.keyCompanyName, dashData.company);
        }

        setState(() {
          _dashboardData = {
            'company': dashData.company,
            'join_date': dashData.joinDate,
            'qid_number': dashData.qidNumber,
            'qid_expiry': dashData.qidExpiry,
            'passport_number': dashData.passportNumber,
            'passport_expiry': dashData.passportExpiry,
            'gender': dashData.gender,
            'nationality': dashData.nationality,
            'work_location': dashData.workLocation,
            'location': dashData.location,
            'manager': dashData.manager,
            'full_name': dashData.fullName,
            'employee_number': dashData.empNo,
            'phone': dashData.phone,
            'whatsapp': dashData.whatsapp,
            'profile_image': dashData.profileImage,
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load Dashboard data: $e';
          _isLoading = false;
        });
      }
    }
  }

  String _formatFieldValue(dynamic val) {
    if (val == null) return 'N/A';
    final str = val.toString().trim();
    if (str.isEmpty || str == 'null' || str == '—') return 'N/A';
    return str;
  }

  String _getNationalityWithFlag(String nationality) {
    final clean = _formatFieldValue(nationality);
    if (clean == 'N/A') return 'N/A';
    final norm = clean.toLowerCase();
    if (norm.contains('india')) return '🇮🇳 $clean';
    if (norm.contains('qatar')) return '🇶🇦 $clean';
    if (norm.contains('pakistan')) return '🇵🇰 $clean';
    if (norm.contains('nepal')) return '🇳🇵 $clean';
    if (norm.contains('philippines') || norm.contains('filipino')) return '🇵🇭 $clean';
    if (norm.contains('bangladesh')) return '🇧🇩 $clean';
    if (norm.contains('egypt')) return '🇪🇬 $clean';
    if (norm.contains('sri lanka')) return '🇱🇰 $clean';
    return clean;
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

    final hasError = _errorMessage != null;

    final rawName = _formatFieldValue(_dashboardData['full_name']);
    final fullName = (rawName != 'N/A')
        ? rawName
        : (!hasError ? StorageService.getValue(StorageService.keyFullName) : 'Employee');

    final rawEmpNo = _formatFieldValue(_dashboardData['employee_number']);
    final empNo = (rawEmpNo != 'N/A')
        ? rawEmpNo
        : StorageService.getValue(StorageService.keyEmpNo);

    final rawPhone = _formatFieldValue(_dashboardData['phone']);
    final phone = (rawPhone != 'N/A')
        ? rawPhone
        : (!hasError ? StorageService.getValue(StorageService.keyPhone) : '');

    final rawWhatsapp = _formatFieldValue(_dashboardData['whatsapp']);
    final whatsapp = (rawWhatsapp != 'N/A')
        ? rawWhatsapp
        : (!hasError ? StorageService.getValue(StorageService.keyWhatsAppPhone) : '');

    final rawProfileImg = _formatFieldValue(_dashboardData['profile_image']);
    final profileImg = (rawProfileImg != 'N/A')
        ? rawProfileImg
        : (!hasError ? StorageService.getValue(StorageService.keyProfileImage) : '');

    final rawCompany = _formatFieldValue(_dashboardData['company']);
    final company = (rawCompany != 'N/A')
        ? rawCompany
        : (!hasError ? StorageService.getValue(StorageService.keyCompanyName) : '');

    final joinDate = _formatFieldValue(_dashboardData['join_date']);
    final qid = _formatFieldValue(_dashboardData['qid_number']);
    final qidExpiry = _formatFieldValue(_dashboardData['qid_expiry']);
    final passportNo = _formatFieldValue(_dashboardData['passport_number']);
    final passportExp = _formatFieldValue(_dashboardData['passport_expiry']);
    final gender = _formatFieldValue(_dashboardData['gender']);
    final nationality = _formatFieldValue(_dashboardData['nationality']);
    final workLocation = _formatFieldValue(_dashboardData['work_location']);
    final location = _formatFieldValue(_dashboardData['location']);
    final manager = _formatFieldValue(_dashboardData['manager']);

    final formattedNationality = _getNationalityWithFlag(nationality);

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      backgroundColor: AppColors.splashGradientStart,
      body: Column(
        children: [
          // Top Burgundy Header Container with Integrated Profile Card
          _buildHeader(
            context,
            fullName: fullName,
            empNo: empNo,
            phone: phone,
            whatsapp: whatsapp,
            profileImg: profileImg,
          ),

          // Main Scrollable Body Container
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFF9F5F3),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary))
                  : RefreshIndicator(
                      onRefresh: _fetchDashboard,
                      color: AppColors.primary,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            if (_errorMessage != null) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFEBEE),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFEF9A9A)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline_rounded,
                                        color: Color(0xFFC62828)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: const TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 12,
                                          color: Color(0xFFC62828),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 4),

                            // PERSONAL DETAILS CARD
                            _buildDetailsCard(
                              sectionTitle: 'PERSONAL DETAILS',
                              rows: [
                                _DetailRow(
                                  leftItem: _DetailItem(
                                    icon: Icons.person_outline_rounded,
                                    label: 'Gender',
                                    value: gender,
                                  ),
                                  rightItem: _DetailItem(
                                    icon: Icons.public_rounded,
                                    label: 'Nationality',
                                    value: formattedNationality,
                                  ),
                                ),
                                const _DividerLine(),
                                _DetailRow(
                                  leftItem: _DetailItem(
                                    icon: Icons.badge_outlined,
                                    label: 'QID',
                                    value: qid,
                                  ),
                                  rightItem: _DetailItem(
                                    icon: Icons.access_time_rounded,
                                    label: 'QID Expiry',
                                    value: qidExpiry,
                                  ),
                                ),
                                const _DividerLine(),
                                _DetailRow(
                                  leftItem: _DetailItem(
                                    icon: Icons.assignment_ind_outlined,
                                    label: 'Passport No.',
                                    value: passportNo,
                                  ),
                                  rightItem: _DetailItem(
                                    icon: Icons.calendar_today_rounded,
                                    label: 'Passport Exp.',
                                    value: passportExp,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // WORK DETAILS CARD
                            _buildDetailsCard(
                              sectionTitle: 'WORK DETAILS',
                              rows: [
                                _DetailRow(
                                  leftItem: _DetailItem(
                                    icon: Icons.apartment_rounded,
                                    label: 'Company',
                                    value: company,
                                  ),
                                  rightItem: _DetailItem(
                                    icon: Icons.calendar_month_rounded,
                                    label: 'Join Date',
                                    value: joinDate,
                                  ),
                                ),
                                const _DividerLine(),
                                _DetailRow(
                                  leftItem: _DetailItem(
                                    icon: Icons.explore_outlined,
                                    label: 'Location',
                                    value: location,
                                  ),
                                  rightItem: _DetailItem(
                                    icon: Icons.location_on_outlined,
                                    label: 'Work Location',
                                    value: workLocation,
                                  ),
                                ),
                                const _DividerLine(),
                                _DetailRow(
                                  leftItem: _DetailItem(
                                    icon: Icons.people_outline_rounded,
                                    label: 'Manager',
                                    value: manager,
                                  ),
                                  rightItem: const SizedBox(),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),
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

  Widget _buildDetailsCard({
    required String sectionTitle,
    required List<Widget> rows,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF6DFE2).withValues(alpha: 0.50),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF7A0E33),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  sectionTitle,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.8,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ...rows,
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context, {
    required String fullName,
    required String empNo,
    required String phone,
    required String whatsapp,
    required String profileImg,
  }) {
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
        child: Column(
          children: [
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Stack(
                alignment: Alignment.center,
                children: [
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
                  const SizedBox(
                    height: 15,
                    child: Center(
                      child: Text(
                        'DASHBOARD',
                        textAlign: TextAlign.center,
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

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 86,
                    height: 86,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.2),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: _buildProfileImage(profileImg),
                    ),
                  ),
                  const SizedBox(width: 14),

                  Expanded(
                    child: SizedBox(
                      height: 86,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            fullName.isNotEmpty ? fullName : 'Employee',
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: Colors.white,
                              height: 1.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                          if (empNo.isNotEmpty)
                            Container(
                              height: 18,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'EMP# $empNo',
                                    style: const TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      letterSpacing: 0.3,
                                      height: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          Row(
                            children: [
                              if (phone.isNotEmpty)
                                _PhoneChip(text: phone),
                              if (phone.isNotEmpty && whatsapp.isNotEmpty)
                                const SizedBox(width: 8),
                              if (whatsapp.isNotEmpty)
                                _WhatsAppChip(text: whatsapp),
                            ],
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
    );
  }

  Widget _buildProfileImage(String profileImg) {
    if (profileImg.isEmpty || profileImg == 'N/A') {
      return const Icon(
        Icons.person_outline_rounded,
        size: 40,
        color: Colors.white,
      );
    }

    try {
      if (profileImg.startsWith('http://') || profileImg.startsWith('https://')) {
        return Image.network(
          profileImg,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.person_outline_rounded,
            size: 40,
            color: Colors.white,
          ),
        );
      }

      String cleanBase64 = profileImg;
      if (cleanBase64.contains(',')) {
        cleanBase64 = cleanBase64.split(',').last;
      }
      cleanBase64 = cleanBase64.replaceAll(RegExp(r'\s+'), '');

      final bytes = base64Decode(cleanBase64);
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Icon(
          Icons.person_outline_rounded,
          size: 40,
          color: Colors.white,
        ),
      );
    } catch (_) {
      return const Icon(
        Icons.person_outline_rounded,
        size: 40,
        color: Colors.white,
      );
    }
  }
}

class _PhoneChip extends StatelessWidget {
  final String text;

  const _PhoneChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 33,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFC6134B),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 17,
            height: 17,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.35),
            ),
            child: const Center(
              child: Icon(
                Icons.phone_rounded,
                size: 10,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.white,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _WhatsAppChip extends StatelessWidget {
  final String text;

  const _WhatsAppChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 33,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF319B4C),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 17,
            height: 17,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF25D366),
            ),
            child: const Center(
              child: Icon(
                Icons.chat_bubble_rounded,
                size: 10,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.white,
              height: 1.0,
            ),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
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

  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 20,
          color: const Color(0xFF7A0E33),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF887775),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1310),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DividerLine extends StatelessWidget {
  const _DividerLine();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 4.0),
      child: Divider(
        color: Color(0xFFE8DCDA),
        thickness: 1,
        height: 1,
      ),
    );
  }
}
