import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'booking_success_screen.dart';
import 'firebase_service.dart';
import 'session_manager.dart';
import 'app_image_helper.dart';

class ConfirmBookingScreen extends StatefulWidget {
  final Map<String, dynamic> doctor;
  final String serviceType; // clinic | home
  final Map<String, String> selectedTime;

  const ConfirmBookingScreen({
    super.key,
    required this.doctor,
    required this.serviceType,
    required this.selectedTime,
  });

  @override
  State<ConfirmBookingScreen> createState() => _ConfirmBookingScreenState();
}

class _ConfirmBookingScreenState extends State<ConfirmBookingScreen> {
  bool forAnother = false;
  bool loading = false;
  Map<String, dynamic>? patientData;

  String? selectedCity;

  final nameController = TextEditingController(text: 'عمار اسامة');
  final phoneController = TextEditingController();
  final areaController = TextEditingController();
  final streetController = TextEditingController();
  final buildingController = TextEditingController();
  final floorController = TextEditingController();
  final apartmentController = TextEditingController();
  final landmarkController = TextEditingController();

  final List<String> cities = [
    'شمال غزة',
    'غزة',
    'الوسطى',
    'جنوب غزة',
  ];


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
    });
  }

  String get doctorId => (widget.doctor['id'] ?? widget.doctor['doctorId'] ?? '').toString();
  String get doctorName => (widget.doctor['name'] ?? widget.doctor['fullName'] ?? 'دكتور').toString();
  String get specialty => (widget.doctor['mainSpecialty'] ?? 'تخصص عام').toString();
  String get doctorImage => (widget.doctor['personalImage'] ?? '').toString();
  String get clinicAddress => (widget.doctor['fullAddress'] ?? widget.doctor['address'] ?? 'لم يتم تحديد العنوان').toString();
  String get price => FirebaseService.servicePrice(widget.doctor, widget.serviceType);

  String get serviceTitle => widget.serviceType == 'home' ? 'زيارة منزلية' : 'زيارة عيادة';

  String get selectedTimeText {
    return FirebaseService.timeStringForSelectedTime(widget.selectedTime);
  }

  String get appointmentDate => FirebaseService.dateStringForSelectedTime(widget.selectedTime);

  String get patientAddress {
    return [
      selectedCity,
      areaController.text.trim(),
      streetController.text.trim(),
      buildingController.text.trim(),
      floorController.text.trim().isNotEmpty ? 'الدور ${floorController.text.trim()}' : '',
      apartmentController.text.trim().isNotEmpty ? 'شقة ${apartmentController.text.trim()}' : '',
      landmarkController.text.trim().isNotEmpty ? 'علامة مميزة: ${landmarkController.text.trim()}' : '',
    ].where((e) => e != null && e.toString().trim().isNotEmpty).join(' - ');
  }

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


  Future<void> confirmBooking() async {
    if (!FirebaseService.isValidLocalPhone(phoneController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(FirebaseService.localPhoneErrorText())),
      );
      return;
    }

    if (widget.serviceType == 'home' && (selectedCity == null || areaController.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل عنوان المريض للزيارة المنزلية')),
      );
      return;
    }

    setState(() => loading = true);

    final location = widget.serviceType == 'home' ? patientAddress : clinicAddress;

    await FirebaseService.createBooking({
      'doctorId': doctorId,
      'doctorName': doctorName,
      'doctorSpecialty': specialty,
      'doctorImage': doctorImage,
      'patientName': nameController.text.trim(),
      'patientPhone': FirebaseService.normalizePhone(phoneController.text.trim()),
      'patientGender': patientData?['gender']?.toString() ?? '',
      'patientAge': calcAge(patientData?['birthdate'] ?? patientData?['birthDate']),
      'serviceType': widget.serviceType,
      'serviceTitle': serviceTitle,
      'date': selectedTimeText,
      'appointmentDate': appointmentDate,
      'appointmentDay': widget.selectedTime['day'] ?? '',
      'appointmentFrom': widget.selectedTime['from'] ?? '',
      'appointmentTo': widget.selectedTime['to'] ?? '',
      'selectedTime': {...widget.selectedTime, 'date': appointmentDate},
      'location': location,
      'clinicLocation': clinicAddress,
      'patientAddress': widget.serviceType == 'home' ? patientAddress : '',
      'price': price,
      'finalAmount': '$price شيكل',
    });

    if (!mounted) return;
    setState(() => loading = false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => BookingSuccessScreen(
          doctor: widget.doctor,
          serviceType: widget.serviceType,
          selectedTime: {...widget.selectedTime, 'date': appointmentDate},
          location: location,
          finalAmount: '$price شيكل',
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    areaController.dispose();
    streetController.dispose();
    buildingController.dispose();
    floorController.dispose();
    apartmentController.dispose();
    landmarkController.dispose();
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
          title: const Text("تأكيد الحجز"),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: box(),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.blue.shade100,
                      backgroundImage: AppImageHelper.provider(doctorImage),
                      child: AppImageHelper.provider(doctorImage) == null ? const Icon(Icons.person, color: Colors.blue) : null,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      doctorName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$specialty - $serviceTitle',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: box(),
                child: Column(
                  children: [
                    buildField("الاسم الكامل", nameController),
                    const SizedBox(height: 12),
                    buildField("رقم المحمول", phoneController, keyboardType: TextInputType.phone),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              if (widget.serviceType == 'clinic')
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: box(),
                  child: Column(
                    children: [
                      rowItem(Icons.date_range, 'تاريخ الحجز: $appointmentDate'),
                      const SizedBox(height: 10),
                      rowItem(Icons.calendar_today, selectedTimeText.isEmpty ? 'لم يحدد' : selectedTimeText),
                      const SizedBox(height: 10),
                      rowItem(Icons.location_on, clinicAddress),
                    ],
                  ),
                ),
              if (widget.serviceType == 'home') ...[
                addressSection(),
                // const SizedBox(height: 10),
                // homeReviewSection(),
              ],
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: box(),
                child: Row(
                  children: [
                    const Text("سعر الكشف", style: TextStyle(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Text("$price شيكل", style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 55,
            child: ElevatedButton(
              onPressed: loading ? null : confirmBooking,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("تأكيد", style: TextStyle(color: Colors.white, fontSize: 18)),
            ),
          ),
        ),
      ),
    );
  }

  Widget addressSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: box(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('عنوان المريض', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            dropdownColor: Colors.white,
            value: selectedCity,
            decoration: InputDecoration(
              hintText: 'اختر المدينة',
              prefixIcon: const Icon(Icons.location_city),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: cities.map((city) => DropdownMenuItem(value: city, child: Text(city))).toList(),
            onChanged: (value) => setState(() => selectedCity = value),
          ),
          const SizedBox(height: 12),
          buildTextField('اسم المنطقة', Icons.place, areaController),
          buildTextField('الشارع', Icons.add_road, streetController),
          buildTextField('اسم العمارة', Icons.apartment, buildingController),
          Row(
            children: [
              Expanded(child: buildAddressField(hint: 'الدور', controller: floorController)),
              const SizedBox(width: 12),
              Expanded(child: buildAddressField(hint: 'رقم الشقة', controller: apartmentController)),
            ],
          ),
          const SizedBox(height: 12),
          buildTextField('علامة مميزة', Icons.flag, landmarkController),
        ],
      ),
    );
  }


  Widget homeReviewSection() {
    final address = patientAddress.isEmpty ? 'أدخل عنوان المريض أعلاه' : patientAddress;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: box(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('مراجعة بيانات الزيارة المنزلية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          rowItem(Icons.date_range, 'تاريخ الحجز: $appointmentDate'),
          const SizedBox(height: 10),
          rowItem(Icons.calendar_today, selectedTimeText.isEmpty ? 'الموعد: لم يحدد' : 'الموعد: $selectedTimeText'),
          const SizedBox(height: 10),
          rowItem(Icons.person, 'اسم المريض: ${nameController.text.trim().isEmpty ? 'لم يتم الإدخال' : nameController.text.trim()}'),
          const SizedBox(height: 10),
          rowItem(Icons.phone, 'رقم الجوال: ${FirebaseService.formatPhoneForDisplay(phoneController.text.trim())}'),
          const SizedBox(height: 10),
          rowItem(Icons.location_on, 'عنوان المريض: $address'),
        ],
      ),
    );
  }

  BoxDecoration box() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    );
  }

  Widget buildField(String label, TextEditingController controller, {TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: keyboardType == TextInputType.phone
          ? [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)]
          : null,
      textDirection: keyboardType == TextInputType.phone ? TextDirection.ltr : TextDirection.rtl,
      textAlign: TextAlign.right,
      decoration: InputDecoration(
        hintText: keyboardType == TextInputType.phone ? '05xxxxxxxx' : null,
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget buildTextField(String hint, IconData icon, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        textAlign: TextAlign.right,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget buildAddressField({required String hint, required TextEditingController controller}) {
    return TextFormField(
      controller: controller,
      textAlign: TextAlign.right,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  static Widget rowItem(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.blue),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(height: 1.45))),
      ],
    );
  }
}
