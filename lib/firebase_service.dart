import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  static final FirebaseFirestore firestore = FirebaseFirestore.instance;
  static final FirebaseAuth auth = FirebaseAuth.instance;

  static String phoneLocalPart(String phone) {
    var digits = phone.toString().replaceAll(RegExp(r'[^0-9]'), '').trim();

    // يدعم الأرقام القديمة المخزنة مع +970 / +972 أو بدون مفتاح دولة
    if (digits.startsWith('970') || digits.startsWith('972')) {
      digits = digits.substring(3);
    }

    // يدعم الإدخال المحلي لو المستخدم كتب 059xxxxxxx أو 056xxxxxxx
    if (digits.length == 10 && digits.startsWith('0')) {
      digits = digits.substring(1);
    }

    if (digits.length > 9) {
      digits = digits.substring(digits.length - 9);
    }

    return digits;
  }

  static bool isValidLocalPhone(String phone) {
    final local = phoneLocalPart(phone);
    return RegExp(r'^(59|56)\d{7}$').hasMatch(local);
  }

  static String localPhoneErrorText() =>
      'رقم الجوال يجب أن يبدأ بـ 059 أو 056 ويتكون من 10 أرقام';

  static String normalizePhone(String phone) => phoneLocalPart(phone);

  static String safePhoneId(String phone) => normalizePhone(phone);

  static String formatPhoneForDisplay(String phone) {
    final local = phoneLocalPart(phone);
    if (local.isEmpty) return phone;
    // العرض للمستخدم يكون بالشكل المحلي الكامل مع الصفر: 059xxxxxxx أو 056xxxxxxx
    if (RegExp(r'^(59|56)\d{7}$').hasMatch(local)) {
      return '\u200E0$local';
    }
    return '\u200E$local';
  }

  static num parseNumber(dynamic value) {
    final text = (value ?? '').toString().replaceAll('شيكل', '').replaceAll('جنيه', '').trim();
    return num.tryParse(text) ?? 0;
  }

  static String servicePrice(Map<String, dynamic> doctor, String serviceType) {
    dynamic v;
    if (serviceType == 'phone') v = doctor['phonePrice'];
    if (serviceType == 'home') v = doctor['homeVisitPrice'];
    if (serviceType == 'clinic') v = doctor['clinicVisitPrice'];
    v ??= doctor['price'];
    final text = (v ?? '0').toString().replaceAll('جنيه', '').replaceAll('شيكل', '').trim();
    return text.isEmpty ? '0' : text;
  }

  static DateTime nextDateForArabicDay(String day) {
    final clean = day.trim();
    final map = <String, int>{
      'الإثنين': DateTime.monday,
      'الاثنين': DateTime.monday,
      'الثلاثاء': DateTime.tuesday,
      'الأربعاء': DateTime.wednesday,
      'الاربعاء': DateTime.wednesday,
      'الخميس': DateTime.thursday,
      'الجمعة': DateTime.friday,
      'السبت': DateTime.saturday,
      'الأحد': DateTime.sunday,
      'الاحد': DateTime.sunday,
    };
    final now = DateTime.now();
    final target = map[clean];
    if (target == null) return now;
    var diff = target - now.weekday;
    if (diff < 0) diff += 7;
    return DateTime(now.year, now.month, now.day).add(Duration(days: diff));
  }

  static String dateStringForSelectedTime(Map<String, String> selectedTime) {
    final existing = selectedTime['date']?.trim();
    if (existing != null && existing.isNotEmpty) return existing;
    final d = nextDateForArabicDay(selectedTime['day'] ?? '');
    return '${d.day}/${d.month}/${d.year}';
  }

  static String timeStringForSelectedTime(Map<String, String> selectedTime) {
    final day = (selectedTime['day'] ?? '').trim();
    final from = (selectedTime['from'] ?? '').trim();
    final to = (selectedTime['to'] ?? '').trim();
    if (day.isEmpty && from.isEmpty && to.isEmpty) return 'لم يحدد';
    return '$day من $from إلى $to'.trim();
  }

  static Future<User?> ensureAnonymousUser() async {
    if (auth.currentUser != null) return auth.currentUser;
    final cred = await auth.signInAnonymously();
    return cred.user;
  }



  static Future<bool> emailExists(String email, {String? excludePhone}) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) return false;
    var snap = await firestore.collection('users').where('emailLower', isEqualTo: normalizedEmail).limit(1).get();
    if (snap.docs.isEmpty) {
      snap = await firestore.collection('users').where('email', isEqualTo: email.trim()).limit(1).get();
    }
    if (snap.docs.isEmpty) return false;
    if (excludePhone != null && excludePhone.trim().isNotEmpty) {
      final existingPhone = (snap.docs.first.data()['phone'] ?? '').toString();
      return normalizePhone(existingPhone) != normalizePhone(excludePhone);
    }
    return true;
  }

  static Future<bool> phoneExists(String phone) async {
    return phoneExistsInAnyAccount(phone);
  }

  static Future<bool> phoneExistsInAnyAccount(String phone, {String? excludeDocId}) async {
    final normalized = normalizePhone(phone);
    if (normalized.isEmpty) return false;
    final local = phoneLocalPart(normalized);
    if (local.isEmpty) return false;

    final userSnap = await firestore.collection('users').where('phoneLocal', isEqualTo: local).limit(1).get();
    if (userSnap.docs.any((d) => excludeDocId == null || d.id != excludeDocId)) return true;

    final requestSnap = await firestore.collection('doctorRequests').where('phoneLocal', isEqualTo: local).limit(1).get();
    if (requestSnap.docs.any((d) => excludeDocId == null || d.id != excludeDocId)) return true;

    final doctorSnap = await firestore.collection('doctors').where('phoneLocal', isEqualTo: local).limit(1).get();
    if (doctorSnap.docs.any((d) => excludeDocId == null || d.id != excludeDocId)) return true;

    return false;
  }

  static Future<bool> doctorPhoneExists(String phone, {String? excludeDocId}) async {
    return phoneExistsInAnyAccount(phone, excludeDocId: excludeDocId);
  }

  static Future<void> savePatient(Map<String, dynamic> data) async {
    await ensureAnonymousUser();
    final phone = normalizePhone(data['phone']?.toString() ?? '');
    final id = safePhoneId(phone);
    await firestore.collection('users').doc(id).set({
      ...data,
      'phone': phone,
      'phoneLocal': phoneLocalPart(phone),
      'emailLower': (data['email'] ?? '').toString().trim().toLowerCase(),
      'role': 'patient',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<Map<String, dynamic>?> getUserByPhone(String phone) async {
    final normalized = normalizePhone(phone);
    final id = safePhoneId(normalized);
    final doc = await firestore.collection('users').doc(id).get();
    if (doc.exists) return {'id': doc.id, ...?doc.data()};
    final local = phoneLocalPart(normalized);
    if (local.isNotEmpty) {
      final snap = await firestore.collection('users').where('phoneLocal', isEqualTo: local).limit(1).get();
      if (snap.docs.isNotEmpty) return {'id': snap.docs.first.id, ...snap.docs.first.data()};
    }
    return null;
  }

  static Future<void> updatePatient(Map<String, dynamic> data, {String? phone}) async {
    await ensureAnonymousUser();
    final userPhone = phone ?? data['phone']?.toString() ?? '';
    final id = safePhoneId(userPhone);
    await firestore.collection('users').doc(id).set({
      ...data,
      'phoneLocal': phoneLocalPart(userPhone),
      'emailLower': (data['email'] ?? '').toString().trim().toLowerCase(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<String> saveDoctorRequest(Map<String, dynamic> data) async {
    await ensureAnonymousUser();
    final phone = normalizePhone(data['phone']?.toString() ?? '');
    if (await phoneExistsInAnyAccount(phone)) {
      throw Exception('رقم الجوال مسجل مسبقاً');
    }
    final ref = firestore.collection('doctorRequests').doc();
    await ref.set({
      ...data,
      'phone': phone,
      'phoneLocal': phoneLocalPart(phone),
      'role': 'doctor',
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  static Future<Map<String, dynamic>?> getDoctorRequestById(String docId) async {
    final doc = await firestore.collection('doctorRequests').doc(docId).get();
    return doc.exists ? {'id': doc.id, ...?doc.data()} : null;
  }

  static Future<Map<String, dynamic>?> getDoctorRequestByPhone(String phone) async {
    final normalized = normalizePhone(phone);
    var snap = await firestore
        .collection('doctorRequests')
        .where('phone', isEqualTo: normalized)
        .limit(1)
        .get();
    if (snap.docs.isNotEmpty) return {'id': snap.docs.first.id, ...snap.docs.first.data()};

    final local = phoneLocalPart(normalized);
    if (local.isEmpty) return null;
    snap = await firestore
        .collection('doctorRequests')
        .where('phoneLocal', isEqualTo: local)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return {'id': snap.docs.first.id, ...snap.docs.first.data()};
  }

  static Future<void> updateDoctorRequestStatus(String docId, String status) async {
    await firestore.collection('doctorRequests').doc(docId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<String> saveDoctorProfile(
    Map<String, dynamic> data, {
    String? doctorRequestId,
    String? phone,
  }) async {
    await ensureAnonymousUser();

    final existing = await getDoctorProfile(
      doctorRequestId: doctorRequestId,
      phone: phone ?? data['phone']?.toString(),
    );

    final ref = existing == null
        ? firestore.collection('doctors').doc()
        : firestore.collection('doctors').doc(existing['id'].toString());

    await ref.set({
      ...data,
      'doctorId': ref.id,
      'doctorRequestId': doctorRequestId ?? data['doctorRequestId'],
      'phone': normalizePhone(phone ?? data['phone']?.toString() ?? ''),
      'phoneLocal': phoneLocalPart(phone ?? data['phone']?.toString() ?? ''),
      'status': 'approved',
      'profileCompleted': true,
      'ratingAvg': data['ratingAvg'] ?? existing?['ratingAvg'] ?? 0,
      'ratingCount': data['ratingCount'] ?? existing?['ratingCount'] ?? 0,
      'visitorsCount': data['visitorsCount'] ?? existing?['visitorsCount'] ?? 0,
      'createdAt': existing == null ? FieldValue.serverTimestamp() : existing['createdAt'],
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return ref.id;
  }

  static Future<Map<String, dynamic>?> getDoctorProfile({
    String? doctorRequestId,
    String? phone,
  }) async {
    if (doctorRequestId != null && doctorRequestId.isNotEmpty) {
      final snap = await firestore
          .collection('doctors')
          .where('doctorRequestId', isEqualTo: doctorRequestId)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        return {'id': snap.docs.first.id, ...snap.docs.first.data()};
      }
    }

    final normalizedPhone = normalizePhone(phone ?? '');
    if (normalizedPhone.isNotEmpty) {
      var snap = await firestore
          .collection('doctors')
          .where('phone', isEqualTo: normalizedPhone)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        return {'id': snap.docs.first.id, ...snap.docs.first.data()};
      }
      final local = phoneLocalPart(normalizedPhone);
      if (local.isNotEmpty) {
        snap = await firestore
            .collection('doctors')
            .where('phoneLocal', isEqualTo: local)
            .limit(1)
            .get();
        if (snap.docs.isNotEmpty) {
          return {'id': snap.docs.first.id, ...snap.docs.first.data()};
        }
      }
    }

    return null;
  }

  static Future<void> updateDoctorProfile(String doctorId, Map<String, dynamic> data) async {
    await ensureAnonymousUser();
    final userPhone = data['phone']?.toString() ?? '';
    await firestore.collection('doctors').doc(doctorId).set({
      ...data,
      if (userPhone.trim().isNotEmpty) 'phoneLocal': phoneLocalPart(userPhone),
      'emailLower': (data['email'] ?? '').toString().trim().toLowerCase(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<Map<String, dynamic>?> getDoctorById(String doctorId) async {
    if (doctorId.trim().isEmpty) return null;
    final doc = await firestore.collection('doctors').doc(doctorId).get();
    if (!doc.exists) return null;
    return {'id': doc.id, ...?doc.data()};
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> approvedDoctors() {
    return firestore.collection('doctors').where('status', isEqualTo: 'approved').snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> doctorsBySpecialty(String specialty) {
    return firestore
        .collection('doctors')
        .where('status', isEqualTo: 'approved')
        .where('mainSpecialty', isEqualTo: specialty)
        .snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> doctorsByServiceAndSpecialty({
    required String serviceType,
    required String specialty,
  }) {
    String serviceField = 'clinicVisit';
    if (serviceType == 'home') serviceField = 'homeVisit';
    if (serviceType == 'phone') serviceField = 'phoneCall';

    return firestore
        .collection('doctors')
        .where('status', isEqualTo: 'approved')
        .where('mainSpecialty', isEqualTo: specialty)
        .where(serviceField, isEqualTo: true)
        .snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> doctorsByService({
    required String serviceType,
  }) {
    String serviceField = 'clinicVisit';
    if (serviceType == 'home') serviceField = 'homeVisit';
    if (serviceType == 'phone') serviceField = 'phoneCall';

    return firestore
        .collection('doctors')
        .where('status', isEqualTo: 'approved')
        .where(serviceField, isEqualTo: true)
        .snapshots();
  }

  static Future<String> createBooking(Map<String, dynamic> data) async {
    await ensureAnonymousUser();
    final ref = firestore.collection('appointments').doc();
    await ref.set({
      ...data,
      'appointmentId': ref.id,
      'status': 'booked',
      'type': data['type'] ?? 'booking',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> patientAppointments(String phone) {
    return firestore
        .collection('appointments')
        .where('patientPhone', isEqualTo: normalizePhone(phone))
        .snapshots();
  }

  static Future<void> cancelAppointment(String appointmentId) async {
    await ensureAnonymousUser();
    await firestore.collection('appointments').doc(appointmentId).set({
      'status': 'cancelled',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> markAppointmentDone(String appointmentId) async {
    await ensureAnonymousUser();
    final appointmentRef = firestore.collection('appointments').doc(appointmentId);

    await firestore.runTransaction((tx) async {
      final appointmentSnap = await tx.get(appointmentRef);
      final data = appointmentSnap.data() ?? {};
      final currentStatus = data['status']?.toString() ?? '';
      final doctorId = (data['doctorId'] ?? '').toString();
      final visitorCounted = data['visitorCounted'] == true;

      tx.set(appointmentRef, {
        'status': 'done',
        'doneAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        if (!visitorCounted) 'visitorCounted': true,
      }, SetOptions(merge: true));

      if (currentStatus != 'done' && !visitorCounted && doctorId.isNotEmpty) {
        final doctorRef = firestore.collection('doctors').doc(doctorId);
        tx.set(doctorRef, {
          'visitorsCount': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    });
  }

  static Future<void> addQuestion(Map<String, dynamic> data) async {
    await ensureAnonymousUser();
    final ref = firestore.collection('questions').doc();
    await ref.set({
      ...data,
      'questionId': ref.id,
      'type': 'question',
      'status': 'waiting',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> questionsForDoctor({
    required String doctorId,
    String? specialty,
  }) {
    Query<Map<String, dynamic>> query = firestore.collection('questions');

    // نجلب أسئلة نفس تخصص الطبيب، ثم نفلتر في الواجهة:
    // waiting تظهر لكل أطباء التخصص، answered تظهر فقط للطبيب الذي رد.
    if (specialty != null && specialty.trim().isNotEmpty) {
      query = query.where('specialty', isEqualTo: specialty.trim());
    } else {
      query = query.where('doctorId', isEqualTo: doctorId);
    }

    return query.snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> answeredQuestionsForDoctor(String doctorId) {
    return firestore
        .collection('questions')
        .where('doctorId', isEqualTo: doctorId)
        .where('status', isEqualTo: 'answered')
        .snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> patientQuestions(String phone) {
    return firestore
        .collection('questions')
        .where('patientPhone', isEqualTo: normalizePhone(phone))
        .snapshots();
  }

  static Future<void> answerQuestion(
    String questionId,
    String answer, {
    String? doctorId,
    String? doctorName,
  }) async {
    await ensureAnonymousUser();
    await firestore.collection('questions').doc(questionId).set({
      'answer': answer,
      'status': 'answered',
      if (doctorId != null) 'doctorId': doctorId,
      if (doctorName != null) 'doctorName': doctorName,
      'answeredAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> addAppointmentRating({
    required String appointmentId,
    required String doctorId,
    required int rating,
    String? doctorName,
    String? patientPhone,
  }) async {
    await ensureAnonymousUser();

    final appointmentRef = firestore.collection('appointments').doc(appointmentId);
    final doctorRef = firestore.collection('doctors').doc(doctorId);

    await firestore.runTransaction((tx) async {
      final doctorSnap = await tx.get(doctorRef);
      final data = doctorSnap.data() ?? {};
      final oldAvg = ((data['ratingAvg'] ?? 0) as num).toDouble();
      final oldCount = ((data['ratingCount'] ?? 0) as num).toInt();
      final newCount = oldCount + 1;
      final newAvg = ((oldAvg * oldCount) + rating) / newCount;

      tx.set(appointmentRef, {
        'rating': rating,
        'rated': true,
        'ratedAt': FieldValue.serverTimestamp(),
        'status': 'done',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      tx.set(doctorRef, {
        'ratingAvg': newAvg,
        'ratingCount': newCount,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });

    await firestore.collection('ratings').add({
      'appointmentId': appointmentId,
      'doctorId': doctorId,
      'doctorName': doctorName ?? '',
      'patientPhone': normalizePhone(patientPhone ?? ''),
      'rating': rating,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> incrementDoctorVisitors(String doctorId) async {
    if (doctorId.isEmpty) return;
    await ensureAnonymousUser();
    await firestore.collection('doctors').doc(doctorId).set({
      'visitorsCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> addRating(String doctorName, int rating) async {
    await ensureAnonymousUser();
    await firestore.collection('ratings').add({
      'doctor': doctorName,
      'rating': rating,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<double> getDoctorRating(String doctorName) async {
    final snap = await firestore.collection('ratings').where('doctor', isEqualTo: doctorName).get();
    if (snap.docs.isEmpty) return 0;
    final sum = snap.docs.fold<num>(0, (p, d) => p + ((d.data()['rating'] ?? 0) as num));
    return sum / snap.docs.length;
  }

  static Future<void> addAppointment(Map<String, dynamic> data) async {
    await createBooking(data);
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> doctorAppointmentsById(String doctorId) {
    return firestore.collection('appointments').where('doctorId', isEqualTo: doctorId).snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> doctorAppointments(String doctorName) {
    return firestore.collection('appointments').where('doctorName', isEqualTo: doctorName).snapshots();
  }

  static Future<int> doctorAppointmentsCount(String doctorId) async {
    final snap = await firestore.collection('appointments').where('doctorId', isEqualTo: doctorId).get();
    return snap.docs.length;
  }

  static Future<void> addTransaction(Map<String, dynamic> data) async {
    await ensureAnonymousUser();
    await firestore.collection('transactions').add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
