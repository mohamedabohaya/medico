import 'package:flutter/material.dart';

import 'confirm_screen.dart';
import 'firebase_service.dart';
import 'phoneConsaltent.dart';
import 'app_image_helper.dart';

class DoctorDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> doctor;
  final String serviceType; // clinic | home | phone

  const DoctorDetailsScreen({
    super.key,
    required this.doctor,
    this.serviceType = 'clinic',
  });

  @override
  State<DoctorDetailsScreen> createState() => _DoctorDetailsScreenState();
}

class _DoctorDetailsScreenState extends State<DoctorDetailsScreen> {
  int selectedSlot = 0;

  String get name => (widget.doctor['name'] ?? widget.doctor['fullName'] ?? 'دكتور').toString();
  String get mainSpecialty => (widget.doctor['mainSpecialty'] ?? 'تخصص عام').toString();
  String get subSpecialties => (widget.doctor['subSpecialties'] ?? '').toString();
  String get about => (widget.doctor['about'] ?? 'لا توجد نبذة مضافة عن الدكتور.').toString();
  String get address => (widget.doctor['fullAddress'] ?? widget.doctor['address'] ?? 'لم يتم تحديد العنوان').toString();
  String get price => FirebaseService.servicePrice(widget.doctor, widget.serviceType);
  double get ratingAvg => ((widget.doctor['ratingAvg'] ?? 0) as num).toDouble();
  int get ratingCount => ((widget.doctor['ratingCount'] ?? 0) as num).toInt();
  int get visitorsCount => ((widget.doctor['visitorsCount'] ?? 0) as num).toInt();
  String get waitingTime => (widget.doctor['waitingTime'] ?? 'غير محدد').toString();
  String get clinicName => (widget.doctor['clinicName'] ?? '').toString();
  String get personalImage => (widget.doctor['personalImage'] ?? '').toString();

  List<Map<String, String>> get availableTimes {
    final raw = widget.doctor['availableTimes'];
    if (raw is List && raw.isNotEmpty) {
      return raw.map((e) {
        final m = e as Map;
        return {
          'day': (m['day'] ?? 'اليوم').toString(),
          'from': (m['from'] ?? '').toString(),
          'to': (m['to'] ?? '').toString(),
        };
      }).toList();
    }
    return [
      {'day': 'اليوم', 'from': 'لا يوجد', 'to': 'مواعيد'},
      {'day': 'غداً', 'from': '5:00 م', 'to': '8:30 م'},
      {'day': 'الجمعة', 'from': 'لا يوجد', 'to': 'مواعيد'},
    ];
  }

  Map<String, String> get selectedTime => availableTimes[selectedSlot < 0 ? 0 : (selectedSlot >= availableTimes.length ? availableTimes.length - 1 : selectedSlot)];

  String get serviceTitle {
    if (widget.serviceType == 'home') return 'زيارة منزلية';
    if (widget.serviceType == 'phone') return 'مكالمة هاتفية';
    return 'زيارة عيادة';
  }

  @override
  Widget build(BuildContext context) {
    final rating = widget.doctor['ratingAvg'] is num ? (widget.doctor['ratingAvg'] as num).toDouble() : 0.0;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          title: const Text("بيانات الدكتور"),
          centerTitle: true,
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: box(),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.blue.shade100,
                      backgroundImage: AppImageHelper.provider(personalImage),
                      child: AppImageHelper.provider(personalImage) == null ? const Icon(Icons.person, color: Colors.blue) : null,
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.orange, size: 18),
                            const SizedBox(width: 4),
                            Text(rating == 0 ? '-' : rating.toStringAsFixed(1)),
                            const SizedBox(width: 6),
                            Text("($visitorsCount زائر)"),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          mainSpecialty,
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(serviceTitle, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                        ),
                      ]),
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
                    rowItem(Icons.medical_services, clinicName.isEmpty ? mainSpecialty : clinicName),
                    if (widget.serviceType == 'clinic') ...[
                      const SizedBox(height: 10),
                      rowItem(Icons.location_on, address),
                    ],
                    const SizedBox(height: 10),
                    rowItem(Icons.attach_money, "سعر الكشف: $price شيكل"),
                    const SizedBox(height: 10),
                    if(widget.serviceType=="clinic") rowItem(Icons.watch_later, "مدة الانتظار $waitingTime دقيقة"),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: box(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("اختر ميعاد حجزك", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      children: List.generate(availableTimes.length, (index) {
                        final t = availableTimes[index];
                        final selected = selectedSlot == index;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => selectedSlot = index),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: selected ? Colors.blue : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: selected ? Colors.blue : Colors.grey.shade300),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    t['day'] ?? '',
                                    style: TextStyle(
                                      color: selected ? Colors.white : Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${t['from']} - ${t['to']}',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: selected ? Colors.white : Colors.grey.shade700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: box(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("عن الدكتور", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                    const SizedBox(height: 8),
                    Text(about, style: const TextStyle(height: 1.6)),
                  ],
                ),
              ),


              if (subSpecialties.trim().isNotEmpty) ...[
                const SizedBox(height: 15),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: box(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("التخصصات الفرعية", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: subSpecialties
                            .split(RegExp(r'[,،\\n]'))
                            .map((e) => e.trim())
                            .where((e) => e.isNotEmpty)
                            .map((e) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(e, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600)),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ],
              clinicImagesSection(),
              const SizedBox(height: 15),
              answeredQuestionsSection(),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    if (widget.serviceType == 'phone') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PhoneConsultationPage(
                            doctor: widget.doctor,
                            selectedTime: selectedTime,
                          ),
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ConfirmBookingScreen(
                            doctor: widget.doctor,
                            serviceType: widget.serviceType,
                            selectedTime: selectedTime,
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("احجز الآن", style: TextStyle(color: Colors.white, fontSize: 17)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  Widget clinicImagesSection() {
    final raw = widget.doctor['clinicImages'];
    if (raw is! List || raw.isEmpty) return const SizedBox();
    final images = raw.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
    if (images.isEmpty) return const SizedBox();
    return Column(
      children: [
        const SizedBox(height: 15),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: box(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("صور العيادة", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
              const SizedBox(height: 10),
              SizedBox(
                height: 105,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: images.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final img = images[i];
                    return GestureDetector(
                      onTap: () => AppImageHelper.showPreview(context, img),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: SizedBox(width: 105, height: 105, child: AppImageHelper.image(img, fit: BoxFit.cover)),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget answeredQuestionsSection() {
    final id = (widget.doctor['id'] ?? widget.doctor['doctorId'] ?? '').toString();
    if (id.isEmpty) return const SizedBox();

    return StreamBuilder(
      stream: FirebaseService.answeredQuestionsForDoctor(id),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const SizedBox();

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: box(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('أسئلة أجاب عنها الدكتور', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
              const SizedBox(height: 10),
              ...docs.map((d) {
                final q = d.data() as Map<String, dynamic>;
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(q['question']?.toString() ?? q['title']?.toString() ?? 'سؤال طبي', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(q['answer']?.toString() ?? '', style: const TextStyle(height: 1.5)),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  BoxDecoration box() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    );
  }

  Widget rowItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 15))),
      ],
    );
  }
}
