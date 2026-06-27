import 'package:flutter/material.dart';
import 'firebase_service.dart';
import 'session_manager.dart';

class AskDoctorScreen extends StatefulWidget {
  const AskDoctorScreen({super.key});

  @override
  State<AskDoctorScreen> createState() => _AskDoctorScreenState();
}

class _AskDoctorScreenState extends State<AskDoctorScreen> {
  String selectedSpecialty = "اختر التخصص";
  String questionType = "لنفسي";
  String gender = "ذكر";
  bool loading = false;

  TextEditingController title = TextEditingController();
  TextEditingController description = TextEditingController();
  TextEditingController age = TextEditingController();

  final specialties = [
    'جلدية',
    'أسنان',
    'نفسي',
    'أطفال',
    'مخ وأعصاب',
    'عظام',
    'نساء وولادة',
    'أنف وأذن وحنجرة',
    'قلب وأوعية دموية',
    'باطنة',
  ];

  Future<void> submit() async {
    if (selectedSpecialty == "اختر التخصص" ||
        title.text.trim().isEmpty ||
        description.text.trim().isEmpty ||
        age.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("يرجى تعبئة جميع الحقول واختيار التخصص"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => loading = true);
    final patientPhone = await SessionManager.getLoggedInPhone() ?? '';
    final patient = patientPhone.isEmpty ? null : await FirebaseService.getUserByPhone(patientPhone);

    await FirebaseService.addQuestion({
      'specialty': selectedSpecialty,
      'title': title.text.trim(),
      'question': title.text.trim(),
      'description': description.text.trim(),
      'text': description.text.trim(),
      'age': age.text.trim(),
      'questionType': questionType,
      'gender': gender,
      'patientPhone': FirebaseService.normalizePhone(patientPhone),
      'patientName': patient?['name'] ?? 'مريض',
    });

    if (!mounted) return;
    setState(() => loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("تم إرسال السؤال للطبيب")),
    );
    Navigator.pop(context);
  }

  @override
  void dispose() {
    title.dispose();
    description.dispose();
    age.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text("اسأل دكتور", style: TextStyle(color: Colors.black)),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              fieldLabel("اختر التخصص"),
              containerBox(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedSpecialty,
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem(value: "اختر التخصص", child: Text("اختر التخصص")),
                      ...specialties.map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    ],
                    onChanged: (value) => setState(() => selectedSpecialty = value!),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              fieldLabel("الجنس"),
              Row(
                children: [
                  chip("ذكر", gender, (v) => setState(() => gender = v)),
                  chip("أنثى", gender, (v) => setState(() => gender = v)),
                ],
              ),
              const SizedBox(height: 15),
              fieldLabel("سؤالك"),
              inputField(controller: title, hint: "اكتب عنوان السؤال"),
              const SizedBox(height: 15),
              fieldLabel("وصف الحالة"),
              inputField(controller: description, hint: "اشرح الأعراض...", maxLines: 4),
              const SizedBox(height: 20),
              fieldLabel("العمر"),
              inputField(controller: age, hint: "مثال: 21", keyboard: TextInputType.number),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: loading ? null : submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: loading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("إرسال", style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget inputField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType keyboard = TextInputType.text,
  }) {
    return containerBox(
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboard,
        decoration: InputDecoration(hintText: hint, border: InputBorder.none),
      ),
    );
  }

  Widget containerBox({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: child,
    );
  }

  Widget chip(String text, String selected, Function(String) onTap) {
    bool isSelected = text == selected;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(text),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.shade100 : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? Colors.blue : Colors.grey.shade300),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: isSelected ? Colors.blue : Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
