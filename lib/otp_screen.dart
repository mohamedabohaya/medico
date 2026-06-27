import 'package:flutter/material.dart';
import 'package:hospital/home_screen.dart';
import 'main.dart';
import 'navigation.dart';
import 'session_manager.dart';
import 'registration_screen.dart';
import 'firebase_service.dart';
import 'doctor_register_screen.dart';
import 'doctor_waiting_screen.dart';
import 'doctor_approved_screen.dart';
import 'doctor_rejected_screen.dart';
import 'doctor_dashboard_screen.dart';
import 'doctor_profile_setup_screen.dart';

class OTPScreen extends StatefulWidget {
  final String phone;
  final bool fromDoctor;
  final bool newPatient;

  const OTPScreen({
    super.key,
    required this.phone,
    this.fromDoctor = false,
    this.newPatient = false,
  });

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {

  final List<TextEditingController> controllers =
  List.generate(4, (_) => TextEditingController());

  final List<FocusNode> focusNodes =
  List.generate(4, (_) => FocusNode());

  /// 🔴 SnackBar
  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      ),
    );
  }

  /// 🔐 تحقق
  void verify() async {
    String code = controllers.map((e) => e.text).join();

    if (code.length < 4) {
      showError("أدخل الكود كامل");
      return;
    }

    if (code != "1234") {
      showError("الكود غير صحيح");
      return;
    }

    if (widget.fromDoctor) {
      final doctorRequest = await FirebaseService.getDoctorRequestByPhone(widget.phone);
      if (doctorRequest == null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => DoctorRegisterScreen(phone: widget.phone)),
        );
        return;
      }

      final requestId = doctorRequest['id']?.toString();
      final status = doctorRequest['status']?.toString() ?? 'pending';
      await SessionManager.saveDoctorLogin(phone: widget.phone, doctorRequestId: requestId);

      if (status == 'approved') {
        final profile = await FirebaseService.getDoctorProfile(doctorRequestId: requestId, phone: widget.phone);
        if (profile != null) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => DoctorDashboardScreen(doctorRequestId: requestId, phone: widget.phone)),
            (route) => false,
          );
        } else {
          final seenApproved = await SessionManager.hasSeenDoctorStatus(phone: widget.phone, status: 'approved');
          if (seenApproved) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => DoctorProfileSetupScreen(doctorRequestId: requestId, phone: widget.phone)),
              (route) => false,
            );
          } else {
            await SessionManager.markDoctorStatusSeen(phone: widget.phone, status: 'approved');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => DoctorApprovedScreen(doctorId: requestId, phone: widget.phone)),
            );
          }
        }
      } else if (status == 'rejected') {
        final seenRejected = await SessionManager.hasSeenDoctorStatus(phone: widget.phone, status: 'rejected');
        if (!seenRejected) {
          await SessionManager.markDoctorStatusSeen(phone: widget.phone, status: 'rejected');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => DoctorRejectedScreen(reason: doctorRequest['rejectionReason']?.toString())),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => DoctorRejectedScreen(reason: doctorRequest['rejectionReason']?.toString())),
          );
        }
      } else {
        await SessionManager.markDoctorStatusSeen(phone: widget.phone, status: 'pending');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => DoctorWaitingScreen(doctorId: requestId)),
        );
      }
      return;
    }

    if (widget.newPatient) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => RegisterScreen(phone: widget.phone)),
      );
      return;
    }

    await SessionManager.saveLogin(widget.phone);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainNavigation()),
      (route) => false,
    );
  }

  /// 🧱 مربع OTP
  Widget otpBox(int index) {
    return Container(
      width: 60,
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.grey.shade100,
      ),
      child: Center(
        child: TextField(
          controller: controllers[index],
          focusNode: focusNodes[index],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          decoration: const InputDecoration(
            counterText: "",
            border: InputBorder.none,
          ),
          onChanged: (value) {
            if (value.isNotEmpty) {
              if (index < 3) {
                FocusScope.of(context)
                    .requestFocus(focusNodes[index + 1]);
              }
            } else {
              if (index > 0) {
                FocusScope.of(context)
                    .requestFocus(focusNodes[index - 1]);
              }
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                const SizedBox(height: 30),

                /// 🟦 Title
                const Text(
                  "تأكيد الكود",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    const Text("أدخل الكود المرسل إلى ", style: TextStyle(color: Colors.grey)),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text('0${widget.phone}', style: const TextStyle(color: Colors.grey)),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                /// 🔢 OTP Boxes
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      otpBox(0),
                      otpBox(1),
                      otpBox(2),
                      otpBox(3),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                /// 🔄 إعادة إرسال
                Center(
                  child: TextButton(
                    onPressed: () {
                      showError("تم إعادة إرسال الكود");
                    },
                    child: const Text("إعادة إرسال الكود"),
                  ),
                ),

                const Spacer(),

                /// 🔘 زر التأكيد
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: verify,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      "تأكيد",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}