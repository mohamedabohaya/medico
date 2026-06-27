import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'booking_success_screen.dart';
import 'firebase_service.dart';
import 'session_manager.dart';
import 'app_image_helper.dart';

class PhoneConsultationPage extends StatefulWidget {
  final Map<String, dynamic> doctor;
  final Map<String, String> selectedTime;

  const PhoneConsultationPage({
    super.key,
    required this.doctor,
    required this.selectedTime,
  });

  @override
  State<PhoneConsultationPage> createState() => _PhoneConsultationPageState();
}

class _PhoneConsultationPageState extends State<PhoneConsultationPage> {
  int currentStep = 0;
  bool loading = false;
  Map<String, dynamic>? patientData;

  String? callType;
  String? paymentMethod;
  String? paymentAttachmentUrl;
  String? paymentAttachmentType;

  final nameController = TextEditingController(text: 'عمار أسامة');
  final phoneController = TextEditingController();
  final ageController = TextEditingController();
  final symptomsController = TextEditingController();

  String? gender;

  @override
  void initState() {
    super.initState();
    loadPatientData();
  }

  Future<void> loadPatientData() async {
    final savedPhone = await SessionManager.getLoggedInPhone();
    if (savedPhone == null || savedPhone.isEmpty) return;
    final user = await FirebaseService.getUserByPhone(savedPhone);
    if (!mounted) return;
    setState(() {
      patientData = user;
      phoneController.text = FirebaseService.formatPhoneForDisplay(savedPhone);
      if (user != null && (user['name'] ?? '').toString().isNotEmpty) {
        nameController.text = user['name'].toString();
      }
      final g = user?['gender']?.toString();
      if (g == 'Male') gender = 'ذكر';
      if (g == 'Female') gender = 'أنثى';
      final age = calcAge(user?['birthdate'] ?? user?['birthDate']);
      if (age.isNotEmpty && ageController.text.trim().isEmpty) ageController.text = age;
    });
  }


  String get doctorId => (widget.doctor['id'] ?? widget.doctor['doctorId'] ?? '').toString();
  String get doctorName => (widget.doctor['name'] ?? widget.doctor['fullName'] ?? 'دكتور').toString();
  String get specialty => (widget.doctor['mainSpecialty'] ?? 'تخصص عام').toString();
  String get doctorImage => (widget.doctor['personalImage'] ?? '').toString();
  String get price => FirebaseService.servicePrice(widget.doctor, 'phone');
  String get bankPalestineNumber => (widget.doctor['bankPalestineNumber'] ?? 'لم يحدد').toString();
  String get jawwalPayNumber => (widget.doctor['jawwalPayNumber'] ?? 'لم يحدد').toString();

  String get selectedTimeText {
    return FirebaseService.timeStringForSelectedTime(widget.selectedTime);
  }

  String get appointmentDate => FirebaseService.dateStringForSelectedTime(widget.selectedTime);

  String calcAge(dynamic birthdate) {
    try {
      final d = DateTime.parse(birthdate.toString());
      final now = DateTime.now();
      var age = now.year - d.year;
      if (now.month < d.month || (now.month == d.month && now.day < d.day)) age--;
      return age.toString();
    } catch (_) {
      return '';
    }
  }


  void nextStep() {
    setState(() {
      if (currentStep < 3) currentStep++;
    });
  }

  void previousStep() {
    setState(() {
      if (currentStep > 0) currentStep--;
    });
  }

  Future<void> confirmPhoneBooking() async {
    if (!FirebaseService.isValidLocalPhone(phoneController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(FirebaseService.localPhoneErrorText())),
      );
      return;
    }

    if (paymentAttachmentUrl == null || paymentAttachmentUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يجب إرفاق صورة التحويل قبل تأكيد الحجز')));
      return;
    }
    setState(() => loading = true);

