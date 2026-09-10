import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  // 11 Native DataStore Keys
  static const String keyAccessToken = "ACCESS_TOKEN";
  static const String keyDeviceId = "DEVICE_ID";
  static const String keyEmpId = "EMP_ID";
  static const String keyCompanyId = "COMPANY_ID";
  static const String keyEmpNo = "EMP_NO";
  static const String keyFullName = "FULL_NAME";
  static const String keyEmail = "EMAIL";
  static const String keyPhone = "PHONE";
  static const String keyProfileImage = "PROFILE_IMAGE";
  static const String keyWhatsAppPhone = "WHATS_APP_PHONE";
  static const String keyWhatsAppData = "WHATS_APP_PHONE"; // Alias for backward compatibility
  static const String keyCompanyName = "COMPANY_NAME";
  static const String keyQid = "QID_NUMBER";
  static const String keyQidExpiry = "QID_EXPIRY";

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Future<void> addValue(String key, String value) async {
    await _prefs?.setString(key, value);
  }

  static Future<void> addInt(String key, int value) async {
    await _prefs?.setInt(key, value);
  }

  static Future<void> addBoolean(String key, bool value) async {
    await _prefs?.setBool(key, value);
  }

  static Future<void> addFloat(String key, double value) async {
    await _prefs?.setDouble(key, value);
  }

  static Future<void> addLong(String key, int value) async {
    await _prefs?.setInt(key, value);
  }

  static String getValue(String key) {
    return _prefs?.getString(key) ?? "";
  }

  static int getInt(String key) {
    try {
      return _prefs?.getInt(key) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  static bool getBoolean(String key, {bool defaultValue = false}) {
    try {
      return _prefs?.getBool(key) ?? defaultValue;
    } catch (_) {
      return defaultValue;
    }
  }

  static double getFloat(String key) {
    try {
      return _prefs?.getDouble(key) ?? 0.0;
    } catch (_) {
      return 0.0;
    }
  }

  static int getLong(String key) {
    try {
      return _prefs?.getInt(key) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  static Future<void> putObject(String key, dynamic obj) async {
    final jsonString = jsonEncode(obj);
    await addValue(key, jsonString);
  }

  static T? getObject<T>(String key, T Function(Map<String, dynamic> json) fromJson) {
    final jsonString = getValue(key);
    if (jsonString.isEmpty) return null;
    try {
      final map = jsonDecode(jsonString) as Map<String, dynamic>;
      return fromJson(map);
    } catch (_) {
      return null;
    }
  }

  static Future<void> removeValue(String key) async {
    await _prefs?.remove(key);
  }

  static Future<void> clear() async {
    await clearAll();
  }

  static Future<void> clearAll() async {
    await _prefs?.clear();
  }

  static Future<void> clearSharedPreference() async {
    await clearAll();
  }
}
