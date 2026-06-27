
import 'package:flutter/material.dart';
import 'firebase_service.dart';
import 'app_image_helper.dart';

class DoctorAppointmentDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> appointment;
  final Map<String, dynamic>? doctorProfile;

  const DoctorAppointmentDetailsScreen({
    super.key,
    required this.appointment,
    this.doctorProfile,
  });

  @override
  State<DoctorAppointmentDetailsScreen> createState() => _DoctorAppointmentDetailsScreenState();
}

class _DoctorAppointmentDetailsScreenState extends State<DoctorAppointmentDetailsScreen> {
  Map<String, dynamic>? patient;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadPatient();
  }

  Future<void> loadPatient() async {
    final phone = widget.appointment['patientPhone']?.toString() ?? '';
    final data = phone.isEmpty ? null : await FirebaseService.getUserByPhone(phone);
    if (!mounted) return;
    setState(() {
      patient = data;
      loading = false;
    });
  }

  String get serviceTitle {
    final type = widget.appointment['serviceType']?.toString() ?? 'clinic';
    if (type == 'phone') return 'مكالمة دكتور';
    if (type == 'home') return 'زيارة منزلية';
    return 'زيارة عيادة';
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

  @override
  Widget build(BuildContext context) {
    final item = widget.appointment;
    final type = item['serviceType']?.toString() ?? 'clinic';
    final homeAddress = item['patientAddress']?.toString() ?? '';
    final attachment = item['paymentAttachment']?.toString() ?? item['paymentImage']?.toString() ?? '';
    final patientName = item['patientName']?.toString() ?? patient?['name']?.toString() ?? 'مريض';
    final rawGender = item['patientGender']?.toString() ?? patient?['gender']?.toString() ?? '';
    final patientGender = rawGender == 'Male' ? 'ذكر' : (rawGender == 'Female' ? 'أنثى' : (rawGender.isEmpty ? 'غير محدد' : rawGender));
    final savedAge = item['patientAge']?.toString() ?? '';
    final patientAge = savedAge.isNotEmpty ? savedAge : calcAge(patient?['birthdate'] ?? patient?['birthDate']);
    final price = formatAmount(item['price'] ?? FirebaseService.servicePrice(widget.doctorProfile ?? {}, type));

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xffF4F6F9),
        appBar: AppBar(
          title: const Text('تفاصيل حجز المريض'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: box(),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 42,
                          backgroundColor: Colors.blue.shade50,
                          backgroundImage: AppImageHelper.provider(patient?['profileImage']?.toString()),
                          child: AppImageHelper.provider(patient?['profileImage']?.toString()) == null
                              ? const Icon(Icons.person, color: Colors.blue, size: 42)
                              : null,
                        ),
                        const SizedBox(height: 12),
                        Text(patientName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text(serviceTitle, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: box(),
                    child: Column(
                      children: [
                        row('العمر', patientAge.isEmpty ? 'غير محدد' : patientAge),
                        row('النوع', patientGender),
                        row('رقم الجوال', formatPhoneForDisplay(item['patientPhone']?.toString() ?? 'غير متوفر')),
                        row('تاريخ الحجز', item['appointmentDate']?.toString() ?? 'غير محدد'),
                        row('موعد الحجز', item['date']?.toString() ?? item['time']?.toString() ?? 'لم يحدد'),
                        if (type == 'home' && homeAddress.isNotEmpty) row('عنوان المريض', homeAddress),
                        row('سعر الكشف', price),
                        if ((item['symptoms'] ?? '').toString().isNotEmpty)
                          row('الأعراض', item['symptoms'].toString()),
                      ],
                    ),
                  ),
                  if (attachment.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: box(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('صورة التحويل المالي', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          Center(
                            child: GestureDetector(
                              onTap: () => AppImageHelper.showPreview(context, attachment),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: SizedBox(
                                  height: 170,
                                  width: 170,
                                  child: AppImageHelper.image(attachment, fit: BoxFit.cover),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Center(child: Text('اضغط على الصورة للتكبير', style: TextStyle(color: Colors.grey))),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  if ((item['status'] ?? '').toString() == 'booked')
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                await FirebaseService.markAppointmentDone(item['id'].toString());
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('تم إنهاء الزيارة / الخدمة')),
                                );
                                Navigator.pop(context);
                              },
                              icon: const Icon(Icons.check_circle, color: Colors.green),
                              label: const Text('تمت الخدمة', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                              onPressed: () async {
                                final ok = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    backgroundColor: Colors.white,
                                    title: const Text('إلغاء الحجز'),
                                    content: const Text('هل تريد إلغاء هذا الحجز؟'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('لا')),
                                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('نعم')),
                                    ],
                                  ),
                                );
                                if (ok == true) {
                                  await FirebaseService.cancelAppointment(item['id'].toString());
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إلغاء الحجز')));
                                  Navigator.pop(context);
                                }
                              },
                              icon: const Icon(Icons.cancel),
                              label: const Text('إلغاء الحجز', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
      ),
    );
  }

  BoxDecoration box() => BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18));

  String formatAmount(dynamic value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty || text == 'غير محدد') return 'غير محدد';
    final cleaned = text.replaceAll('جنيه', '').replaceAll('شيكل', '').trim();
    return '$cleaned شيكل';
  }

  String formatPhoneForDisplay(String phone) => FirebaseService.formatPhoneForDisplay(phone);

  Widget row(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 115,
            child: Text(title, style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Directionality(
              textDirection: value.trim().startsWith('+') ? TextDirection.ltr : TextDirection.rtl,
              child: Text(value, textAlign: TextAlign.start, style: const TextStyle(fontWeight: FontWeight.w600, height: 1.4)),
            ),
          ),
        ],
      ),
    );
  }
}
