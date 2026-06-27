import 'package:flutter/material.dart';
import 'firebase_service.dart';

class PatientBookingDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> item;
  const PatientBookingDetailsScreen({super.key, required this.item});

  String get type => item['serviceType']?.toString() ?? 'clinic';
  String get status => item['status']?.toString() ?? 'booked';

  String serviceTitle() {
    if (type == 'phone') return 'مكالمة هاتفية';
    if (type == 'home') return 'زيارة منزلية';
    return 'زيارة عيادة';
  }

  String statusText() {
    if (status == 'done') return 'مكتمل';
    if (status == 'cancelled') return 'ملغي';
    return 'جاري';
  }

  Color statusColor() {
    if (status == 'done') return Colors.green;
    if (status == 'cancelled') return Colors.red;
    return Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xffF4F6F9),
        appBar: AppBar(
          title: const Text('تفاصيل المعاملة'),
          centerTitle: true,
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: box(),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.blue.shade50,
                    child: const Icon(Icons.person, color: Colors.blue, size: 34),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(item['doctorName']?.toString() ?? 'دكتور', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      Text(item['doctorSpecialty']?.toString() ?? 'تخصص عام', style: TextStyle(color: Colors.grey.shade600)),
                    ]),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: statusColor().withOpacity(.12), borderRadius: BorderRadius.circular(20)),
                    child: Text(statusText(), style: TextStyle(color: statusColor(), fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: box(),
              child: Column(children: [
                row(Icons.date_range, 'تاريخ الحجز', item['appointmentDate']?.toString() ?? 'غير محدد'),
                row(Icons.calendar_today, 'موعد الحجز', item['date']?.toString() ?? 'غير محدد'),
                row(Icons.payments, 'سعر الكشف', formatAmount(item['finalAmount'] ?? item['price'])),
                if (type == 'phone')
                  row(Icons.phone, 'نوع العملية', 'مكالمة هاتفية')
                else if (type == 'home' && (item['patientAddress'] ?? '').toString().isNotEmpty)
                  row(Icons.home, 'عنوان المريض', item['patientAddress'].toString())
                else if (type == 'clinic' && (item['location'] ?? '').toString().isNotEmpty)
                  row(Icons.location_on, 'عنوان العيادة', item['location'].toString()),
              ]),
            ),
            const SizedBox(height: 14),
            if (status == 'booked')
              SizedBox(
                height: 50,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
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
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  icon: const Icon(Icons.cancel),
                  label: const Text('إلغاء الحجز'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  BoxDecoration box() => BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18));

  String formatAmount(dynamic value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) return 'غير محدد';
    final cleaned = text.replaceAll('جنيه', '').replaceAll('شيكل', '').trim();
    return '$cleaned شيكل';
  }

  Widget row(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue, size: 21),
          const SizedBox(width: 8),
          SizedBox(
            width: 95,
            child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 6),
          Expanded(child: Directionality(textDirection: value.trim().startsWith('+') ? TextDirection.ltr : TextDirection.rtl, child: Text(value, textAlign: TextAlign.start, style: const TextStyle(height: 1.4)))),
        ],
      ),
    );
  }
}
