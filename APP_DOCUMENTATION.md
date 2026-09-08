# Al Sharqi Holding Self Service App — Complete Technical Documentation

**Target App:** Al Sharqi Holding Self Service App (`com.selfservice.app`)  
**Flutter Workspace:** `C:\Users\Shaheer\Documents\GitHub\Sharqi-App`  
**Native Source Codebase:** `D:\selfservice-webview-new_updates_nov_2024`  
**Backend Host:** `https://erp.alsharqiholding.qa`  
**ERP System:** Odoo 14 ERP (`/alsharqi/`)  
**Protocol:** Odoo JSON-RPC 2.0 over HTTP `POST`  
**Document Version:** 1.0.0 (Production Migration)  

---

## 1. Executive Summary

This document serves as the authoritative, end-to-end technical specification for the **Al Sharqi Holding Self Service App** Flutter migration. The application enables employees across Al Sharqi Holding and its subsidiaries (including Al Sharqi Shipping, Mr. Valet, etc.) to perform daily GPS-verified time attendance (Clock In / Clock Out), view work schedules, track monthly attendance history, receive push notifications, and access HR self-service portal features.

### Core Stack & Framework
* **Framework:** Flutter (Dart 3.x)
* **HTTP Client:** Dio 5.x with 60-second timeouts & JSON-RPC request envelope builder
* **Local Storage:** `SharedPreferences` + `FlutterSecureStorage` supporting 11 native DataStore keys
* **Location Services:** `geolocator` with high-accuracy GPS capture & 10s position timeout fallback
* **Push Notifications:** Firebase Cloud Messaging (`firebase_messaging`) & Local Notifications (`flutter_local_notifications`)
* **Embedded Web:** `webview_flutter` with DOM storage and file selection delegates

---

## 2. Backend Architecture & Odoo JSON-RPC Contract

All network interactions hit Odoo 14 ERP endpoint routes over HTTP `POST`.

### Request Payload Envelope
Every request MUST encapsulate parameters inside a top-level `params` key:
```json
{
  "jsonrpc": "2.0",
  "method": "call",
  "params": {
    "employee_number": "10091",
    "company_id": "1",
    "api_token": "d8f3b2049e71a5c68f9a2b0e4d7c18e3f"
  },
  "id": 1
}
```
*(When no body parameters are needed, `"params": ""` is passed).*

### Response Payload Envelope
Every response arrives wrapped inside a top-level `result` object:
```json
{
  "jsonrpc": "2.0",
  "id": null,
  "result": {
    "success": "Login Successful",
    "api_token": "d8f3b2049e71a5c68f9a2b0e4d7c18e3f",
    ...
  }
}
```

### Critical Backend Conventions
1. **Authentication:** The app does **NOT** use HTTP `Authorization: Bearer <token>` headers. Instead, authentication passes `"api_token": "<token>"` inside the JSON request payload under `params`.
2. **Odoo False-Type Handling:** Odoo returns boolean `false` when string or object fields are null/empty (e.g., `phone: false`, `profile: false`, `code: false`, `email: false`). All Dart model JSON parsers defensively evaluate `value is String ? value : ''`.
3. **HTTP 200 Error Handling:** Odoo returns HTTP status 200 even when an operation fails. All repositories inspect `result['error']` and display specific server error messages in UI SnackBars.

---

## 3. Project Directory Structure

