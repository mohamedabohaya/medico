import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hospital/registration_screen.dart';

import 'firebase_service.dart';
import 'doctor_register_screen.dart';
import 'otp_screen.dart';
import 'doctor_waiting_screen.dart';
import 'doctor_approved_screen.dart';
import 'doctor_rejected_screen.dart';
import 'doctor_dashboard_screen.dart';
import 'doctor_profile_setup_screen.dart';
import 'session_manager.dart';

class PhoneScreen extends StatefulWidget {
  final bool? fromDoctor;
  const PhoneScreen({this.fromDoctor,super.key});

  @override
  State<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends State<PhoneScreen> {
  TextEditingController phoneController = TextEditingController();
  void checkUser() async {
    final phone = FirebaseService.normalizePhone(phoneController.text.trim());

    if (!FirebaseService.isValidLocalPhone(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            FirebaseService.localPhoneErrorText(),
            textAlign: TextAlign.center,style: TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        ),
      );
      return;
    }

    if (widget.fromDoctor == true) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OTPScreen(phone: phone, fromDoctor: true),
        ),
      );
      return;
    }

    final result = await FirebaseService.getUserByPhone(phone);
    final userExists = result != null;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OTPScreen(
          phone: phone,
          newPatient: !userExists,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [

              const SizedBox(height: 30),

              /// 🔵 عنوان
              const Text(
                "انشئ حساب أو سجل دخول",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              /// 📝 وصف
              const Text(
                "سنرسل لك رمز تحقق لتأكيد رقمك",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 30),

              /// 📦 كرت الإدخال
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [

                    const Icon(Icons.phone_android, color: Colors.blue),
                    const SizedBox(width: 10),

                    /// 📱 رقم الجوال
                    Expanded(
                      child: TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        decoration: const InputDecoration(
                          hintText: "05xxxxxxxx",
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              /// 🔘 زر المتابعة
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: checkUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child:  Text(
                    "متابعة",
                    style: TextStyle(fontSize: 16,color: Colors.white,fontWeight: FontWeight.w700),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}