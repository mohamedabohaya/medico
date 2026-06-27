import 'package:flutter/material.dart';
import 'firebase_service.dart';
import 'main.dart';
import 'session_manager.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  TextEditingController name = TextEditingController();
  TextEditingController phone = TextEditingController();
  TextEditingController email = TextEditingController();
  TextEditingController date = TextEditingController();

  String gender = "Male";
  bool isEditing = false;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    final savedPhone = await SessionManager.getLoggedInPhone();
    if (savedPhone == null) {
      setState(() => loading = false);
      return;
    }

    final user = await FirebaseService.getUserByPhone(savedPhone);

    if (user != null) {
      name.text = user['name'] ?? '';
      phone.text = FirebaseService.formatPhoneForDisplay(user['phone'] ?? savedPhone);
      email.text = user['email'] ?? '';
      date.text = user['birthdate'] ?? '';
      gender = user['gender'] ?? 'Male';
    } else {
      phone.text = FirebaseService.formatPhoneForDisplay(savedPhone);
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> save() async {
    final exists = await FirebaseService.emailExists(email.text.trim(), excludePhone: phone.text.trim());
    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('هذا الإيميل مستخدم مسبقاً')));
      return;
    }
    await FirebaseService.updatePatient({
      "name": name.text.trim(),
      "phone": phone.text.trim(),
      "email": email.text.trim(),
      "birthdate": date.text.trim(),
      "gender": gender,
    }, phone: phone.text.trim());

    setState(() => isEditing = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ البيانات')));
  }

  Future<void> logout() async {
    await SessionManager.logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    email.dispose();
    date.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xffF4F6F9),
        appBar: AppBar(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          centerTitle: true,
          title: const Text('حسابي'),
          actions: [
            TextButton(
              onPressed: loading
                  ? null
                  : () {
                      if (isEditing) {
                        save();
                      } else {
                        setState(() => isEditing = true);
                      }
                    },
              child: Text(
                isEditing ? 'حفظ' : 'تعديل',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            )
          ],
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  profileHeader(),
                  const SizedBox(height: 16),
                  sectionCard(
                    title: 'البيانات الشخصية',
                    children: [
                      buildField('الاسم', name, Icons.person, readOnly: !isEditing),
                      buildField('الهاتف', phone, Icons.phone, readOnly: true),
                      buildField('الإيميل', email, Icons.email, readOnly: !isEditing),
                      buildField('تاريخ الميلاد', date, Icons.calendar_today, readOnly: !isEditing),
                      genderSelector(),
                    ],
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: logout,
                    icon: const Icon(Icons.logout),
                    label: const Text('تسجيل الخروج', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
      ),
    );
  }

  Widget profileHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: Colors.blue.shade50,
            child: const Icon(Icons.person, color: Colors.blue, size: 42),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name.text.isEmpty ? 'مستخدم' : name.text, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
            ]),
          ),
        ],
      ),
    );
  }

  Widget sectionCard({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 14),
        ...children,
      ]),
    );
  }

  Widget buildField(String label, TextEditingController controller, IconData icon, {bool readOnly = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        textAlign: TextAlign.right,
        decoration: InputDecoration(
          // labelText: label,
          prefixIcon: Icon(icon, color: Colors.blue),
          filled: true,
          fillColor: readOnly ? Colors.grey.shade100 : Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget genderSelector() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('الجنس', style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(child: genderChip('Male', 'ذكر')),
          const SizedBox(width: 10),
          Expanded(child: genderChip('Female', 'أنثى')),
        ],
      ),
    ]);
  }

  Widget genderChip(String value, String label) {
    final selected = gender == value;
    return GestureDetector(
      onTap: isEditing ? () => setState(() => gender = value) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? Colors.blue.shade50 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? Colors.blue : Colors.transparent),
        ),
        child: Center(
          child: Text(label, style: TextStyle(color: selected ? Colors.blue : Colors.black87, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