```text
lib/
├── core/
│   ├── constants/
│   │   ├── app_assets.dart          # Local image/icon asset paths
│   │   ├── app_colors.dart          # #C6134B Burgundy primary, #06038D Navy, #FBF6F3 background
│   │   ├── app_strings.dart         # String constants & UI text
│   │   └── app_text_styles.dart     # Typography styles (Outfit font)
│   ├── services/
│   │   ├── api_service.dart         # Dio client, 60s timeouts, JSON-RPC wrapper, 15 API methods
│   │   ├── storage_service.dart     # SharedPreferences wrapper with 11 native DataStore keys
│   │   ├── location_service.dart    # High-accuracy Geolocator position capture
│   │   ├── notification_service.dart# FCM background handler & local notification channel
│   │   ├── auth_repository.dart     # Sign in, OTP verification, WhatsApp registration
│   │   └── attendance_repository.dart# Clock In/Out, Locations, Work Plan, Attendance List, Notifications
│   └── theme/
│       └── app_theme.dart           # App ThemeData configuration
│
├── data/
│   └── models/
│       ├── app_models.dart          # Barrel export for all data models
│       ├── company_models.dart      # CompanyItem & CompanyListResponse
│       ├── send_otp_response.dart   # SendOtpResponse with isStatus101 & isSuccess
│       ├── verify_otp_response.dart # VerifyOtpResponse with defensive Odoo parsing
│       ├── dashboard_data.dart      # DashboardData with toGridList() helper
│       ├── time_in_out_status.dart  # TimeInOutStatus (is_time_in & last_time_in_datetime)
│       ├── today_work_location.dart # TodayWorkLocation (area_id mapping)
│       ├── work_location_item.dart  # WorkLocationItem
│       ├── attendance_item.dart     # AttendanceItem with isApproved getter
│       ├── work_plan_item.dart      # WorkPlanItem shift roster model
│       └── notification_item.dart   # NotificationItem feed model
│
├── features/
│   ├── splash/                      # SplashScreen & AlSharqiLogo widget
│   ├── auth/                        # SignInScreen & VerificationScreen
│   ├── dashboard/                   # DashboardScreen & AppDrawer navigation shell
│   ├── home/                        # HomeScreen profile card container
│   ├── attendance/                  # RecordTimeInScreen, RecordTimeOutScreen, AttendanceListScreen, WorkPlanScreen
│   ├── notifications/               # NotificationsScreen & NotificationDetailScreen
│   └── self_service/                # SelfServicePortalScreen, Leave, Complaint, Bright Idea, Employee Request forms
│
├── routes/
│   └── app_routes.dart              # Named route definitions & route generator map
└── main.dart                        # App entry point initializing StorageService & Firebase
```

---

## 4. Master API Catalog

| # | Endpoint Route | HTTP Method | Request Payload (`params`) | Expected Response (`result`) | Used By Screen |
| :--- | :--- | :--- | :--- | :--- | :--- |
| 1 | `company/list` | POST | `""` | `[{id, name}]` | `SignInScreen` |
| 2 | `attendance/sign/in` | POST | `employee_number`, `company_id` | `{success, register_mobile, status, error}` | `SignInScreen`, `VerificationScreen` |
| 3 | `attendance/add/whatsapp_number` | POST | `employee_number`, `company_id`, `whatsapp_number` | `{success, register_mobile}` | `AddMobileScreen` |
| 4 | `attendance/otp/verify` | POST | `employee_number`, `company_id`, `otp`, `device_token`, `device_type`, `device_info` | `{api_token, employee_id, name, emp_no, profile, phone, whatsapp_phone, ...}` | `VerificationScreen` |
| 5 | `attendance/dashboard` | POST | `employee_number`, `company_id`, `api_token` | `{company, join_date, qid_number, passport_number, gender, nationality, work_location, location, manager}` | `DashboardScreen` |
| 6 | `attendance/check_time_in_out` | POST | `employee_number`, `company_id`, `api_token` | `{is_time_in, last_time_in_datetime}` | `RecordTimeInScreen`, `RecordTimeOutScreen` |
| 7 | `plan/location/today` | POST | `employee_number`, `company_id`, `api_token` | `{area_id: {id, name}}` | `RecordTimeInScreen` |
| 8 | `location/update/list` | POST | `employee_number`, `company_id`, `api_token` | `[{id, name, code}]` | `RecordTimeInScreen` |
| 9 | `attendance/check/in` | POST | `employee_number`, `company_id`, `api_token`, `date`, `time_in`, `geo_location`, `lat`, `long`, `attendance_type` | `{success, id}` | `RecordTimeInScreen` |
| 10 | `attendance/check/in/secure` | POST | `employee_number`, `company_id`, `api_token`, `time_in`, `geo_location`, `lat`, `long`, `attendance_type` | `{success, id}` | `RecordTimeInScreen` |
| 11 | `attendance/update_area` | POST | `time_in_id`, `area_id` | `{success}` | `RecordTimeInScreen` |
| 12 | `attendance/check/out` | POST | `employee_number`, `company_id`, `api_token`, `date`, `time_out`, `geo_location`, `lat`, `long`, `note` | `{success_msg}` | `RecordTimeOutScreen` |
| 13 | `attendance/list` | POST | `employee_number`, `company_id`, `api_token`, `month_no`, `year` | `[{id, name, emp_no, date, s_time, e_time, work_hours, overtime_hours}]` | `AttendanceListScreen` |
| 14 | `employee/work_plan` | POST | `employee_number`, `company_id`, `api_token` | `{planes: [{employee, area, location, date, work_from, work_to, total_hours, overtime_hours}]}` | `WorkPlanScreen` |
| 15 | `notification/logs` | POST | `emp_no`, `company_id`, `api_token` | `{notification_logs: [{notification_id, subject, message, timestamp, attachment_url}]}` | `NotificationsScreen` |

