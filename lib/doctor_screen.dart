import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'doctor_details_screen.dart';
import 'firebase_service.dart';
import 'app_image_helper.dart';

class DoctorsScreen extends StatefulWidget {
  final String specialty;
  final String serviceType; // clinic | home | phone

  const DoctorsScreen({
    super.key,
    required this.specialty,
    this.serviceType = 'clinic',
  });

  @override
  State<DoctorsScreen> createState() => _DoctorsScreenState();
}

class _DoctorsScreenState extends State<DoctorsScreen> {
  final TextEditingController search = TextEditingController();
  final Set<String> selectedFilters = {};
  String searchText = '';

  String get serviceTitle {
    if (widget.serviceType == 'home') return 'زيارة منزلية';
    if (widget.serviceType == 'phone') return 'مكالمة دكتور';
    return 'زيارة العيادة';
  }

  IconData get serviceIcon {
    if (widget.serviceType == 'home') return Icons.home;
    if (widget.serviceType == 'phone') return Icons.phone_in_talk;
    return Icons.local_hospital;
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseService.doctorsByServiceAndSpecialty(
      serviceType: widget.serviceType,
      specialty: widget.specialty,
    );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          centerTitle: true,
          title: Text('${widget.specialty} - $serviceTitle'),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: TextField(
                controller: search,
                onChanged: (v) => setState(() => searchText = v.trim()),
                decoration: InputDecoration(
                  hintText: 'ابحث باسم الدكتور',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: filtersSelector(),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: stream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  var docs = snapshot.data?.docs ?? [];
                  var doctors = docs.map((d) => {'id': d.id, ...d.data()}).where((d) {
                    if (searchText.isEmpty) return true;
                    final name = (d['name'] ?? d['fullName'] ?? '').toString();
                    return name.contains(searchText);
                  }).toList();

                  doctors.sort((a, b) {
                    num parseNum(dynamic v) => num.tryParse(v?.toString() ?? '') ?? 0;

                    int compareBy(String filter) {
                      if (filter == 'price_low') return parseNum(FirebaseService.servicePrice(a, widget.serviceType)).compareTo(parseNum(FirebaseService.servicePrice(b, widget.serviceType)));
                      if (filter == 'price_high') return parseNum(FirebaseService.servicePrice(b, widget.serviceType)).compareTo(parseNum(FirebaseService.servicePrice(a, widget.serviceType)));
                      if (filter == 'waiting_low') return parseNum(a['waitingTime']).compareTo(parseNum(b['waitingTime']));
                      if (filter == 'rating') return ((b['ratingAvg'] ?? 0) as num).compareTo((a['ratingAvg'] ?? 0) as num);
                      return 0;
                    }

                    final order = selectedFilters.isEmpty
                        ? ['rating']
                        : ['rating', 'price_low', 'price_high', 'waiting_low'].where(selectedFilters.contains).toList();

                    for (final f in order) {
                      final r = compareBy(f);
                      if (r != 0) return r;
                    }
                    return 0;
                  });

                  if (doctors.isEmpty) {
                    return Center(
                      child: Text(
                        'لا يوجد أطباء متاحين في هذا التخصص حالياً',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: doctors.length,
                    itemBuilder: (context, index) {
                      final d = doctors[index];
                      return doctorCard(d);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget filtersSelector() {
    final filters = {
      'rating': 'الأكثر تقييماً',
      'price_low': 'الأقل سعراً',
      'price_high': 'الأعلى سعراً',
      'waiting_low': 'أقل مدة انتظار',
    };

    final selectedText = selectedFilters.isEmpty
        ? ''
        : filters.entries.where((e) => selectedFilters.contains(e.key)).map((e) => e.value).join('، ');

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        builder: (_) => Directionality(
          textDirection: TextDirection.rtl,
          child: StatefulBuilder(
            builder: (context, setSheet) => Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('فلاتر', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ...filters.entries.map((e) {
                    return CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(e.value),
                      value: selectedFilters.contains(e.key),
                      onChanged: (v) {
                        setSheet(() {
                          if (v == true) {
                            selectedFilters.add(e.key);
                          } else {
                            selectedFilters.remove(e.key);
                          }
                        });
                        setState(() {});
                      },
                    );
                  }),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('تطبيق'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            const Icon(Icons.filter_list, color: Colors.blue),
            const SizedBox(width: 8),
            const Text('فلاتر', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Expanded(child: Text(selectedText, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade600))),
            const Icon(Icons.keyboard_arrow_down),
          ],
        ),
      ),
    );
  }

  Widget doctorCard(Map<String, dynamic> doctor) {
    final name = (doctor['name'] ?? doctor['fullName'] ?? 'دكتور').toString();
    final specialty = (doctor['mainSpecialty'] ?? widget.specialty).toString();
    final sub = (doctor['subSpecialties'] ?? '').toString();
    final location = (doctor['fullAddress'] ?? doctor['address'] ?? 'لم يتم تحديد العنوان').toString();
    final img = (doctor['personalImage'] ?? '').toString();
    final rating = ((doctor['ratingAvg'] ?? 0) as num).toDouble();
    final ratingCount = ((doctor['ratingCount'] ?? 0) as num).toInt();
    final visitors = ((doctor['visitorsCount'] ?? 0) as num).toInt();
    final price = FirebaseService.servicePrice(doctor, widget.serviceType);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DoctorDetailsScreen(
              doctor: doctor,
              serviceType: widget.serviceType,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.25),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.blue.shade100,
                    backgroundImage: AppImageHelper.provider(img),
                    child: AppImageHelper.provider(img) == null ? const Icon(Icons.person, color: Colors.blue, size: 34) : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                      const SizedBox(height: 4),
                      Text(specialty, style: const TextStyle(color: Colors.black54)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.orange, size: 18),
                          const SizedBox(width: 4),
                          Text(rating == 0 ? '-  ·  $visitors زائر' : '${rating.toStringAsFixed(1)}  ·  $visitors زائر'),
                        ],
                      ),
                    ]),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(children: [
                info(Icons.medical_services, sub.isEmpty ? 'لا توجد تخصصات فرعية' : sub),
                const SizedBox(height: 8),
                if (widget.serviceType == 'clinic') ...[
                  info(Icons.location_on, location),
                  const SizedBox(height: 8),
                ],
                info(Icons.payments, '$price شيكل'),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => DoctorDetailsScreen(doctor: doctor, serviceType: widget.serviceType)),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('احجز', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget info(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue, size: 18),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
      ],
    );
  }
}
