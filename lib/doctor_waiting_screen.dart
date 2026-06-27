import 'package:flutter/material.dart';
import 'firebase_service.dart';
import 'doctor_approved_screen.dart';
import 'doctor_rejected_screen.dart';
import 'session_manager.dart';

class DoctorWaitingScreen extends StatefulWidget {
  final String? doctorId;
  const DoctorWaitingScreen({super.key, this.doctorId});

  @override
  State<DoctorWaitingScreen> createState() => _DoctorWaitingScreenState();
}

class _DoctorWaitingScreenState extends State<DoctorWaitingScreen> {
  bool loading = false;

  Future<void> refreshStatus() async {
    if (widget.doctorId == null) return;
    setState(() => loading = true);
    try {
      final request = await FirebaseService.getDoctorRequestById(widget.doctorId!);
      if (!mounted) return;
      final status = request?['status']?.toString() ?? 'pending';

      final phone = request?['phone']?.toString() ?? '';
      if (status == 'approved') {
        if (phone.isNotEmpty) {
          await SessionManager.markDoctorStatusSeen(phone: phone, status: 'approved');
        }
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DoctorApprovedScreen(doctorId: widget.doctorId, phone: phone),
          ),
        );
      } else if (status == 'rejected') {
        if (phone.isNotEmpty) {
          await SessionManager.markDoctorStatusSeen(phone: phone, status: 'rejected');
        }
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DoctorRejectedScreen(
              reason: request?['rejectionReason']?.toString(),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('طلبك ما زال قيد المراجعة')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ أثناء تحديث حالة الطلب')),
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
          title: const Text('انتظار الموافقة', style: TextStyle(color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
                child: const Icon(Icons.hourglass_top, color: Colors.blue, size: 62),
              ),
              const SizedBox(height: 24),
              const Text('طلبك قيد المراجعة', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(
                'سيتم مراجعة بياناتك ومرفقاتك خلال يوم إلى يومين. بعد القبول يمكنك الدخول إلى التطبيق.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, height: 1.7, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 35),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: const Row(
                  children: [
                    Icon(Icons.verified_user, color: Colors.green),
                    SizedBox(width: 12),
                    Expanded(child: Text('سيتم تفعيل حساب الطبيب بعد موافقة الإدارة فقط.')),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: loading ? null : refreshStatus,
                  child: loading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text(
                          'تحديث حالة الطلب',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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
