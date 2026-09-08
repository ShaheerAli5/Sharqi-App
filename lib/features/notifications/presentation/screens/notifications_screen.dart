import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/attendance_repository.dart';
import '../../../dashboard/presentation/widgets/app_drawer.dart';
import 'notification_detail_screen.dart';

class NotificationItem {
  final String id;
  final String title;
  final String description;
  final String date;
  final String badgeText;
  final Color badgeBgColor;
  final Color badgeTextColor;
  final bool isUnread;
  final String? englishBody;
  final String? arabicBody;
  final String? attachmentName;
  final Map<String, String>? extraDetails;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.badgeText,
    required this.badgeBgColor,
    required this.badgeTextColor,
    this.isUnread = false,
    this.englishBody,
    this.arabicBody,
    this.attachmentName,
    this.extraDetails,
  });
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final AttendanceRepository _attendanceRepository = AttendanceRepository();

  bool _isLoading = true;
  List<NotificationItem> _notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  String _cleanHtml(String text) {
    if (text.isEmpty) return '';
    String cleaned = text
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'</div>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");

    return cleaned.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    try {
      final list = await _attendanceRepository.getNotifications();
      List<NotificationItem> fetched = [];
      for (var item in list) {
        final title = item.subject.isNotEmpty ? item.subject : 'Notification';
        final desc = _cleanHtml(item.message);
        final date = item.timestamp;
        final tag = item.notificationTag.isNotEmpty ? item.notificationTag : 'Notification';
        fetched.add(NotificationItem(
          id: item.notificationId.toString(),
          title: title,
          description: desc,
          date: date,
          badgeText: tag,
          badgeBgColor: const Color(0xFFC6134B),
          badgeTextColor: Colors.white,
          isUnread: item.state != 'read',
          englishBody: desc,
        ));
      }
      setState(() {
        _notifications = fetched;
      });
    } catch (_) {
      setState(() => _notifications = []);
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
                child: _isLoading
                    ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
                    : _notifications.isEmpty
                    ? const Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Center(
                    child: Text(
                      'No notifications found',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14,
                        color: Color(0xFF888888),
                      ),
                    ),
                  ),
                )
                    : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _notifications.length,
                  separatorBuilder: (context, index) =>
                  const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final item = _notifications[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                NotificationDetailScreen(item: item),
                          ),
                        );
                      },
                      child: _buildNotificationCard(item),
                    );
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
    final cleanDesc = _cleanHtml(item.description);
    final previewText = cleanDesc.contains('---')
        ? cleanDesc.split('---')[0].trim()
        : cleanDesc;

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
            previewText,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
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
