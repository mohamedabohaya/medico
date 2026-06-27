# خطوات إنشاء Firebase وربطه بتطبيق MediGo

## 1) إنشاء مشروع Firebase
1. افتح Firebase Console.
2. اضغط Add project.
3. اكتب اسم المشروع: `medigo-graduation-project`.
4. يمكن إيقاف Google Analytics لو المشروع للتخرج فقط.
5. اضغط Create project.

## 2) إضافة Android App
1. من Project Overview اضغط Android.
2. اكتب Package name الموجود في AndroidManifest، غالباً: `com.example.hospital`.
3. حمّل ملف `google-services.json`.
4. ضعه داخل: `android/app/google-services.json`.

## 3) تشغيل FlutterFire
من داخل مجلد المشروع نفذ:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
flutter pub get
```

سيتم استبدال ملف:
`lib/firebase_options.dart`
بالقيم الحقيقية لمشروعك.

## 4) تفعيل الخدمات
من Firebase Console فعّل:
- Authentication > Sign-in method > Anonymous مبدئياً للتجربة.
- Firestore Database > Create database.
- Storage يمكن تفعيله لاحقاً لرفع ملفات الطبيب فعلياً.

## 5) Collections المقترحة في Firestore
- `users`: بيانات المرضى.
- `doctorRequests`: طلبات تسجيل الأطباء قبل موافقة الأدمن.
- `doctors`: بيانات الطبيب بعد الموافقة واستكمال بيانات العيادة.
- `appointments`: الحجوزات.
- `questions`: أسئلة المرضى.
- `ratings`: تقييمات المرضى.
- `transactions`: معاملات الطبيب والمدفوعات.

## 6) قواعد Firestore للتجربة فقط
هذه قواعد مناسبة للتجربة الجامعية فقط، وليست للإنتاج الحقيقي:

```js
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## 7) ملاحظات مهمة
- الكود الحالي يربط البيانات مع Firebase مع إبقاء SQLite كنسخة احتياطية محلية حتى لا ينكسر التطبيق أثناء التجربة.
- ملف `firebase_options.dart` الحالي Placeholder ويجب استبداله عبر `flutterfire configure`.
- رفع ملفات الطبيب حالياً يحفظ اسم الملف فقط، ولرفع الملف نفسه يلزم إضافة Firebase Storage في مرحلة لاحقة.
