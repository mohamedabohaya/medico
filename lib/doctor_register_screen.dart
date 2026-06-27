import 'dart:convert';
import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'doctor_waiting_screen.dart';
import 'firebase_service.dart';
import 'session_manager.dart';
import 'app_image_helper.dart';

class DoctorRegisterScreen extends StatefulWidget {
  final String? phone;
  const DoctorRegisterScreen({super.key, this.phone});

  @override
  State<DoctorRegisterScreen> createState() => _DoctorRegisterScreenState();
}

class _DoctorRegisterScreenState extends State<DoctorRegisterScreen> {
  final formKey = GlobalKey<FormState>();
  final fullName = TextEditingController();
  final nationalId = TextEditingController();
  final email = TextEditingController();
  final birthDate = TextEditingController();
  final specialty = TextEditingController();
  final university = TextEditingController();
  final graduationYear = TextEditingController();
  final licenseNo = TextEditingController();
  final experienceYears = TextEditingController();
  final currentWork = TextEditingController();
  String gender = 'ذكر';
  bool loading = false;

  Map<String, String> uploadedFiles = {};

  final Map<String, String> attachmentKeys = const {
    'الصورة الشخصية': 'personalPhoto',
    'صورة الهوية / جواز السفر': 'idOrPassport',
    'شهادة التخرج': 'graduationCertificate',
    'رخصة مزاولة المهنة': 'practiceLicense',
    'شهادات الخبرة إن وجدت': 'experienceCertificates',
  };

  Map<String, String> get safeAttachments {
    return uploadedFiles.map((label, value) {
      final key = attachmentKeys[label] ?? label.replaceAll(RegExp(r'[./~*\[\]]'), '_');
      return MapEntry(key, value);
    });
  }


  Future<String?> pickImageAsDataUrl() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 45,
      maxWidth: 900,
    );
    if (picked == null) return null;
    final bytes = await File(picked.path).readAsBytes();
    if (bytes.length > 700 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الصورة كبيرة جداً، اختر صورة أصغر')),
        );
      }
      return null;
    }
    final ext = picked.path.split('.').last.toLowerCase();
    final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
    return 'data:$mime;base64,${base64Encode(bytes)}';
  }

  Future<void> pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
      firstDate: DateTime(1940),
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
      birthDate.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => loading = true);
    try {
      final requestId = await FirebaseService.saveDoctorRequest({
        'fullName': fullName.text.trim(),
        'nationalId': nationalId.text.trim(),
        'email': email.text.trim(),
        'birthDate': birthDate.text.trim(),
        'gender': gender,
        'mainSpecialty': specialty.text.trim(),
        'university': university.text.trim(),
        'graduationYear': graduationYear.text.trim(),
        'licenseNo': licenseNo.text.trim(),
        'experienceYears': experienceYears.text.trim(),
        'currentWork': currentWork.text.trim(),
        'attachments': safeAttachments,
        'attachmentLabels': uploadedFiles.keys.toList(),
        'personalImage': uploadedFiles['الصورة الشخصية'] ?? '',
        'phone': widget.phone ?? '',
      });
      await SessionManager.saveDoctorLogin(
        phone: widget.phone ?? '',
        doctorRequestId: requestId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال الطلب بنجاح')));
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => DoctorWaitingScreen(doctorId: requestId)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ في الحفظ: $e')));
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
        appBar: AppBar(backgroundColor: Colors.white, elevation: 0, centerTitle: true, iconTheme: const IconThemeData(color: Colors.black), title: const Text('التسجيل كطبيب', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
        body: Form(
          key: formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              sectionCard(title: 'البيانات الشخصية', children: [
                customField('الاسم الرباعي', fullName),
                customField('رقم الهوية / جواز السفر', nationalId),
                customField('البريد الإلكتروني', email, keyboardType: TextInputType.emailAddress),
                customField('تاريخ الميلاد', birthDate, readOnly: true, onTap: pickBirthDate),
                genderSection(),
              ]),
              const SizedBox(height: 18),
              sectionCard(title: 'البيانات المهنية', children: [
                customField('التخصص الطبي', specialty),
                customField('اسم الجامعة', university),
                customField('سنة التخرج', graduationYear, keyboardType: TextInputType.number),
                customField('رقم الترخيص الطبي', licenseNo,keyboardType: TextInputType.number),
                customField('عدد سنوات الخبرة', experienceYears, keyboardType: TextInputType.number),
                customField('جهة العمل الحالية / المستشفى', currentWork),
              ]),
              const SizedBox(height: 18),
              requiredFilesSection(),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  onPressed: loading ? null : submit,
                  child: loading ? const CircularProgressIndicator(color: Colors.white) : const Text('إرسال الطلب', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget sectionCard({required String title, required List<Widget> children}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 18), ...children]),
      );

  Widget customField(String hint, TextEditingController controller, {TextInputType? keyboardType, bool readOnly = false, VoidCallback? onTap}) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly,
          onTap: onTap,
          validator: (v) => (v == null || v.trim().isEmpty) ? 'هذا الحقل مطلوب' : null,
          decoration: InputDecoration(hintText: hint, filled: true, fillColor: Colors.grey.shade50, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)), focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.blue))),
        ),
      );

  Widget genderSection() => Row(children: [Expanded(child: genderButton('ذكر')), const SizedBox(width: 10), Expanded(child: genderButton('أنثى'))]);

  Widget genderButton(String title) {
    final selected = gender == title;
    return GestureDetector(
      onTap: () => setState(() => gender = title),
      child: Container(height: 50, decoration: BoxDecoration(color: selected ? Colors.blue.shade50 : Colors.grey.shade100, borderRadius: BorderRadius.circular(14), border: Border.all(color: selected ? Colors.blue : Colors.transparent)), child: Center(child: Text(title, style: TextStyle(color: selected ? Colors.blue : Colors.black, fontWeight: FontWeight.bold)))),
    );
  }

  Widget requiredFilesSection() => sectionCard(title: 'المرفقات المطلوبة', children: [
        fileItem('الصورة الشخصية'),
        fileItem('صورة الهوية / جواز السفر'),
        fileItem('شهادة التخرج'),
        fileItem('رخصة مزاولة المهنة'),
        fileItem('شهادات الخبرة إن وجدت'),
      ]);

  Widget fileItem(String title) {
    final value = uploadedFiles[title] ?? '';
    final hasImage = value.isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade300)),
      child: Row(children: [
        if (hasImage)
          GestureDetector(
            onTap: () => AppImageHelper.showPreview(context, value),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(width: 45, height: 45, child: AppImageHelper.image(value, fit: BoxFit.cover)),
            ),
          )
        else
          const Icon(Icons.image, color: Colors.blue),
        const SizedBox(width: 10),
        Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600))),
        Text(hasImage ? 'تم الرفع' : 'لم يتم الرفع', style: TextStyle(color: hasImage ? Colors.green : Colors.grey)),
        IconButton(
          icon: const Icon(Icons.upload_file, color: Colors.blue),
          onPressed: () async {
            final image = await pickImageAsDataUrl();
            if (image != null) setState(() => uploadedFiles[title] = image);
          },
        ),
      ]),
    );
  }
}

