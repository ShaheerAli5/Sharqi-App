import 'package:flutter/material.dart';
import '../features/splash/presentation/screens/splash_screen.dart';
import '../features/auth/presentation/screens/sign_in_screen.dart';
import '../features/auth/presentation/screens/verification_screen.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/self_service/presentation/screens/self_service_portal_screen.dart';
import '../features/self_service/presentation/screens/complaint_form_screen.dart';
import '../features/self_service/presentation/screens/track_case_screen.dart';
import '../features/self_service/presentation/screens/employee_request_form_screen.dart';
import '../features/self_service/presentation/screens/leave_request_form_screen.dart';
import '../features/self_service/presentation/screens/bright_idea_form_screen.dart';
import '../features/attendance/presentation/screens/record_time_in_screen.dart';
import '../features/attendance/presentation/screens/record_time_out_screen.dart';
import '../features/attendance/presentation/screens/attendance_list_screen.dart';
import '../features/attendance/presentation/screens/work_plan_screen.dart';
import '../features/notifications/presentation/screens/notifications_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String signIn = '/sign-in';
  static const String verification = '/verification';
  static const String home = '/home';
  static const String dashboard = '/dashboard';
  static const String selfServiceWeb = '/self-service-web';
  static const String complaintForm = '/complaint-form';
  static const String trackCase = '/track-case';
  static const String employeeRequestForm = '/employee-request-form';
  static const String leaveRequestForm = '/leave-request-form';
  static const String brightIdeaForm = '/bright-idea-form';
  static const String recordTimeIn = '/record-time-in';
  static const String recordTimeOut = '/record-time-out';
  static const String attendanceList = '/attendance-list';
  static const String workPlan = '/work-plan';
  static const String notifications = '/notifications';

  static Map<String, WidgetBuilder> get routes => {
        splash: (context) => const SplashScreen(),
        signIn: (context) => const SignInScreen(),
        verification: (context) => const VerificationScreen(),
        home: (context) => const HomeScreen(),
        dashboard: (context) => const DashboardScreen(),
        selfServiceWeb: (context) => const SelfServicePortalScreen(),
        complaintForm: (context) => const ComplaintFormScreen(),
        trackCase: (context) => const TrackCaseScreen(),
        employeeRequestForm: (context) => const EmployeeRequestFormScreen(),
        leaveRequestForm: (context) => const LeaveRequestFormScreen(),
        brightIdeaForm: (context) => const BrightIdeaFormScreen(),
        recordTimeIn: (context) => const RecordTimeInScreen(),
        recordTimeOut: (context) => const RecordTimeOutScreen(),
        attendanceList: (context) => const AttendanceListScreen(),
        workPlan: (context) => const WorkPlanScreen(),
        notifications: (context) => const NotificationsScreen(),
      };
}
