import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hospital/main.dart';
import 'doctor_profile_setup_screen.dart';
import 'firebase_service.dart';
import 'session_manager.dart';
import 'login_screen.dart';
import 'app_image_helper.dart';
import 'doctor_appointment_details_screen.dart';

class DoctorDashboardScreen extends StatefulWidget {
  final String? doctorRequestId;
  final String? phone;

  const DoctorDashboardScreen({
    super.key,
    this.doctorRequestId,
    this.phone,
  });

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  int currentIndex = 0;
  Map<String, dynamic>? profile;
  bool loading = true;
  String transactionFilter = '3';

  String get doctorId => profile?['id']?.toString() ?? '';
  String get doctorName => profile?['name']?.toString() ?? 'الطبيب';

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    setState(() => loading = true);
    final data = await FirebaseService.getDoctorProfile(
      doctorRequestId: widget.doctorRequestId,
      phone: widget.phone,
    );

    if (!mounted) return;
    setState(() {
      profile = data;
      loading = false;
    });
  }

  Future<void> logoutDoctor() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تسجيل الخروج'),
          content: const Text('هل تريد تسجيل الخروج من حساب الطبيب؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: (){
                Navigator.pop(context, true);

            },
              child: const Text('تسجيل خروج', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (confirm != true) return;

    await SessionManager.logoutDoctor();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => HomeScreen(),
      ),
    );

  }

  @override
  Widget build(BuildContext context) {
    final titles = ['الرئيسية', 'معاملاتي', 'بياناتي'];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xffF4F6F9),
        appBar: AppBar(
          backgroundColor: Colors.blue,
          centerTitle: true,
          title: Text(titles[currentIndex], style: const TextStyle(color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : profile == null
                ? missingProfile()
                : IndexedStack(
                    index: currentIndex,
                    children: [
                      homePage(),
                      transactionsPage(),
                      myDataPage(),
                    ],
                  ),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: Colors.white,
          currentIndex: currentIndex,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          onTap: (i) => setState(() => currentIndex = i),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'الصفحة الرئيسية'),
            BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'معاملاتي'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'بياناتي'),
          ],
        ),
      ),
    );
  }

  Widget missingProfile() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.info, color: Colors.blue, size: 70),
            const SizedBox(height: 16),
            const Text(
              'لم يتم استكمال بيانات الطبيب بعد',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DoctorProfileSetupScreen(
                      doctorRequestId: widget.doctorRequestId,
                      phone: widget.phone,
                    ),
                  ),
                );
              },
              child: const Text('استكمال البيانات'),
            ),
          ],
        ),
      ),
    );
  }

  Widget homePage() {
    return RefreshIndicator(
      onRefresh: loadProfile,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          headerCard(),
          const SizedBox(height: 14),
          bookingsCountCard(),
          const SizedBox(height: 14),
          sectionTitle('أحدث 5 حجوزات'),
          const SizedBox(height: 10),
          appointmentsList(limit: 5),
          const SizedBox(height: 18),
          sectionTitle('أسئلة المرضى'),
          const SizedBox(height: 10),
          questionsList(),
        ],
      ),
    );
  }

  Widget headerCard() {
    final specialty = profile?['mainSpecialty']?.toString() ?? '';
    final img = profile?['personalImage']?.toString() ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.blue.shade50,
            backgroundImage: AppImageHelper.provider(img),
            child: AppImageHelper.provider(img) == null
                ? const Icon(Icons.person, color: Colors.blue, size: 38)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(doctorName, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(specialty.isEmpty ? 'طبيب' : specialty, style: TextStyle(color: Colors.grey.shade600)),
              
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('مفعل', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget bookingsCountCard() {
    final rating = ((profile?['ratingAvg'] ?? 0) as num).toDouble();
    if (doctorId.isEmpty) {
      return Row(children: [
        Expanded(child: statCard('عدد الحجوزات', '0', Icons.calendar_month)),
        const SizedBox(width: 10),
        Expanded(child: statCard('التقييم', rating == 0 ? '-' : rating.toStringAsFixed(1), Icons.star)),
      ]);
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseService.doctorAppointmentsById(doctorId),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        return Row(children: [
          Expanded(child: statCard('عدد الحجوزات', count.toString(), Icons.calendar_month)),
          const SizedBox(width: 10),
          Expanded(child: statCard('التقييم', rating == 0 ? '-' : rating.toStringAsFixed(1), Icons.star)),
        ]);
      },
    );
  }

  Widget statCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: Colors.blue),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Text(title, style: TextStyle(color: Colors.grey.shade600)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget appointmentsList({int? limit, DateTime? fromDate}) {
    if (doctorId.isEmpty) return emptyHint('لا توجد حجوزات حتى الآن');

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseService.doctorAppointmentsById(doctorId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return smallLoader();
        }

        var docs = snapshot.data?.docs ?? [];
        if (fromDate != null) {
          docs = docs.where((doc) {
            final created = doc.data()['createdAt'];
            return created is Timestamp ? created.toDate().isAfter(fromDate) : true;
          }).toList();
        }
        docs.sort((a,b){
          final at=a.data()['createdAt']; final bt=b.data()['createdAt'];
          if(at is Timestamp && bt is Timestamp) return bt.compareTo(at);
          return 0;
        });
        if (limit != null && docs.length > limit) docs = docs.take(limit).toList();
        if (docs.isEmpty) return emptyHint('ستظهر هنا حجوزات المرضى معك عند توفرها.');

        return Column(
          children: docs.map((d) {
            final data = d.data();
            return bookingCard({'id': d.id, ...data});
          }).toList(),
        );
      },
    );
  }

  Widget questionsList() {
    if (doctorId.isEmpty) return emptyHint('لا توجد أسئلة حالياً');

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseService.questionsForDoctor(
        doctorId: doctorId,
        specialty: profile?['mainSpecialty']?.toString(),
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return smallLoader();
        }

        final docs = (snapshot.data?.docs ?? []).where((d) {
          final data = d.data();
          final status = data['status']?.toString() ?? 'waiting';
          final answeredBy = data['doctorId']?.toString() ?? '';
          return status == 'waiting' || (status == 'answered' && answeredBy == doctorId);
        }).toList();

        if (docs.isEmpty) return emptyHint('لا توجد أسئلة حالياً.');

        return Column(
          children: docs.map((d) {
            final data = d.data();
            return questionCard(
              questionId: d.id,
              patientName: data['patientName']?.toString() ?? 'مريض',
              question: data['question']?.toString() ?? data['title']?.toString() ?? data['text']?.toString() ?? data['description']?.toString() ?? 'سؤال طبي',
              answer: data['answer']?.toString() ?? '',
              status: data['status']?.toString() ?? 'waiting',
              questionData: data,
            );
          }).toList(),
        );
      },
    );
  }

  Widget myDataPage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        headerCard(),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DoctorProfileSetupScreen(
                    doctorRequestId: widget.doctorRequestId,
                    phone: widget.phone,
                    existingProfile: profile,
                  ),
                ),
              );
              loadProfile();
            },
            icon: const Icon(Icons.edit, color: Colors.white),
            label: const Text('تعديل بياناتي', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 12),
        infoTile('اسم العيادة / المركز', profile?['clinicName']),
        infoTile('التخصص الرئيسي', profile?['mainSpecialty']),
        infoTile('التخصصات الفرعية', profile?['subSpecialties']),
        infoTile('سعر كشف زيارة العيادة', profile?['clinicVisitPrice'] ?? profile?['price']),
        infoTile('سعر مكالمة الدكتور', profile?['phonePrice']),
        infoTile('سعر الزيارة المنزلية', profile?['homeVisitPrice']),
        infoTile('رقم بنك فلسطين', profile?['bankPalestineNumber']),
        infoTile('رقم Jawwal Pay', profile?['jawwalPayNumber']),
        infoTile('مدة الانتظار', (profile?['waitingTime'] == null || profile!['waitingTime'].toString().isEmpty) ? null : '${profile?['waitingTime']} دقيقة'),
        infoTile('العنوان', profile?['fullAddress']),
        infoTile('نبذة عن الدكتور', profile?['about']),
        servicesTile(),
        timesTile(),
        imagesTile(),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: logoutDoctor,
            icon: const Icon(Icons.logout),
            label: const Text(
              'تسجيل خروج من حساب الطبيب',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],

    );
  }

  Widget servicesTile() {
    final services = <String>[];
    if (profile?['clinicVisit'] == true || profile?['clinicVisit'] == 1) services.add('زيارة عيادة');
    if (profile?['homeVisit'] == true || profile?['homeVisit'] == 1) services.add('زيارة منزلية');
    if (profile?['phoneCall'] == true || profile?['phoneCall'] == 1) services.add('مكالمة هاتفية');
    return infoTile('الخدمات المتاحة', services.isEmpty ? 'لا يوجد' : services.join(' - '));
  }

  Widget timesTile() {
    final times = profile?['availableTimes'];
    if (times is! List || times.isEmpty) return infoTile('مواعيد التوفر', 'لم يتم الإدخال');

    final value = times.map((e) {
      final m = e as Map;
      return '${m['day']} من ${m['from']} إلى ${m['to']}';
    }).join('\n');

    return infoTile('مواعيد التوفر', value);
  }

  Widget imagesTile() {
    final imgs = profile?['clinicImages'];
    if (imgs is! List || imgs.isEmpty) return infoTile('صور العيادة', 'لم يتم إضافة صور');

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('صور العيادة', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: imgs.map((e) => GestureDetector(
              onTap: () => AppImageHelper.showPreview(context, e.toString()),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(width: 86, height: 86, child: AppImageHelper.image(e.toString(), fit: BoxFit.cover)),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget sectionTitle(String title) => Text(
        title,
        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
      );

  Widget bookingCard(Map<String, dynamic> item) {
    final name = item['patientName']?.toString() ?? 'مريض';
    final type = item['serviceType']?.toString() ?? 'clinic';
    final time = item['date']?.toString() ?? item['time']?.toString() ?? 'لم يحدد';
    final apptDate = item['appointmentDate']?.toString() ?? '';
    final status = item['status']?.toString() ?? 'booked';
    final attachment = item['paymentAttachment']?.toString() ?? item['paymentImage']?.toString() ?? '';
    final attachmentType = item['paymentAttachmentType']?.toString() ?? '';
    final locationText = type == 'home'
        ? (item['patientAddress']?.toString() ?? '')
        : '';

    final icon = type == 'phone'
        ? Icons.phone_in_talk
        : type == 'home'
            ? Icons.home
            : Icons.local_hospital;
    final title = type == 'phone'
        ? 'مكالمة دكتور'
        : type == 'home'
            ? 'زيارة منزلية'
            : 'زيارة عيادة';

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DoctorAppointmentDetailsScreen(
            appointment: item,
            doctorProfile: profile,
          ),
        ),
      ),
      borderRadius: BorderRadius.circular(16),
      child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(backgroundColor: Colors.blue.shade50, child: Icon(icon, color: Colors.blue)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('$title • ${apptDate.isNotEmpty ? 'التاريخ: $apptDate • ' : ''}الموعد: $time', style: TextStyle(color: Colors.grey.shade600, height: 1.4)),
                  if (locationText.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('عنوان المريض: $locationText', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  ],
                ]),
              ),
              Text(
                status == 'done' ? 'مكتمل' : status == 'cancelled' ? 'ملغي' : 'جاري',
                style: TextStyle(
                  color: status == 'done' ? Colors.green : status == 'cancelled' ? Colors.red : Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (attachment.isNotEmpty) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => showDialog(
                context: context,
                builder: (_) => Dialog(
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: buildPaymentImage(attachment, attachmentType, fit: BoxFit.contain),
                      ),
                      Positioned(
                        top: 4,
                        left: 4,
                        child: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(width: 58, height: 58, child: buildPaymentImage(attachment, attachmentType, fit: BoxFit.cover)),
                  ),
                  const SizedBox(width: 10),
                  const Text('تم إرفاق صورة الدفع', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
          if (status == 'booked') ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => FirebaseService.markAppointmentDone(item['id'].toString()),
                icon: const Icon(Icons.check_circle, color: Colors.green),
                label: const Text('تمت الزيارة / الخدمة', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ],
      ),
    ));
  }


  Future<void> showBookingDetails(Map<String, dynamic> item) async {
    final patientPhone = item['patientPhone']?.toString() ?? '';
    final patient = await FirebaseService.getUserByPhone(patientPhone);
    if (!mounted) return;
    final type = item['serviceType']?.toString() ?? 'clinic';
    final attachment = item['paymentAttachment']?.toString() ?? item['paymentImage']?.toString() ?? '';
    final attachmentType = item['paymentAttachmentType']?.toString() ?? '';
    final locationText = type == 'home'
        ? (item['patientAddress']?.toString() ?? '')
        : '';
    showDialog(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تفاصيل حجز المريض'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                infoLine('اسم المريض', item['patientName'] ?? patient?['name']),
                infoLine('العمر', item['patientAge'] ?? calcAge(patient?['birthdate'])),
                infoLine('النوع', item['patientGender'] ?? patient?['gender']),
                infoLine('رقم الهاتف', formatPhoneForDisplay(patientPhone)),
                infoLine('نوع الحجز', type == 'phone' ? 'مكالمة دكتور' : type == 'home' ? 'زيارة منزلية' : 'زيارة عيادة'),
                infoLine('تاريخ الحجز', item['appointmentDate'] ?? 'غير محدد'),
                infoLine('موعد الحجز', item['date']),
                infoLine('سعر الكشف', formatAmount(item['price'] ?? FirebaseService.servicePrice(profile ?? {}, item['serviceType']?.toString() ?? 'clinic'))),
                if (type == 'home' && (item['patientAddress'] ?? '').toString().isNotEmpty) infoLine('عنوان المريض', item['patientAddress']),
                if (attachment.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Text('صورة التحويل', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => showDialog(
                      context: context,
                      builder: (_) => Dialog(
                        child: Stack(children: [
                          Padding(padding: const EdgeInsets.all(12), child: buildPaymentImage(attachment, attachmentType, fit: BoxFit.contain)),
                          Positioned(top: 4, left: 4, child: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))),
                        ]),
                      ),
                    ),
                    child: SizedBox(height: 110, width: double.infinity, child: buildPaymentImage(attachment, attachmentType, fit: BoxFit.contain)),
                  ),
                ]
              ],
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق'))],
        ),
      ),
    );
  }

  String formatAmount(dynamic value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) return 'غير متوفر';
    final cleaned = text.replaceAll('جنيه', '').replaceAll('شيكل', '').trim();
    return '$cleaned شيكل';
  }

  String formatPhoneForDisplay(String phone) => FirebaseService.formatPhoneForDisplay(phone);

  Widget infoLine(String title, dynamic value) {
    final text = value == null || value.toString().trim().isEmpty ? 'غير متوفر' : value.toString();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$title: ', style: const TextStyle(fontWeight: FontWeight.bold)),
        Expanded(child: Text(text)),
      ]),
    );
  }

  String calcAge(dynamic birthdate) {
    try {
      final d = DateTime.parse(birthdate.toString());
      final now = DateTime.now();
      var age = now.year - d.year;
      if (now.month < d.month || (now.month == d.month && now.day < d.day)) age--;
      return age.toString();
    } catch (_) { return ''; }
  }

  Widget transactionsPage() {
    final options = {
      'all': 'كل الحجوزات',
      '1': 'آخر شهر',
      '3': 'آخر 3 شهور',
      '6': 'آخر 6 شهور',
      '12': 'آخر سنة',
    };
    DateTime? from;
    if (transactionFilter != 'all') {
      final months = int.tryParse(transactionFilter) ?? 3;
      from = DateTime.now().subtract(Duration(days: months * 30));
    }
    return RefreshIndicator(
      onRefresh: loadProfile,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(children: [
            const Expanded(child: Text('معاملاتي', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
            DropdownButton<String>(
              value: transactionFilter,
              items: options.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
              onChanged: (v) => setState(() => transactionFilter = v ?? '3'),
            ),
          ]),
          const SizedBox(height: 12),
          appointmentsList(fromDate: from),
        ],
      ),
    );
  }

  Widget buildPaymentImage(String value, String type, {BoxFit fit = BoxFit.cover}) {
    return AppImageHelper.image(value, fit: fit);
  }

  Widget questionCard({
    required String questionId,
    required String patientName,
    required String question,
    String answer = '',
    String status = 'waiting',
    Map<String, dynamic>? questionData,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          children: [
            const Icon(Icons.question_answer, color: Colors.blue),
            const SizedBox(width: 8),
            Text(patientName, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        Text(question, style: const TextStyle(height: 1.5)),
        const SizedBox(height: 10),
        if (status == 'answered' && answer.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
            child: Text('إجابتك: $answer', style: const TextStyle(height: 1.5)),
          ),
        ] else
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton(
              onPressed: () => showAnswerDialog(questionId, questionData ?? {}),
              child: const Text('عرض التفاصيل والرد'),
            ),
          ),
      ]),
    );
  }

  Future<void> showAnswerDialog(String questionId, Map<String, dynamic> data) async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('تفاصيل السؤال والرد'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                infoLine('اسم المريض', data['patientName']),
                infoLine('التخصص', data['specialty']),
                infoLine('العمر', data['age']),
                infoLine('النوع', data['gender']),
                infoLine('عنوان السؤال', data['title'] ?? data['question']),
                infoLine('وصف الحالة', data['description'] ?? data['text']),
                const SizedBox(height: 10),
                TextField(
                  controller: controller,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'اكتب ردك هنا',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                if (controller.text.trim().isEmpty) return;
                await FirebaseService.answerQuestion(questionId, controller.text.trim(), doctorId: doctorId, doctorName: doctorName);
                if (mounted) Navigator.pop(context);
              },
              child: const Text('إرسال'),
            ),
          ],
        ),
      ),
    );
  }

  Widget infoTile(String title, dynamic value) {
    final text = value == null || value.toString().trim().isEmpty ? 'لم يتم الإدخال' : value.toString();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        const SizedBox(height: 6),
        Text(text, style: const TextStyle(fontWeight: FontWeight.w600, height: 1.5)),
      ]),
    );
  }

  Widget emptyHint(String text) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Text(text, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
      );

  Widget smallLoader() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: const Center(child: CircularProgressIndicator()),
      );
}