---

## 5. Local Storage Keys Matrix

Managed via `StorageService` ([storage_service.dart](file:///C:/Users/Shaheer/Documents/GitHub/Sharqi-App/lib/core/services/storage_service.dart)):

| Key Constant | Storage Key String | Data Type | Purpose & Written By |
| :--- | :--- | :--- | :--- |
| `keyAccessToken` | `"ACCESS_TOKEN"` | String | Odoo `api_token` session token written on OTP verification success |
| `keyDeviceId` | `"DEVICE_ID"` | String | FCM device token written by `NotificationService` |
| `keyEmpId` | `"EMP_ID"` | Int | Odoo primary key `employee_id` |
| `keyCompanyId` | `"COMPANY_ID"` | String | Selected company ID |
| `keyEmpNo` | `"EMP_NO"` | String | Employee badge string (e.g., `"10091"`) |
| `keyFullName` | `"FULL_NAME"` | String | Employee full name |
| `keyEmail` | `"EMAIL"` | String | Employee email address |
| `keyPhone` | `"PHONE"` | String | Employee mobile phone number |
| `keyProfileImage` | `"PROFILE_IMAGE"` | String | Base64-encoded profile avatar string |
| `keyWhatsAppPhone` | `"WHATS_APP_PHONE"` | String | Employee registered WhatsApp number |
| `keyCompanyName` | `"COMPANY_NAME"` | String | Selected company display name |

---

## 6. Business Logic & Policy Rules

### 1. Attendance Check-In Duplication Guard
* On opening `RecordTimeInScreen`, calls `attendance/check_time_in_out`.
* If `is_time_in == true`, presents an alert dialog (*"You have already recorded Time-In for today."*) and disables the Time-In button.

### 2. Attendance Check-Out Prerequisite Guard
* On opening `RecordTimeOutScreen`, calls `attendance/check_time_in_out`.
* If `is_time_in == false`, presents an alert dialog (*"You have not done Check-In yet today."*) and disables the Time-Out button.

### 3. 2-Hour Early Checkout Justification Rule
* Calculates `timeElapsed = DateTime.now().difference(_lastTimeInDatetime)`.
* If `timeElapsed.inMinutes <= 120` (<= 2 hours worked since check-in):
  * Displays mandatory justification dialog: *"You are making checkout before 2 Hours. Please specify a reason:"*
  * Requires non-empty reason text string. Aborts checkout if empty or cancelled.
  * Attaches reason string to `note` parameter in `attendance/check/out`.
* If `timeElapsed.inMinutes > 120`: sets `note = ""`.

### 4. Work Location Reassignment on Check-In
* On check-in success, extracts created attendance record `time_in_id`.
* If the user selected a location ID different from today's assigned area ID (`selectedId != _todayWorkLocation.id`), automatically dispatches `POST attendance/update_area` with `time_in_id` and `area_id`.

### 5. Unregistered WhatsApp Mobile (Status 101)
* When submitting employee badge number in `SignInScreen`, if Odoo returns `status == "101"`, displays error prompt directing user to register an 8-digit WhatsApp number via `POST attendance/add/whatsapp_number`.

### 6. Overtime Approval Metric
* In `AttendanceListScreen`, an attendance record displays `Approved = "Yes"` if `overtime_hours > 0`, otherwise `"No"`.

---

## 7. Quality Assurance & Verification

* **Static Code Analysis:** `flutter analyze` completed with **0 errors and 0 warnings**.
* **Automated Test Suite:** `flutter test` executed **10/10 passing unit and model tests** in [attendance_test.dart](file:///C:/Users/Shaheer/Documents/GitHub/Sharqi-App/test/attendance_test.dart) and [widget_test.dart](file:///C:/Users/Shaheer/Documents/GitHub/Sharqi-App/test/widget_test.dart).
* **Data Origin Audit:** 100% of production data fields originate from live Odoo ERP APIs or authenticated device storage/GPS telemetry. No hardcoded or dummy business data exists in production code.
