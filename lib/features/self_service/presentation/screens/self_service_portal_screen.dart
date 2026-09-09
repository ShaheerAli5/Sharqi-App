import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/attendance_repository.dart';
import '../../../../data/models/portal_service_item.dart';
import '../../../../routes/app_routes.dart';
import '../../../dashboard/presentation/widgets/app_drawer.dart';
import 'track_case_screen.dart';

class SelfServicePortalScreen extends StatefulWidget {
  const SelfServicePortalScreen({super.key});

  @override
  State<SelfServicePortalScreen> createState() =>
      _SelfServicePortalScreenState();
}

class _SelfServicePortalScreenState extends State<SelfServicePortalScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final AttendanceRepository _attendanceRepository = AttendanceRepository();

  bool _isLoading = true;
  List<PortalServiceItem> _portalItems = [];

  @override
  void initState() {
    super.initState();
    _fetchPortalItems();
  }

  Future<void> _fetchPortalItems() async {
    setState(() => _isLoading = true);
    try {
      final items = await _attendanceRepository.getSelfServicePortalItems();
      if (mounted) {
        setState(() {
          _portalItems = items;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  IconData _getIconForAction(String actionType) {
    switch (actionType) {
      case 'complaint':
        return Icons.add_rounded;
      case 'employee_request':
        return Icons.group_outlined;
      case 'leave_request':
        return Icons.calendar_month_outlined;
      case 'bright_idea':
        return Icons.lightbulb_outline_rounded;
      case 'salary_slip':
        return Icons.article_outlined;
      default:
        return Icons.grid_view_rounded;
    }
  }

  IconData _getPrimaryIconForAction(String actionType) {
    switch (actionType) {
      case 'complaint':
        return Icons.add_rounded;
      case 'employee_request':
        return Icons.group_outlined;
      case 'leave_request':
        return Icons.calendar_today_rounded;
      case 'bright_idea':
        return Icons.lightbulb_outline_rounded;
      case 'salary_slip':
        return Icons.article_outlined;
      default:
        return Icons.arrow_forward_rounded;
    }
  }

  VoidCallback _getPrimaryAction(BuildContext context, String actionType) {
    switch (actionType) {
      case 'complaint':
        return () => Navigator.pushNamed(context, AppRoutes.complaintForm);
      case 'employee_request':
        return () =>
            Navigator.pushNamed(context, AppRoutes.employeeRequestForm);
      case 'leave_request':
        return () => Navigator.pushNamed(context, AppRoutes.leaveRequestForm);
      case 'bright_idea':
        return () => Navigator.pushNamed(context, AppRoutes.brightIdeaForm);
      case 'salary_slip':
        return () => Navigator.pushNamed(context, AppRoutes.salarySlip);
      default:
        return () {};
    }
  }

  VoidCallback? _getSecondaryAction(BuildContext context, String actionType) {
    switch (actionType) {
      case 'complaint':
      case 'employee_request':
        return () => Navigator.pushNamed(context, AppRoutes.trackCase);
      case 'leave_request':
        return () => Navigator.pushNamed(
              context,
              AppRoutes.trackCase,
              arguments: const TrackCaseArguments(
                labelText: 'LEAVE CODE',
                hintText: '',
                buttonText: 'Search Leave',
              ),
            );
      default:
        return null;
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
                color: Color(0xFFFBF6F3),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    )
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 24.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(
                            width: double.infinity,
                            child: Text(
                              AppStrings.portalIntroSubtitle,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF1A1310),
                                height: 20.3 / 14,
                                letterSpacing: -0.14,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _portalItems.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 14),
                            itemBuilder: (context, index) {
                              final item = _portalItems[index];
                              return _PortalServiceCard(
                                icon: _getIconForAction(item.actionType),
                                imageUrl: item.imageUrl,
                                title: item.title,
                                description: item.description,
                                hasSeeManual: item.hasSeeManual,
                                primaryButtonLabel: item.primaryButtonLabel,
                                primaryButtonIcon:
                                    _getPrimaryIconForAction(item.actionType),
                                secondaryButtonLabel:
                                    item.secondaryButtonLabel,
                                secondaryButtonIcon:
                                    item.secondaryButtonLabel != null
                                        ? Icons.search_rounded
                                        : null,
                                onPrimaryTap: _getPrimaryAction(
                                    context, item.actionType),
                                onSecondaryTap: _getSecondaryAction(
                                    context, item.actionType),
                              );
                            },
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
                height: 15,
                child: Center(
                  child: Text(
                    AppStrings.selfServicePortalTitle,
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

class _PortalServiceCard extends StatelessWidget {
  final IconData icon;
  final String? imageUrl;
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
    this.imageUrl,
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
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
          bottomRight: Radius.circular(18),
          bottomLeft: Radius.circular(6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCE8EE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: imageUrl != null && imageUrl!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Icon(
                                icon,
                                size: 16,
                                color: const Color(0xFFC6134B),
                              ),
                            ),
                          )
                        : Icon(
                            icon,
                            size: 16,
                            color: const Color(0xFFC6134B),
                          ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A1310),
                        height: 1.0,
                      ),
                    ),
                  ),
                  if (hasSeeManual)
                    GestureDetector(
                      onTap: () {},
                      child: const Text(
                        AppStrings.seeManual,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF8A5A10),
                          height: 1.0,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
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
          const SizedBox(height: 16),
          Row(
            children: [
              GestureDetector(
                onTap: onPrimaryTap,
                child: Container(
                  height: 34,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFC6134B),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                      bottomRight: Radius.circular(10),
                      bottomLeft: Radius.circular(4),
                    ),
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
                          fontFamily: 'Outfit',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (secondaryButtonLabel != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onSecondaryTap,
                  child: Container(
                    height: 34,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFBE7EE),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10),
                        bottomRight: Radius.circular(10),
                        bottomLeft: Radius.circular(4),
                      ),
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
                            fontFamily: 'Outfit',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFC6134B),
                            height: 1.0,
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
