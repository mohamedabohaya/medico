import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'ask_screen.dart';
import 'clinic_screen.dart';
import 'db_helper.dart';
import 'firebase_service.dart';
import 'doctor_details_screen.dart';
import 'app_image_helper.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  Map<String, double> ratings = {};

  final doctors = [];

  @override
  void initState() {
    super.initState();
    loadRatings();
  }

  void loadRatings() async {
    for (var doc in doctors) {
      double r = await DBHelper.getDoctorRating(doc["name"] as String);
      ratings[doc["name"] as String] = r;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,

        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                const SizedBox(height: 20),

                /// 🟦 Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: EdgeInsetsDirectional.only(start: 15),
                      child: const Text(
                        "MidGo",
                        style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold,color: Color(0xff0070d2)),
                      ),
                    ),

                  ],
                ),

                const SizedBox(height: 10),

                /// 🧱 Categories
                Row(
                  children: [
                    categoryItem(
                      image: 'assets/images/clinc4.jpg',
                      title: "زيارة العيادة",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ClinicScreen(serviceType: 'clinic')),
                        );
                      },
                    ),
                    categoryItem(
                      image: 'assets/images/clinc2.jpg',
                      title: "مكالمة دكتور",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ClinicScreen(serviceType: 'phone')),
                        );
                      },),
                    categoryItem(
                      image: 'assets/images/clinc3.jpg',
                        title: "رعاية منزلية",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ClinicScreen(serviceType: 'home')),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                /// 💬 Ask Question Section
                askDoctorCard(),

                const SizedBox(height: 25),

                const BookClinicSection(),

                const SizedBox(height: 25),

                const Text(
                  "أفضل الأطباء",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 15),

                Expanded(
                  child: StreamBuilder(
                    stream: FirebaseService.approvedDoctors(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final allDocs = [...snapshot.data!.docs];
                      allDocs.sort((a, b) => (((b.data()['ratingAvg'] ?? 0) as num).compareTo((a.data()['ratingAvg'] ?? 0) as num)));
                      final seenSpecialties = <String>{};
                      final doctors = <QueryDocumentSnapshot<Map<String, dynamic>>>[];

                      for (final d in allDocs) {
                        final data = d.data();
                        final specialty = (data['mainSpecialty'] ?? 'تخصص عام').toString();
                        if (!seenSpecialties.contains(specialty)) {
                          seenSpecialties.add(specialty);
                          doctors.add(d);
                        }
                      }

                      return ListView.builder(
                        itemCount: doctors.length,
                        itemBuilder: (context, index) {
                          final doc = doctors[index].data();

                          final data = {'id': doctors[index].id, ...doc};
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DoctorDetailsScreen(
                                    doctor: data,
                                    serviceType: 'clinic',
                                  ),
                                ),
                              );
                            },
                            child: doctorCard(
                              name: doc["name"] ?? "دكتور",
                              specialty: doc["mainSpecialty"] ?? "تخصص عام",
                              rating: ((doc["ratingAvg"] ?? 0) as num).toDouble(),
                              visitorsCount: ((doc["visitorsCount"] ?? 0) as num).toInt(),
                              image: doc["personalImage"]?.toString() ?? '',
                            ),
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

  /// 🔹 Ask Doctor Card (🔥 الجديد)
  Widget askDoctorCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AskDoctorScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.05),
              blurRadius: 10,
            )
          ],
        ),
        child: Row(
          children: [

            /// 📄 النص
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "هل لديك سؤال طبي؟",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    "اسأل دكتور مجاناً وسيتم الرد خلال 24 ساعة",
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),

            /// 💬 أيقونة
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chat, color: Colors.blue),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔹 Category
  Widget categoryItem({
    required String image,
    required String title,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Image.asset(image,width: 80,height: 80,),
              const SizedBox(height: 5),
              Text(title, textAlign: TextAlign.center,style: TextStyle(fontWeight: FontWeight.w700),),
            ],
          ),
        ),
      ),
    );
  }
  /// 🔹 Doctor Card
  Widget doctorCard({
    required String name,
    required String specialty,
    required double rating,
    int visitorsCount = 0,
    String image = '',
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [

          /// 👤 صورة يمين
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.blue.shade100,
            backgroundImage: AppImageHelper.provider(image),
            child: AppImageHelper.provider(image) == null
                ? const Icon(Icons.person, color: Colors.blue)
                : null,
          ),

          const SizedBox(width: 12),

          /// 📄 معلومات
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Text(specialty, style: const TextStyle(color: Colors.grey)),
            ],
          ),

          const Spacer(),

          /// ⭐ تقييم
          Row(
            children: [
              const Icon(Icons.star, color: Colors.orange, size: 18),
              const SizedBox(width: 4),
              Text(rating == 0 ? "-  ·  $visitorsCount زائر" : "${rating.toStringAsFixed(1)}  ·  $visitorsCount زائر"),
            ],
          ),
        ],
      ),
    );
  }
}


class BookClinicSection extends StatelessWidget {
  const BookClinicSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 18, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Align(
              alignment: Alignment.centerRight,
              child: Text(
                'احجز كشف عيادة',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff4A4A4A),
                ),
              ),
            ),

            const SizedBox(height: 12),
            GestureDetector(
              onTap: (){
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ClinicScreen(serviceType: 'clinic')),
                );
              },
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: Color(0xffDDE1E6),
                    width: 1.6,
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.search,
                      size: 18,
                      color: Color(0xff555555),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'ابحث بالتخصص، اسم الدكتور، أو المستشفى',
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xffA5A5A5),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}