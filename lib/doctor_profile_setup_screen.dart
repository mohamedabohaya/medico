import 'dart:convert';
import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'doctor_dashboard_screen.dart';
import 'firebase_service.dart';
import 'session_manager.dart';
import 'app_image_helper.dart';

class DoctorProfileSetupScreen extends StatefulWidget {
  final String? doctorRequestId;
  final String? phone;
  final Map<String, dynamic>? existingProfile;

  const DoctorProfileSetupScreen({
    super.key,
    this.doctorRequestId,
    this.phone,
    this.existingProfile,
  });

  @override
  State<DoctorProfileSetupScreen> createState() => _DoctorProfileSetupScreenState();
}

class _DoctorProfileSetupScreenState extends State<DoctorProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();

  final name = TextEditingController(text: '');
  final mainSpecialty = TextEditingController();
  final subSpecialties = TextEditingController();

  final List<String> specialties = [
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

  String? selectedMainSpecialty;
  final List<String> weekDays = const [
    'السبت',
    'الأحد',
    'الإثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
  ];
  String? selectedAvailableDay;
  final about = TextEditingController();
  final clinicName = TextEditingController();
  final price = TextEditingController();
  final clinicVisitPrice = TextEditingController();
  final phonePrice = TextEditingController();
  final homeVisitPrice = TextEditingController();
  final waitingTime = TextEditingController();
  final bankPalestineNumber = TextEditingController();
  final jawwalPayNumber = TextEditingController();
  final fullAddress = TextEditingController();
  final availableDay = TextEditingController();
  final availableFrom = TextEditingController();
  final availableTo = TextEditingController();

  bool clinicVisit = true;
  bool homeVisit = false;
  bool phoneCall = false;
  bool loading = false;

  List<Map<String, String>> availableTimes = [];
  List<String> clinicImages = [];
  String? personalImage;

  @override
  void initState() {
    super.initState();
    final p = widget.existingProfile;
    if (p != null) {
      name.text = p['name']?.toString() ?? '';
      mainSpecialty.text = p['mainSpecialty']?.toString() ?? '';
      selectedMainSpecialty = specialties.contains(mainSpecialty.text) ? mainSpecialty.text : null;
      subSpecialties.text = p['subSpecialties']?.toString() ?? '';
      about.text = p['about']?.toString() ?? '';
      clinicName.text = p['clinicName']?.toString() ?? '';
      price.text = p['price']?.toString() ?? '';
      clinicVisitPrice.text = p['clinicVisitPrice']?.toString() ?? p['price']?.toString() ?? '';
      phonePrice.text = p['phonePrice']?.toString() ?? p['price']?.toString() ?? '';
      homeVisitPrice.text = p['homeVisitPrice']?.toString() ?? p['price']?.toString() ?? '';
      waitingTime.text = p['waitingTime']?.toString() ?? '';
      bankPalestineNumber.text = p['bankPalestineNumber']?.toString() ?? '';
      jawwalPayNumber.text = p['jawwalPayNumber']?.toString() ?? '';
      fullAddress.text = p['fullAddress']?.toString() ?? '';
      clinicVisit = p['clinicVisit'] == true || p['clinicVisit'] == 1;
      homeVisit = p['homeVisit'] == true || p['homeVisit'] == 1;
      phoneCall = p['phoneCall'] == true || p['phoneCall'] == 1;
      personalImage = p['personalImage']?.toString();

      final times = p['availableTimes'];
      if (times is List) {
        availableTimes = times
            .map((e) => Map<String, String>.from((e as Map).map((key, value) => MapEntry(key.toString(), value.toString()))))
            .toList();
      }

      final imgs = p['clinicImages'];
      if (imgs is List) clinicImages = imgs.map((e) => e.toString()).toList();
    }
  }

  @override
  void dispose() {
    for (final c in [
      name,
      mainSpecialty,
      subSpecialties,
      about,
      clinicName,
      price,
      clinicVisitPrice,
      phonePrice,
      homeVisitPrice,
      waitingTime,
      bankPalestineNumber,
      jawwalPayNumber,
      fullAddress,
      availableDay,
      availableFrom,
      availableTo,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<String?> pickImageAsDataUrl({int maxKb = 700}) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 45,
      maxWidth: 900,
    );
    if (picked == null) return null;

    final bytes = await File(picked.path).readAsBytes();
    if (bytes.length > maxKb * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('الصورة كبيرة جداً، اختر صورة أصغر من ${maxKb}KB')),
        );
      }
      return null;
    }

    final ext = picked.path.split('.').last.toLowerCase();
    final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
    return 'data:$mime;base64,${base64Encode(bytes)}';
  }

  Future<void> pickPersonalImage() async {
    final image = await pickImageAsDataUrl(maxKb: 700);
    if (image != null) {
      setState(() => personalImage = image);
    }
  }

  Future<void> pickClinicImages() async {
    final image = await pickImageAsDataUrl(maxKb: 700);
    if (image != null) {
      setState(() => clinicImages.add(image));
    }
  }

  void addAvailableTime() {
    if ((selectedAvailableDay == null || selectedAvailableDay!.trim().isEmpty) ||
        availableFrom.text.trim().isEmpty ||
        availableTo.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل اليوم ووقت البداية والنهاية')),
      );
      return;
    }

    setState(() {
      availableTimes.add({
        'day': selectedAvailableDay ?? '',
        'from': availableFrom.text.trim(),
        'to': availableTo.text.trim(),
      });
      selectedAvailableDay = null;
      availableFrom.clear();
      availableTo.clear();
    });
  }

  Future<void> save() async {
    if (!_formKey.currentState!.validate()) return;
    if (availableTimes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أضف وقت واحد على الأقل لتوفر الطبيب')),
      );
      return;
    }

    setState(() => loading = true);

    final data = {
      'name': name.text.trim(),
      'mainSpecialty': mainSpecialty.text.trim(),
      'subSpecialties': subSpecialties.text.trim(),
      'about': about.text.trim(),
      'clinicName': clinicName.text.trim(),
      'price': clinicVisitPrice.text.trim().isNotEmpty ? clinicVisitPrice.text.trim() : price.text.trim(),
      'clinicVisitPrice': clinicVisitPrice.text.trim().isNotEmpty ? clinicVisitPrice.text.trim() : price.text.trim(),
      'phonePrice': phonePrice.text.trim(),
      'homeVisitPrice': homeVisitPrice.text.trim(),
      'waitingTime': waitingTime.text.trim(),
      'bankPalestineNumber': bankPalestineNumber.text.trim(),
      'jawwalPayNumber': jawwalPayNumber.text.trim(),
      'fullAddress': fullAddress.text.trim(),
      'availableTimes': availableTimes,
      'personalImage': personalImage ?? '',
      'clinicImages': clinicImages,
      'clinicVisit': clinicVisit,
      'homeVisit': homeVisit,
      'phoneCall': phoneCall,
      'phone': widget.phone ?? widget.existingProfile?['phone'] ?? '',
      'doctorRequestId': widget.doctorRequestId ?? widget.existingProfile?['doctorRequestId'],
    };

    try {
      final doctorId = widget.existingProfile?['id']?.toString();
      if (doctorId == null || doctorId.isEmpty) {
        await FirebaseService.saveDoctorProfile(
          data,
          doctorRequestId: widget.doctorRequestId,
          phone: widget.phone,
        );
      } else {
        await FirebaseService.updateDoctorProfile(doctorId, data);
      }

      await SessionManager.saveDoctorLogin(
        phone: widget.phone ?? widget.existingProfile?['phone']?.toString() ?? '',
        doctorRequestId: widget.doctorRequestId ?? widget.existingProfile?['doctorRequestId']?.toString(),
      );

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => DoctorDashboardScreen(
            doctorRequestId: widget.doctorRequestId ?? widget.existingProfile?['doctorRequestId']?.toString(),
            phone: widget.phone ?? widget.existingProfile?['phone']?.toString(),
          ),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء الحفظ: $e')),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingProfile != null;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          backgroundColor: Colors.blue,
          centerTitle: true,
          title: Text(
            isEdit ? 'تعديل بياناتي' : 'استكمال بيانات الطبيب',
            style: const TextStyle(color: Colors.white),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              card('الصورة الشخصية', [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.blue.shade50,
                      backgroundImage: AppImageHelper.provider(personalImage),
                      child: AppImageHelper.provider(personalImage) == null
                          ? const Icon(Icons.person, color: Colors.blue, size: 38)
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        personalImage == null || personalImage!.isEmpty
                            ? 'لم يتم اختيار صورة'
                            : 'تم اختيار الصورة الشخصية',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: pickPersonalImage,
                      icon: const Icon(Icons.image),
                      label: const Text('اختيار'),
                    ),
                  ],
                ),
              ]),
              const SizedBox(height: 14),
              card('الخدمات التي يقدمها الطبيب', [
                serviceSwitch('زيارة في العيادة', Icons.local_hospital, clinicVisit, (v) => setState(() => clinicVisit = v)),
                serviceSwitch('زيارة منزلية', Icons.home_work, homeVisit, (v) => setState(() => homeVisit = v)),
                serviceSwitch('مكالمة هاتفية', Icons.phone_in_talk, phoneCall, (v) => setState(() => phoneCall = v)),
              ]),
              const SizedBox(height: 14),
              card('بيانات التخصص والأسعار', [
                field(name, 'اسم الطبيب'),
                specialtyDropdown(),
                field(subSpecialties, 'التخصصات الفرعية - افصل بينها بفاصلة'),
                field(clinicVisitPrice, 'سعر كشف زيارة العيادة', keyboardType: TextInputType.number),
                field(phonePrice, 'سعر مكالمة الدكتور', keyboardType: TextInputType.number, required: false),
                field(homeVisitPrice, 'سعر الزيارة المنزلية', keyboardType: TextInputType.number, required: false),
                field(waitingTime, 'مدة الانتظار المتوقعة مثال: 15 دقيقة'),
              ]),
              const SizedBox(height: 14),
              card('أرقام التحويل المالي', [
                field(bankPalestineNumber, 'رقم بنك فلسطين للتحويل', keyboardType: TextInputType.phone, required: false),
                field(jawwalPayNumber, 'رقم Jawwal Pay للتحويل', keyboardType: TextInputType.phone, required: false),
              ]),
              const SizedBox(height: 14),
              card('العنوان', [
                field(clinicName, 'اسم العيادة / المركز'),
                field(
                  fullAddress,
                  'العنوان كامل: المدينة، المنطقة، الشارع، العمارة، الدور، الشقة، علامة مميزة',
                  maxLines: 4,
                ),
              ]),
              const SizedBox(height: 14),
              card('أيام وساعات التوفر', [
                Row(
                  children: [
                    Expanded(child: dayDropdown()),
                    const SizedBox(width: 8),
                    Expanded(child: field(availableFrom, 'من', required: false,keyboardType: TextInputType.number)),
                    const SizedBox(width: 8),
                    Expanded(child: field(availableTo, 'إلى', required: false,keyboardType: TextInputType.number)),
                  ],
                ),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: addAvailableTime,
                    icon: const Icon(Icons.add),
                    label: const Text('إضافة وقت'),
                  ),
                ),
                const SizedBox(height: 8),
                ...availableTimes.asMap().entries.map((entry) {
                  final i = entry.key;
                  final item = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: Text('${item['day']} من ${item['from']} إلى ${item['to']}')),
                        IconButton(
                          onPressed: () => setState(() => availableTimes.removeAt(i)),
                          icon: const Icon(Icons.delete, color: Colors.red),
                        ),
                      ],
                    ),
                  );
                }),
              ]),
              const SizedBox(height: 14),
              card('صور العيادة', [
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: pickClinicImages,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('إضافة صور للعيادة'),
                  ),
                ),
                const SizedBox(height: 8),
                if (clinicImages.isEmpty)
                  Text('لم يتم إضافة صور بعد', style: TextStyle(color: Colors.grey.shade600)),
                if (clinicImages.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: clinicImages.asMap().entries.map((entry) {
                      final i = entry.key;
                      final img = entry.value;
                      return Stack(
                        children: [
                          GestureDetector(
                            onTap: () => AppImageHelper.showPreview(context, img),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                width: 92,
                                height: 92,
                                child: AppImageHelper.image(img, fit: BoxFit.cover),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 0,
                            left: 0,
                            child: InkWell(
                              onTap: () => setState(() => clinicImages.removeAt(i)),
                              child: Container(
                                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                padding: const EdgeInsets.all(3),
                                child: const Icon(Icons.close, size: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
              ]),
              const SizedBox(height: 14),
              card('معلومات عن الدكتور', [
                field(about, 'اكتب نبذة عن خبرتك وخدماتك', maxLines: 5),
              ]),
              const SizedBox(height: 24),
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: loading ? null : save,
                  child: loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          isEdit ? 'حفظ التعديلات' : 'حفظ البيانات والدخول',
                          style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget card(String title, List<Widget> children) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          ...children,
        ]),
      );


  Widget specialtyDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        dropdownColor: Colors.white,
        value: selectedMainSpecialty,
        isExpanded: true,
        decoration: InputDecoration(
          hintText: 'اختر التخصص الرئيسي',
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
        items: specialties.map((specialty) {
          return DropdownMenuItem<String>(
            value: specialty,
            child: Text(specialty),
          );
        }).toList(),
        validator: (v) => v == null || v.trim().isEmpty ? 'اختر التخصص الرئيسي' : null,
        onChanged: (value) {
          setState(() {
            selectedMainSpecialty = value;
            mainSpecialty.text = value ?? '';
          });
        },
      ),
    );
  }


  Widget dayDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        dropdownColor: Colors.white,
        value: selectedAvailableDay,
        isExpanded: true,
        decoration: InputDecoration(
          hintText: 'اختر اليوم',
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        ),
        items: weekDays.map((day) => DropdownMenuItem(value: day, child: Text(day))).toList(),
        onChanged: (v) => setState(() => selectedAvailableDay = v),
      ),
    );
  }

  Widget field(
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
    TextInputType? keyboardType,
    bool required = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'هذا الحقل مطلوب' : null : null,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget serviceSwitch(String title, IconData icon, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      secondary: Icon(icon, color: Colors.blue),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      value: value,
      activeColor: Colors.blue,
      onChanged: onChanged,
    );
  }
}
