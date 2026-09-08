import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
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
  Map<String, dynamic> _dashboardData = {};

  @override
  void initState() {
    super.initState();
    _fetchDashboard();
  }

  Future<void> _fetchDashboard() async {
    setState(() => _isLoading = true);
    try {
      final dashData = await _attendanceRepository.getDashboardData();
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
        };
      });
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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

    final fullName = _dashboardData['full_name']?.toString().isNotEmpty == true
        ? _dashboardData['full_name'].toString()
        : StorageService.getValue(StorageService.keyFullName);

    final empNo = _dashboardData['employee_number']?.toString().isNotEmpty == true
        ? _dashboardData['employee_number'].toString()
        : StorageService.getValue(StorageService.keyEmpNo);

    final phone = _dashboardData['phone']?.toString().isNotEmpty == true
        ? _dashboardData['phone'].toString()
        : StorageService.getValue(StorageService.keyPhone);

    final whatsapp = _dashboardData['whatsapp']?.toString().isNotEmpty == true
        ? _dashboardData['whatsapp'].toString()
        : StorageService.getValue(StorageService.keyWhatsAppData);

    final company = _dashboardData['company']?.toString() ?? StorageService.getValue(StorageService.keyCompanyName);
    final joinDate = _dashboardData['join_date']?.toString() ?? '';
    final qid = _dashboardData['qid_number']?.toString() ?? '';
    final qidExpiry = _dashboardData['qid_expiry']?.toString() ?? '';
    final passportNo = _dashboardData['passport_number']?.toString() ?? '';
    final passportExp = _dashboardData['passport_expiry']?.toString() ?? '';
    final gender = _dashboardData['gender']?.toString() ?? '';
    final nationality = _dashboardData['nationality']?.toString() ?? '';
    final workLocation = _dashboardData['work_location']?.toString() ?? '';
    final location = _dashboardData['location']?.toString() ?? '';
    final manager = _dashboardData['manager']?.toString() ?? '';

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Top Burgundy Header Bar
          _buildHeader(context),

          // Main Scrollable Body Container
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFFBF6F3), // Exact Hex: #FBF6F3
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Info Row
                    _ProfileInfoCard(
                      name: fullName,
                      empId: empNo.isNotEmpty ? 'EMP#$empNo' : '',
                      phone: phone,
                      whatsapp: whatsapp,
                    ),

                    const SizedBox(height: 24),

                    // Personal Details Section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _CategoryHeader(title: AppStrings.personalDetailsHeader),
                        const SizedBox(height: 8),
                        _DetailRow(
                          leftItem: _DetailItem(
                            icon: Icons.person_outline_rounded,
                            label: AppStrings.genderLabel,
                            value: gender,
                          ),
                          rightItem: _DetailItem(
                            icon: Icons.public_rounded,
                            label: AppStrings.nationalityLabel,
                            value: nationality,
                          ),
                        ),
                        const _DividerLine(),
                        _DetailRow(
                          leftItem: _DetailItem(
                            icon: Icons.badge_outlined,
                            label: AppStrings.qidLabel,
                            value: qid,
                          ),
                          rightItem: _DetailItem(
                            icon: Icons.access_time_rounded,
                            label: AppStrings.qidExpiryLabel,
                            value: qidExpiry,
                          ),
                        ),
                        const _DividerLine(),
                        _DetailRow(
                          leftItem: _DetailItem(
                            icon: Icons.contact_page_outlined,
                            label: AppStrings.passportNoLabel,
                            value: passportNo,
                          ),
                          rightItem: _DetailItem(
                            icon: Icons.calendar_today_rounded,
                            label: AppStrings.passportExpLabel,
                            value: passportExp,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Work Details Section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _CategoryHeader(title: AppStrings.workDetailsHeader),
                        const SizedBox(height: 8),
                        _DetailRow(
                          leftItem: _DetailItem(
                            icon: Icons.business_outlined,
                            label: AppStrings.companyLabel,
                            value: company,
                          ),
                          rightItem: _DetailItem(
                            icon: Icons.calendar_month_rounded,
                            label: AppStrings.joinDateLabel,
                            value: joinDate,
                          ),
                        ),
                        const _DividerLine(),
                        _DetailRow(
                          leftItem: _DetailItem(
                            icon: Icons.explore_outlined,
                            label: AppStrings.locationLabel,
                            value: location,
                          ),
                          rightItem: _DetailItem(
                            icon: Icons.location_on_outlined,
                            label: AppStrings.workLocationLabel,
                            value: workLocation,
                          ),
                        ),
                        const _DividerLine(),
                        _DetailRow(
                          leftItem: _DetailItem(
                            icon: Icons.people_outline_rounded,
                            label: AppStrings.managerLabel,
                            value: manager,
                          ),
                          rightItem: const SizedBox(),
                        ),
                        const _DividerLine(),
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
                width: 88,
                height: 15,
                child: Center(
                  child: Text(
                    AppStrings.dashboardTitle,
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
      ),
    );
  }
}

// Profile Info Card
class _ProfileInfoCard extends StatelessWidget {
  final String name;
  final String empId;
  final String phone;
  final String whatsapp;

  const _ProfileInfoCard({
    required this.name,
    required this.empId,
    required this.phone,
    required this.whatsapp,
  });

  @override
  Widget build(BuildContext context) {
    final profileImg = StorageService.getValue(StorageService.keyProfileImage);

    return SizedBox(
      height: 86, // Exact Height: Fixed 86px
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 86, // Exact Figma Width: 86px
            height: 86, // Exact Figma Height: 86px
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade300,
            ),
            child: profileImg.isNotEmpty
                ? ClipOval(
              child: Image.network(
                profileImg,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.person_outline_rounded,
                  size: 40,
                  color: AppColors.primary,
                ),
              ),
            )
                : const Icon(
              Icons.person_outline_rounded,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SizedBox(
              height: 86,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    name.isNotEmpty ? name : 'Employee',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.detailValueColor,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (empId.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.empChipBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        empId,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.empChipText,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  Row(
                    children: [
                      if (phone.isNotEmpty) _PhoneChip(label: phone),
                      if (phone.isNotEmpty && whatsapp.isNotEmpty) const SizedBox(width: 8),
                      if (whatsapp.isNotEmpty) _WhatsAppChip(label: whatsapp),
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

class _PhoneChip extends StatelessWidget {
  final String label;

  const _PhoneChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 25,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFFF3636).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.phone_outlined,
            size: 13,
            color: AppColors.detailIconColor,
          ),
          const SizedBox(width: 4),
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
      height: 25,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.whatsappChipBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.chat_bubble_rounded,
            size: 13,
            color: AppColors.whatsappIconColor,
          ),
          const SizedBox(width: 4),
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

  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
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

