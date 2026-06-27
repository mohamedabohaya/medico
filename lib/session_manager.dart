import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const String _phoneKey = 'logged_in_phone';
  static const String _doctorPhoneKey = 'logged_in_doctor_phone';
  static const String _doctorRequestIdKey = 'logged_in_doctor_request_id';
  static const String _doctorStatusSeenPrefix = 'doctor_status_seen_';

  static String _safeKeyPart(String value) =>
      value.replaceAll(RegExp(r'[^0-9a-zA-Z_]+'), '_');

  static Future<void> saveLogin(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_phoneKey, phone);
    // عند دخول المريض نمسح أي جلسة طبيب قديمة حتى لا يحصل تعارض.
    await prefs.remove(_doctorPhoneKey);
    await prefs.remove(_doctorRequestIdKey);
  }

  static Future<String?> getLoggedInPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_phoneKey);
  }

  static Future<void> saveDoctorLogin({required String phone, String? doctorRequestId}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_doctorPhoneKey, phone);
    if (doctorRequestId != null && doctorRequestId.isNotEmpty) {
      await prefs.setString(_doctorRequestIdKey, doctorRequestId);
    }
    // عند دخول الطبيب نمسح جلسة المريض القديمة حتى لا يحصل تعارض.
    await prefs.remove(_phoneKey);
  }

  static Future<String?> getLoggedInDoctorPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_doctorPhoneKey);
  }

  static Future<String?> getLoggedInDoctorRequestId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_doctorRequestIdKey);
  }


  static Future<bool> hasSeenDoctorStatus({
    required String phone,
    required String status,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_doctorStatusSeenPrefix${_safeKeyPart(phone)}_${_safeKeyPart(status)}';
    return prefs.getBool(key) ?? false;
  }

  static Future<void> markDoctorStatusSeen({
    required String phone,
    required String status,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_doctorStatusSeenPrefix${_safeKeyPart(phone)}_${_safeKeyPart(status)}';
    await prefs.setBool(key, true);
  }

  static Future<void> logoutDoctor() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_doctorPhoneKey);
    await prefs.remove(_doctorRequestIdKey);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_phoneKey);
  }

  static Future<void> logoutAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_phoneKey);
    await prefs.remove(_doctorPhoneKey);
    await prefs.remove(_doctorRequestIdKey);
  }
}
