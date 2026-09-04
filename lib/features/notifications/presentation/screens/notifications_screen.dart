import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../dashboard/presentation/widgets/app_drawer.dart';

class NotificationItem {
  final String title;
  final String description;
  final String date;
  final String badgeText;
  final Color badgeBgColor;
  final Color badgeTextColor;
  final bool isUnread;

  const NotificationItem({
    required this.title,
    required this.description,
    required this.date,
    required this.badgeText,
    required this.badgeBgColor,
    required this.badgeTextColor,
    this.isUnread = false,
  });
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<NotificationItem> _notifications = const [
    NotificationItem(
      title: 'CMS Memo Update',
      description:
          'Please be informed that the memo has been updated. Kindly note that all requests must be submitted through the CMS.',
      date: '23-Feb-2025 07:35 AM',
      badgeText: 'Attention - CMS',
      badgeBgColor: Color(0xFFC6134B), // Solid Maroon/Red
      badgeTextColor: Colors.white,
      isUnread: true,
    ),
    NotificationItem(
      title: 'Leave Request Approved',
      description:
          'Your annual leave request from 12 Jul to 18 Jul has been approved by your duty manager.',
      date: '20-Feb-2025 09:12 AM',
      badgeText: 'HR Update',
      badgeBgColor: Color(0xFFE2F7EB), // Soft green
      badgeTextColor: Color(0xFF1E854A), // Green text
      isUnread: true,
    ),
    NotificationItem(
      title: 'Salary Slip Available',
      description:
          'Your salary slip for January 2025 is now available for download.',
      date: '05-Feb-2025 03:40 PM',
      badgeText: 'Payroll',
      badgeBgColor: Color(0xFFFDEED9), // Soft tan/amber
      badgeTextColor: Color(0xFF8A5A10), // Brown text
      isUnread: false,
    ),
    NotificationItem(
      title: 'Shift Schedule Updated',
      description:
          'Your work schedule at Ritz Carlton Hotel has been revised for next week.',
      date: '02-Feb-2025 11:05 AM',
      badgeText: 'Work Plan',
      badgeBgColor: Color(0xFFEFECE8), // Soft grey
      badgeTextColor: Color(0xFF666666), // Grey text
      isUnread: false,
    ),
    NotificationItem(
      title: 'QID Expiry Reminder',
      description:
          'Your Qatar ID is set to expire in 30 days. Please renew and update your documents.',
      date: '28-Jan-2025 08:00 AM',
      badgeText: 'Action Required',
      badgeBgColor: Color(0xFFE85B7A), // Soft maroon/pink
      badgeTextColor: Colors.white,
      isUnread: false,
    ),
  ];

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
                padding: const EdgeInsets.all(20.0), // Exact Padding: 20px
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _notifications.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final item = _notifications[index];
                    return _buildNotificationCard(item);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem item) {
    return Container(
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
          // Header Row: Unread Dot + Title & Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Unread Indicator Dot
              if (item.isUnread) ...[
                Container(
                  margin: const EdgeInsets.only(top: 5, right: 6),
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFC6134B),
                    shape: BoxShape.circle,
                  ),
                ),
              ],

              // Title
              Expanded(
                child: Text(
                  item.title,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1310),
                    height: 1.1,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Category Badge Pill
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: item.badgeBgColor,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  item.badgeText,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: item.badgeTextColor,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Description Text
          Text(
            item.description,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
              color: Color(0xFF666666),
              height: 1.35,
            ),
          ),

          const SizedBox(height: 12),

          // Date / Time Text (Right Aligned)
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              item.date,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFF888888),
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
              // Open Drawer / Back Button Container
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    } else {
                      _scaffoldKey.currentState?.openDrawer();
                    }
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
                      Icons.chevron_left_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
              ),

              // Title Text: "NOTIFICATIONS"
              const SizedBox(
                height: 15,
                child: Center(
                  child: Text(
                    'NOTIFICATIONS',
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
