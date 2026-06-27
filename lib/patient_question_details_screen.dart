
import 'package:flutter/material.dart';

class PatientQuestionDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> item;
  const PatientQuestionDetailsScreen({super.key, required this.item});

  String value(dynamic v) {
    final s = v?.toString().trim() ?? '';
    return s.isEmpty ? 'غير محدد' : s;
  }

  @override
  Widget build(BuildContext context) {
    final answer = value(item['answer']);
    final hasAnswer = answer != 'غير محدد';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xffF4F6F9),
        appBar: AppBar(
          title: const Text('تفاصيل السؤال'),
          centerTitle: true,
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            card([
              row(Icons.medical_services, 'التخصص', value(item['specialty'])),
              row(Icons.person, 'اسم الطبيب', value(item['doctorName'])),
              row(Icons.cake, 'العمر', value(item['age'])),
              row(Icons.wc, 'النوع', value(item['gender'])),
            ]),
            const SizedBox(height: 12),
            card([
              title('السؤال'),
              const SizedBox(height: 8),
              Text(value(item['title'] ?? item['question']), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, height: 1.5)),
              const SizedBox(height: 10),
              Text(value(item['description'] ?? item['text']), style: const TextStyle(fontSize: 15, height: 1.7)),
            ]),
            const SizedBox(height: 12),
            card([
              Row(
                children: [
                  Icon(hasAnswer ? Icons.check_circle : Icons.hourglass_top, color: hasAnswer ? Colors.green : Colors.orange),
                  const SizedBox(width: 8),
                  Text(hasAnswer ? 'إجابة الطبيب' : 'بانتظار رد الطبيب', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: hasAnswer ? Colors.green : Colors.orange)),
                ],
              ),
              if (hasAnswer) ...[
                const SizedBox(height: 10),
                Text(answer, style: const TextStyle(fontSize: 15, height: 1.8)),
              ],
            ]),
          ],
        ),
      ),
    );
  }

  Widget card(List<Widget> children) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
      );

  Widget title(String text) => Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue));

  Widget row(IconData icon, String title, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue, size: 22),
            const SizedBox(width: 10),
            SizedBox(width: 95, child: Text(title, style: TextStyle(color: Colors.grey.shade600))),
            Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
          ],
        ),
      );
}