    await FirebaseService.createBooking({
      'doctorId': doctorId,
      'doctorName': doctorName,
      'doctorSpecialty': specialty,
      'doctorImage': doctorImage,
      'patientName': nameController.text.trim(),
      'patientPhone': FirebaseService.normalizePhone(phoneController.text.trim()),
      'serviceType': 'phone',
      'serviceTitle': 'مكالمة هاتفية',
      'callType': callType ?? 'phone',
      'date': selectedTimeText,
      'appointmentDate': appointmentDate,
      'appointmentDay': widget.selectedTime['day'] ?? '',
      'appointmentFrom': widget.selectedTime['from'] ?? '',
      'appointmentTo': widget.selectedTime['to'] ?? '',
      'selectedTime': {...widget.selectedTime, 'date': appointmentDate},
      'location': 'مكالمة هاتفية',
      'paymentAttachment': paymentAttachmentUrl ?? '',
      'paymentAttachmentType': paymentAttachmentType ?? '',
      'price': price,
      'finalAmount': '$price شيكل',
      'patientAge': ageController.text.trim(),
      'patientGender': gender ?? '',
      'symptoms': symptomsController.text.trim(),
    });

    if (!mounted) return;
    setState(() => loading = false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => BookingSuccessScreen(
          doctor: widget.doctor,
          serviceType: 'phone',
          selectedTime: {...widget.selectedTime, 'date': appointmentDate},
          location: 'مكالمة هاتفية',
          finalAmount: '$price شيكل',
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    ageController.dispose();
    symptomsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          title: const Text('تأكيد مكالمة دكتور'),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Column(
            children: [
              buildDoctorHeader(),
              buildStepsBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: buildCurrentStep(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildDoctorHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.blue.shade100,
            backgroundImage: AppImageHelper.provider(doctorImage),
            child: AppImageHelper.provider(doctorImage) == null ? const Icon(Icons.person, color: Colors.blue, size: 34) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(doctorName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text(
                specialty,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text('السعر: $price شيكل', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget buildStepsBar() {
    final steps = ['نوع المكالمة', 'التفاصيل', 'الأعراض', 'الدفع'];

    return Column(
      children: [
        LinearProgressIndicator(
          value: (currentStep + 1) / steps.length,
          backgroundColor: Colors.grey.shade300,
          color: const Color(0xff0878D1),
          minHeight: 8,
        ),
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(steps.length, (index) {
              return InkWell(
                onTap: () => setState(() => currentStep = index),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  child: Text(
                    steps[index],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: currentStep == index ? const Color(0xff0878D1) : Colors.black54,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget buildCurrentStep() {
    switch (currentStep) {
      case 0:
        return buildCallTypeStep();
      case 1:
        return buildContactDetailsStep();
      case 2:
        return buildSymptomsStep();
      case 3:
        return buildPaymentStep();
      default:
        return const SizedBox();
    }
  }

  Widget buildAppointmentStep() {
    return Column(
      children: [
        const Text('اختيار الموعد', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        const SizedBox(height: 25),
        optionCard(
          icon: Icons.calendar_month,
          title: widget.selectedTime['day'] ?? 'الموعد',
          subtitle: '${widget.selectedTime['from'] ?? ''} - ${widget.selectedTime['to'] ?? ''}',
          selected: true,
          onTap: () {},
        ),
        const SizedBox(height: 30),
        mainButton('استمرار', nextStep),
      ],
    );
  }

  Widget buildCallTypeStep() {
    return Column(
      children: [
        const Text(
          'نوع مكالمة الاستشارة الطبية',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        const Text('اختر طريقة التواصل المناسبة لك', style: TextStyle(fontSize: 16, color: Colors.black87)),
        const SizedBox(height: 25),
        optionCard(
          icon: Icons.phone,
          title: 'مكالمة صوتية عبر الهاتف',
          subtitle: 'سيتم التواصل معك على رقم الهاتف',
          selected: callType == 'phone',
          onTap: () => setState(() => callType = 'phone'),
        ),
        const SizedBox(height: 18),
        optionCard(
          icon: Icons.videocam,
          title: 'مكالمة فيديو',
          subtitle: 'سيتم إرسال رابط الاستشارة لاحقاً',
          selected: callType == 'video',
          onTap: () => setState(() => callType = 'video'),
        ),
        const SizedBox(height: 30),
        mainButton('استمرار', () {
          if (callType != null) nextStep();
        }),
      ],
    );
  }

  Widget buildContactDetailsStep() {
    return Column(
      children: [
        const Text('تفاصيل الاتصال', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        buildTextField(hint: 'الاسم الكامل', controller: nameController, icon: Icons.badge_outlined),
        const SizedBox(height: 15),
        buildTextField(hint: 'رقم المحمول', controller: phoneController, icon: Icons.phone, keyboardType: TextInputType.phone),
        const SizedBox(height: 25),
        Text(
          callType == 'video'
              ? 'سيتم إرسال رابط اللقاء على الرقم المدون في الاستشارة الهاتفية مع التأكيد'
              : 'سيتم الاتصال على الرقم المدون في الاستشارة الهاتفية',
          style: const TextStyle(fontSize: 15, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 30),
        mainButton('استمرار', nextStep),
      ],
    );
  }

  Widget buildSymptomsStep() {
    return Column(
      children: [
        const Text(
          'معلومات إضافية للدكتور',
          style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 25),
        buildTextField(hint: 'السن', controller: ageController, icon: Icons.cake_outlined, keyboardType: TextInputType.number),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Radio<String>(value: 'ذكر', groupValue: gender, onChanged: (value) => setState(() => gender = value)),
            const Text('ذكر', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 40),
            Radio<String>(value: 'أنثى', groupValue: gender, onChanged: (value) => setState(() => gender = value)),
            const Text('أنثى', style: TextStyle(fontSize: 16)),
          ],
        ),
        const SizedBox(height: 18),
        TextFormField(
          controller: symptomsController,
          maxLines: 3,
          textAlign: TextAlign.right,
          decoration: InputDecoration(
            hintText: 'اكتب الأعراض أو سبب الاستشارة',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 30),
        mainButton('استمرار', () {
          if (ageController.text.trim().isEmpty || gender == null || symptomsController.text.trim().isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('السن والنوع والأعراض مطلوبة')));
            return;
          }
          nextStep();
        }),
      ],
    );
  }


  Future<void> pickPaymentImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 45,
      maxWidth: 900,
    );

    if (picked == null) return;

    final bytes = await File(picked.path).readAsBytes();
    if (bytes.length > 700 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الصورة كبيرة جداً، اختر صورة أصغر أو Screenshot')),
        );
      }
      return;
    }
    final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';

    setState(() {
      paymentAttachmentUrl = base64Image;
      paymentAttachmentType = 'base64';
    });
  }

  Widget paymentPreview() {
    if (paymentAttachmentUrl == null || paymentAttachmentUrl!.isEmpty) {
      return const SizedBox();
    }

    return Column(
      children: [
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => AppImageHelper.showPreview(context, paymentAttachmentUrl),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 110,
              width: 110,
              child: AppImageHelper.image(paymentAttachmentUrl, fit: BoxFit.cover),
            ),
          ),
        ),
        const SizedBox(height: 6),
        const Text('تم اختيار صورة الدفع من المعرض', style: TextStyle(color: Colors.blue)),
      ],
    );
  }

  Widget buildPaymentStep() {
    if (paymentMethod == null) {
      return Column(
        children: [
          const Text('اختر طريقة الدفع', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 25),
          optionCard(
            icon: Icons.account_balance,
            title: 'بنك فلسطين',
            subtitle: 'تحويل بنكي إلى حساب الطبيب',
            selected: false,
            onTap: () => setState(() => paymentMethod = 'bank'),
          ),
          const SizedBox(height: 18),
          optionCard(
            icon: Icons.account_balance_wallet,
            title: 'Jawwal Pay',
            subtitle: 'تحويل عبر تطبيق جوال باي',
            selected: false,
            onTap: () => setState(() => paymentMethod = 'jawwal'),
          ),
        ],
      );
    }

    return buildPaymentConfirmation();
  }

  Widget buildPaymentConfirmation() {
    return Column(
      children: [
        const Text('تحويل رسوم الكشف', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
         Text(
          paymentMethod == 'bank' ? 'حوّل على رقم بنك فلسطين الخاص بالطبيب ثم أرفق صورة التحويل' : 'حوّل على رقم Jawwal Pay الخاص بالطبيب ثم أرفق صورة التحويل',
          style: TextStyle(fontSize: 16, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.blue.shade100)),
          child: Column(
            children: [
              const Text('رقم التحويل الخاص بالطبيب', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SelectableText(
                paymentMethod == 'bank' ? bankPalestineNumber : jawwalPayNumber,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              infoRow('طريقة الدفع', paymentMethod == 'bank' ? 'بنك فلسطين' : 'Jawwal Pay'),
              infoRow('اسم الدكتور', doctorName),
              infoRow('تاريخ الحجز', appointmentDate),
              infoRow('موعد المكالمة', selectedTimeText),
              infoRow('رقم الجوال', FirebaseService.formatPhoneForDisplay(phoneController.text.trim())),
              infoRow('نوع المكالمة', callType == 'video' ? 'مكالمة فيديو' : 'مكالمة صوتية'),
              infoRow('سعر الكشف', '$price شيكل'),
            ],
          ),
        ),
        const SizedBox(height: 25),
        OutlinedButton.icon(
          onPressed: pickPaymentImage,
          icon: const Icon(Icons.upload_file),
          label: Text(
            paymentAttachmentUrl == null ? 'ارفق صورة الدفع' : 'تم إرفاق صورة الدفع',
            style: const TextStyle(fontSize: 18),
          ),
          style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 55)),
        ),
        paymentPreview(),
        const SizedBox(height: 30),
        mainButton(loading ? 'جاري التأكيد...' : 'تأكيد الحجز', loading ? () {} : confirmPhoneBooking),
        textButton('تغيير طريقة الدفع', () => setState(() => paymentMethod = null)),
      ],
    );
  }

  Widget optionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 12, offset: const Offset(0, 4))],
          border: Border.all(color: selected ? const Color(0xff0878D1) : Colors.transparent, width: 2),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: const Color(0xffEAF4FF),
              child: Icon(icon, color: const Color(0xff0878D1), size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                Text(subtitle, style: const TextStyle(fontSize: 14, color: Colors.grey)),
              ]),
            ),
            const Icon(Icons.arrow_back_ios, size: 16),
          ],
        ),
      ),
    );
  }

  Widget buildTextField({
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      textAlign: TextAlign.right,
      textDirection: keyboardType == TextInputType.phone ? TextDirection.ltr : TextDirection.rtl,
      keyboardType: keyboardType,
      inputFormatters: keyboardType == TextInputType.phone
          ? [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)]
          : null,
      decoration: InputDecoration(
        hintText: keyboardType == TextInputType.phone ? '05xxxxxxxx' : hint,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget mainButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xff0878D1),
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(text, style: const TextStyle(fontSize: 18, color: Colors.white)),
    );
  }

  Widget textButton(String text, VoidCallback onPressed) {
    return TextButton(
      onPressed: onPressed,
      child: Text(
        text,
        style: const TextStyle(fontSize: 17, color: Color(0xff0878D1), fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Text(title, style: const TextStyle(fontSize: 15, color: Colors.grey)),
          const Spacer(),
          Flexible(
            child: Text(value, textAlign: TextAlign.left, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
