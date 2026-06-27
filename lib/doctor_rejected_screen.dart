import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'session_manager.dart';

class DoctorRejectedScreen extends StatelessWidget {
  final String? reason;
  const DoctorRejectedScreen({super.key, this.reason});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          backgroundColor: Colors.red,
          centerTitle: true,
          automaticallyImplyLeading: false,
          title: const Text(
            'تم رفض الطلب',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 125,
                height: 125,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cancel,
                  color: Colors.red,
                  size: 75,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'عذراً، تم رفض طلب تسجيلك كطبيب',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                reason == null || reason!.trim().isEmpty
                    ? 'يمكنك مراجعة البيانات أو التواصل مع إدارة التطبيق ثم المحاولة مرة أخرى.'
                    : reason!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.7,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 34),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () async {
                    await SessionManager.logoutDoctor();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const PhoneScreen(fromDoctor: true)),
                      (route) => false,
                    );
                  },
                  child: const Text(
                    'الرجوع إلى تسجيل الدخول',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
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
