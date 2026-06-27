import 'package:flutter/material.dart';
import 'db_helper.dart';
import 'otp_screen.dart';
import 'firebase_service.dart';
import 'session_manager.dart';
import 'navigation.dart';

class RegisterScreen extends StatefulWidget {
  final String phone;
  const RegisterScreen({super.key, required this.phone});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  TextEditingController name = TextEditingController();
  TextEditingController email = TextEditingController();
  TextEditingController date = TextEditingController();

  String gender = "Male";

  /// 🔴 SnackBar موحد
  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      ),
    );
  }

  /// 📧 تحقق من الإيميل
  bool isValidEmail(String email) {
    return RegExp(
      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
    ).hasMatch(email);
  }

  /// 📅 اختيار التاريخ
  Future<void> pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          dialogBackgroundColor: Colors.white,
          colorScheme: Theme.of(context).colorScheme.copyWith(surface: Colors.white),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      date.text = "${picked.year}-${picked.month}-${picked.day}";
    }
  }

  /// 🧠 تسجيل المستخدم
  void register() async {
    String userName = name.text.trim();
    String userEmail = email.text.trim();
    String userDate = date.text.trim();

    /// ❌ تحقق من الفراغ
    if (userName.isEmpty || userEmail.isEmpty || userDate.isEmpty) {
      showError("يرجى إكمال جميع البيانات");
      return;
    }

    /// ❌ تحقق من الإيميل
    if (!isValidEmail(userEmail)) {
      showError("البريد الإلكتروني غير صحيح");
      return;
    }

    final phoneExists = await FirebaseService.phoneExists(widget.phone);
    if (phoneExists) {
      showError("رقم الجوال مسجل مسبقاً");
      return;
    }

    final emailExists = await FirebaseService.emailExists(userEmail);
    if (emailExists) {
      showError("البريد الإلكتروني مسجل مسبقاً");
      return;
    }

    /// ✅ إدخال البيانات
    await FirebaseService.savePatient({

      "name": userName,
      "email": userEmail,
      "phone": widget.phone,
      "gender": gender,
      "birthdate": userDate,
    });

    /// 🔁 انتقال بعد إنشاء الحساب
    await SessionManager.saveLogin(widget.phone);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const MainNavigation(),
      ),
      (route) => false,
    );
  }

  /// 🧱 Field UI
  Widget buildField({
    required String hint,
    required TextEditingController controller,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        textDirection: controller.text.trim().startsWith('+') ? TextDirection.ltr : TextDirection.rtl,
        textAlign: controller.text.trim().startsWith('+') ? TextAlign.left : TextAlign.right,
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
        ),
      ),
    );
  }

  /// 🏷️ Label
  Widget fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        textAlign: TextAlign.right,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }

  /// 🚻 Gender
  Widget genderChip(String value) {
    bool isSelected = gender == value;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => gender = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          margin: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.shade700 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.grey.shade300,
            ),
          ),
          child: Center(
            child: Text(
              value == "Male" ? "ذكر" : "أنثى",
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
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

                const Text(
                  "إنشاء حساب",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  "أدخل بياناتك للمتابعة",
                  style: TextStyle(color: Colors.grey),
                ),

                const SizedBox(height: 30),

                /// 📱 رقم الجوال
                fieldLabel("رقم الجوال"),
                buildField(
                  hint: FirebaseService.formatPhoneForDisplay(widget.phone),
                  controller: TextEditingController(text: FirebaseService.formatPhoneForDisplay(widget.phone)),
                  readOnly: true,
                ),

                /// 👤 الاسم
                fieldLabel("الاسم الكامل"),
                buildField(
                  hint: "اكتب اسمك",
                  controller: name,
                ),

                /// 📧 البريد
                fieldLabel("البريد الإلكتروني"),
                buildField(
                  hint: "example@email.com",
                  controller: email,
                ),

                /// 🎂 التاريخ
                fieldLabel("تاريخ الميلاد"),
                buildField(
                  hint: "اختر التاريخ",
                  controller: date,
                  readOnly: true,
                  onTap: pickDate,
                ),

                const SizedBox(height: 10),

                /// 🚻 الجنس
                fieldLabel("الجنس"),

                Row(
                  children: [
                    genderChip("Male"),
                    genderChip("Female"),
                  ],
                ),

                const Spacer(),

                /// 🔘 زر التسجيل
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      "إنشاء الحساب",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
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