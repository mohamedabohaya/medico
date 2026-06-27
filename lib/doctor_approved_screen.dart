import 'package:flutter/material.dart';
import 'doctor_dashboard_screen.dart';
import 'doctor_profile_setup_screen.dart';
import 'firebase_service.dart';
import 'session_manager.dart';

class DoctorApprovedScreen extends StatefulWidget {
  final String? doctorId;
  final String? phone;

  const DoctorApprovedScreen({super.key, this.doctorId, this.phone});

  @override
  State<DoctorApprovedScreen> createState() => _DoctorApprovedScreenState();
}

class _DoctorApprovedScreenState extends State<DoctorApprovedScreen> {
  bool loading = false;

  Future<void> goNext() async {
    setState(() => loading = true);
    try {
      if ((widget.phone ?? '').isNotEmpty) {
        await SessionManager.saveDoctorLogin(
          phone: widget.phone!,
          doctorRequestId: widget.doctorId,
        );
        await SessionManager.markDoctorStatusSeen(
          phone: widget.phone!,
          status: 'approved',
        );
      }
      final profile = await FirebaseService.getDoctorProfile(
        doctorRequestId: widget.doctorId,
        phone: widget.phone,
      );

      if (!mounted) return;

      if (profile == null) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => DoctorProfileSetupScreen(
              doctorRequestId: widget.doctorId,
              phone: widget.phone,
            ),
          ),
          (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => DoctorDashboardScreen(
              doctorRequestId: widget.doctorId,
              phone: widget.phone,
            ),
          ),
          (route) => false,
        );
      }
    } catch (_) {
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => DoctorProfileSetupScreen(
            doctorRequestId: widget.doctorId,
            phone: widget.phone,
          ),
        ),
        (route) => false,
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          backgroundColor: Colors.blue,
          centerTitle: true,
          automaticallyImplyLeading: false,
          title: const Text(
            'تم قبولك',
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
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 75,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'تم قبول طلبك بنجاح',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'أكمل بيانات عيادتك وخدماتك أول مرة، وبعدها ستدخل مباشرة إلى لوحة الطبيب.',
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
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: loading ? null : goNext,
                  child: loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'متابعة',
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
