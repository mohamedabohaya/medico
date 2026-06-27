import 'package:flutter/material.dart';

import 'doctor_screen.dart';

class ClinicScreen extends StatefulWidget {
  final String serviceType; // clinic | home | phone

  const ClinicScreen({
    super.key,
    this.serviceType = 'clinic',
  });

  @override
  State<ClinicScreen> createState() => _ClinicScreenState();
}

class _ClinicScreenState extends State<ClinicScreen> {
  final TextEditingController searchController = TextEditingController();

  final List<Map<String, dynamic>> allSpecialties = [
    {"name": "جلدية", "icon": Icons.face},
    {"name": "أسنان", "icon": Icons.medical_services},
    {"name": "نفسي", "icon": Icons.psychology},
    {"name": "أطفال", "icon": Icons.child_care},
    {"name": "مخ وأعصاب", "icon": Icons.memory},
    {"name": "عظام", "icon": Icons.accessibility_new},
    {"name": "نساء وولادة", "icon": Icons.pregnant_woman},
    {"name": "أنف وأذن وحنجرة", "icon": Icons.hearing},
    {"name": "قلب وأوعية دموية", "icon": Icons.favorite},
    {"name": "باطنة", "icon": Icons.sick},
  ];

  List<Map<String, dynamic>> filtered = [];

  @override
  void initState() {
    super.initState();
    filtered = allSpecialties;
  }

  String get title {
    if (widget.serviceType == 'home') return 'اختر تخصص الزيارة المنزلية';
    if (widget.serviceType == 'phone') return 'اختر تخصص المكالمة';
    return 'اختر التخصص';
  }

  void search(String value) {
    setState(() {
      filtered = allSpecialties.where((item) {
        return item["name"].toString().toLowerCase().contains(value.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        body: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.blue,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    Text(
                      title,
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    const SizedBox(width: 24),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TextField(
                    controller: searchController,
                    onChanged: search,
                    decoration: const InputDecoration(
                      hintText: "ابحث عن تخصص",
                      border: InputBorder.none,
                      icon: Icon(Icons.search),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    "التخصصات الأكثر اختياراً",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DoctorsScreen(
                              specialty: item["name"].toString(),
                              serviceType: widget.serviceType,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(item["icon"] as IconData, color: Colors.blue),
                            const SizedBox(width: 12),
                            Text(item["name"].toString(), style: const TextStyle(fontSize: 14)),
                            const Spacer(),
                            const Icon(Icons.arrow_forward_ios, size: 14),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
