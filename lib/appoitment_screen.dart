import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'firebase_service.dart';
import 'session_manager.dart';
import 'patient_booking_details_screen.dart';
import 'doctor_details_screen.dart';
import 'phoneConsaltent.dart';
import 'patient_question_details_screen.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  String? patientPhone;

  @override
  void initState() {
    super.initState();
    loadPhone();
  }

  Future<void> loadPhone() async {
    patientPhone = await SessionManager.getLoggedInPhone();
    if (mounted) setState(() {});
  }

  Future<void> cancelAppointment(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text("تأكيد"),
          content: const Text("هل تريد إلغاء الحجز؟"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("لا")),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("نعم")),
          ],
        ),
      ),
    );

    if (ok == true) {
      await FirebaseService.cancelAppointment(id);
    }
  }


  Future<void> rebookAppointment(Map<String, dynamic> item) async {
    final doctorId = item['doctorId']?.toString() ?? '';
    Map<String, dynamic>? doctor = doctorId.isEmpty ? null : await FirebaseService.getDoctorById(doctorId);
    doctor ??= {
      'id': doctorId,
      'doctorId': doctorId,
      'name': item['doctorName'] ?? item['doctor'],
      'mainSpecialty': item['doctorSpecialty'] ?? item['specialty'],
      'personalImage': item['doctorImage'] ?? '',
      'clinicVisitPrice': item['price'],
      'homeVisitPrice': item['price'],
      'phonePrice': item['price'],
      'price': item['price'],
      'fullAddress': item['location'] ?? '',
    };
    final type = item['serviceType']?.toString() ?? 'clinic';
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DoctorDetailsScreen(doctor: doctor!, serviceType: type),
      ),
    );
  }

  Future<void> rateAppointment(Map<String, dynamic> item, int rating) async {
    final appointmentId = item['id']?.toString() ?? '';
    final doctorId = item['doctorId']?.toString() ?? '';
    if (appointmentId.isEmpty || doctorId.isEmpty) return;

    await FirebaseService.addAppointmentRating(
      appointmentId: appointmentId,
      doctorId: doctorId,
      rating: rating,
      doctorName: item['doctorName']?.toString(),
      patientPhone: patientPhone,
    );

    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال التقييم')));
  }

  Future<List<Map<String, dynamic>>> loadQuestionsOnce() async {
    if (patientPhone == null || patientPhone!.isEmpty) return [];
    final snap = await FirebaseService.firestore
        .collection('questions')
        .where('patientPhone', isEqualTo: FirebaseService.normalizePhone(patientPhone!))
        .get();
    return snap.docs.map((d) => {'id': d.id, ...d.data(), 'recordType': 'question'}).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (patientPhone == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                const SizedBox(height: 20),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    "معاملاتي",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseService.patientAppointments(patientPhone!),
                    builder: (context, appointmentSnap) {
                      if (appointmentSnap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirebaseService.patientQuestions(patientPhone!),
                        builder: (context, questionSnap) {
                          final appointments = (appointmentSnap.data?.docs ?? [])
                              .map((d) => {'id': d.id, ...d.data(), 'recordType': 'appointment'})
                              .toList();

                          final questions = (questionSnap.data?.docs ?? [])
                              .map((d) => {'id': d.id, ...d.data(), 'recordType': 'question'})
                              .toList();
                          final items = [...appointments, ...questions];

                          items.sort((a, b) {
                            final at = a['createdAt'];
                            final bt = b['createdAt'];
                            if (at is Timestamp && bt is Timestamp) {
                              return bt.compareTo(at);
                            }
                            return 0;
                          });

                          if (items.isEmpty) {
                            return emptyHint('لا توجد معاملات أو حجوزات حتى الآن');
                          }

                          return ListView.builder(
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final item = items[index];
                              if (item['recordType'] == 'question') {
                                return questionCard(item);
                              }
                              return GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => PatientBookingDetailsScreen(item: item)),
                                ),
                                child: appointmentCard(item),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget appointmentCard(Map<String, dynamic> item) {
    final status = item['status']?.toString() ?? 'booked';
    final type = item['serviceType']?.toString() ?? 'clinic';
    final rated = item['rated'] == true || (item['rating'] ?? 0) != 0;
    final rating = ((item['rating'] ?? 0) as num).toInt();
    final doctorName = item['doctorName']?.toString() ?? 'دكتور';
    final specialty = item['doctorSpecialty']?.toString() ?? 'تخصص عام';
    final appointmentDate = item['appointmentDate']?.toString() ?? displayCreatedDate(item);
    final appointmentTime = item['date']?.toString() ?? 'لم يحدد';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PatientBookingDetailsScreen(item: item)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black12.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  statusWidget(status),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${serviceTitle(type)} $appointmentDate ${appointmentTime.replaceAll('من', '-').replaceAll('إلى', '-')}',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: status == 'cancelled' ? Colors.red : Colors.grey.shade800, fontWeight: FontWeight.w600),
                    ),
                  ),
                  serviceIcon(type),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.blue.shade100,
                    child: const Icon(Icons.person, color: Colors.blue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(doctorName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      Text(specialty, style: const TextStyle(color: Colors.grey, fontSize: 16)),
                    ]),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Row(
                children: [
                  if (status == 'done') ...[
                    Expanded(
                      child: GestureDetector(
                        onTap: () => rebookAppointment(item),
                        child: button('احجز مرة أخرى', Colors.blue.shade50, Colors.blue),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: GestureDetector(
                      onTap: status == 'booked'
                          ? () => cancelAppointment(item['id'].toString())
                          : () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => PatientBookingDetailsScreen(item: item)),
                              ),
                      child: button(
                        status == 'booked' ? 'إلغاء' : 'عرض التفاصيل',
                        status == 'booked' ? Colors.red.shade50 : Colors.grey.shade100,
                        status == 'booked' ? Colors.red : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (status == 'done')
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: rated
                    ? Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(rating, (i) => const Icon(Icons.star, color: Colors.orange)))
                    : Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
                        child: Column(children: [
                          const Text('قيّم تجربتك مع الطبيب'),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (i) => GestureDetector(
                              onTap: () => rateAppointment(item, i + 1),
                              child: const Icon(Icons.star_border, color: Colors.orange, size: 30),
                            )),
                          ),
                        ]),
                      ),
              ),
          ],
        ),
      ),
    );
  }

  Widget questionCard(Map<String, dynamic> item) {
    final status = item['status']?.toString() ?? 'waiting';
    final answer = item['answer']?.toString() ?? '';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PatientQuestionDetailsScreen(item: item)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          children: [
            const Icon(Icons.question_answer, color: Colors.blue),
            const SizedBox(width: 8),
            Expanded(child: Text(item['title']?.toString() ?? item['question']?.toString() ?? 'سؤال طبي', style: const TextStyle(fontWeight: FontWeight.bold))),
            status == 'answered'
                ? const Icon(Icons.check_circle, color: Colors.green)
                : const Text('بانتظار الرد', style: TextStyle(color: Colors.orange)),
          ],
        ),
        const SizedBox(height: 8),
        Text("التخصص: ${item['specialty'] ?? ''}", style: TextStyle(color: Colors.grey.shade600)),
        const SizedBox(height: 8),
        Text(item['description']?.toString() ?? item['text']?.toString() ?? ''),
        if (answer.isNotEmpty) ...[
          const Divider(height: 24),
          Text("تم الرد على السؤال", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
          const SizedBox(height: 6),
          Text(
            answer,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(height: 1.5),
          ),
          const SizedBox(height: 6),
          const Text('اضغط لعرض التفاصيل كاملة', style: TextStyle(color: Colors.blue, fontSize: 12)),
        ],
      ]),
      ),
    );
  }

  String displayCreatedDate(Map<String, dynamic> item) {
    final created = item['createdAt'];
    DateTime d = DateTime.now();
    if (created is Timestamp) d = created.toDate();
    return '${d.day}/${d.month}/${d.year}';
  }

  Widget statusWidget(String status) {
    if (status == "done") {
      return const Row(children: [Icon(Icons.check_circle, color: Colors.green, size: 18), SizedBox(width: 4), Text("مكتمل", style: TextStyle(color: Colors.green))]);
    }
    if (status == "cancelled") {
      return const Text("تم الإلغاء", style: TextStyle(color: Colors.red));
    }
    return const Text("جاري", style: TextStyle(color: Colors.orange));
  }

  Widget serviceIcon(String type) {
    if (type == 'phone') return const Icon(Icons.phone_in_talk, color: Colors.green);
    if (type == 'home') return const Icon(Icons.home, color: Colors.deepPurple);
    return const Icon(Icons.local_hospital, color: Colors.blue);
  }

  String serviceTitle(String type) {
    if (type == 'phone') return 'مكالمة دكتور';
    if (type == 'home') return 'زيارة منزلية';
    return 'زيارة عيادة';
  }

  Widget emptyHint(String text) => Center(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Text(text, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
        ),
      );

  Widget button(String text, Color bg, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Center(
        child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
