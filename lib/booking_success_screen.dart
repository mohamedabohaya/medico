import 'package:flutter/material.dart';

import 'navigation.dart';

class BookingSuccessScreen extends StatelessWidget {
  final Map<String, dynamic> doctor;
  final String serviceType;
  final Map<String, String> selectedTime;
  final String location;
  final String finalAmount;

  const BookingSuccessScreen({
    super.key,
    required this.doctor,
    required this.serviceType,
    required this.selectedTime,
    required this.location,
    required this.finalAmount,
  });

  String get serviceTitle {
    if (serviceType == 'home') return 'زيارة منزلية';
    if (serviceType == 'phone') return 'مكالمة هاتفية';
    return 'زيارة عيادة';
  }

  String get appointmentDate {
    final existing = selectedTime['date']?.trim();
    if (existing != null && existing.isNotEmpty) return existing;
    final now = DateTime.now();
    return '${now.day}/${now.month}/${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    final doctorName = (doctor['name'] ?? doctor['fullName'] ?? 'دكتور').toString();
    final specialty = (doctor['mainSpecialty'] ?? 'تخصص عام').toString();
    final appointmentTime = '${selectedTime['day'] ?? ''} من ${selectedTime['from'] ?? ''} إلى ${selectedTime['to'] ?? ''}'.trim();
    final amount = finalAmount.contains('شيكل') ? finalAmount : '$finalAmount شيكل';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          title: const Text('تم تأكيد الحجز'),
          centerTitle: true,
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 10)],
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green, size: 80),
                            const SizedBox(height: 12),
                            const Text(
                              'تم تأكيد الحجز بنجاح',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(20)),
                              child: Text(serviceTitle, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      detailCard([
                        row(Icons.person, 'اسم الدكتور', doctorName),
                        row(Icons.medical_services, 'التخصص', specialty),
                        row(Icons.date_range, 'تاريخ الحجز', appointmentDate),
                        row(Icons.calendar_today, 'موعد الحجز', appointmentTime.isEmpty ? 'لم يحدد' : appointmentTime),
                        if (serviceType != 'phone' && location.trim().isNotEmpty)
                          row(Icons.location_on, serviceType == 'home' ? 'عنوان المريض' : 'عنوان العيادة', location),
                        row(Icons.payments, 'سعر الكشف', amount),
                      ]),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const MainNavigation(initialIndex: 1)),
                        (route) => false,
                      );
                    },
                    child: const Text('الذهاب إلى معاملاتي', style: TextStyle(color: Colors.white, fontSize: 17)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget detailCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Column(children: children),
    );
  }

  Widget row(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue, size: 22),
          const SizedBox(width: 10),
          SizedBox(width: 92, child: Text(title, style: const TextStyle(color: Colors.grey))),
          const SizedBox(width: 8),
          Expanded(
            child: Directionality(
              textDirection: value.trim().startsWith('+') ? TextDirection.ltr : TextDirection.rtl,
              child: Text(
                value,
                textAlign: TextAlign.start,
                softWrap: true,
                style: const TextStyle(fontWeight: FontWeight.bold, height: 1.45),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
