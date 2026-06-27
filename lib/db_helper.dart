import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'firebase_service.dart';

class DBHelper {
  static Database? _db;

  static Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await initDB();
    return _db!;
  }

  static Future<Database> initDB() async {
    String path = join(await getDatabasesPath(), 'users.db');

    return await openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            email TEXT,
            phone TEXT,
            gender TEXT,
            birthdate TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE ratings(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            doctor TEXT,
            rating INTEGER
          )
        ''');

        await db.execute('''
          CREATE TABLE doctor_profiles(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            mainSpecialty TEXT,
            subSpecialties TEXT,
            about TEXT,
            clinicName TEXT,
            price TEXT,
            city TEXT,
            area TEXT,
            street TEXT,
            building TEXT,
            floorApartment TEXT,
            landmark TEXT,
            clinicVisit INTEGER,
            homeVisit INTEGER,
            phoneCall INTEGER
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS doctor_profiles(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT,
              mainSpecialty TEXT,
              subSpecialties TEXT,
              about TEXT,
              clinicName TEXT,
              price TEXT,
              city TEXT,
              area TEXT,
              street TEXT,
              building TEXT,
              floorApartment TEXT,
              landmark TEXT,
              clinicVisit INTEGER,
              homeVisit INTEGER,
              phoneCall INTEGER
            )
          ''');
        }
      },
    );
  }

  static Future<int> insertUser(Map<String, dynamic> user) async {
    try { await FirebaseService.savePatient(user); } catch (_) {}
    final dbClient = await db;
    return dbClient.insert('users', user);
  }

  static Future<List<Map<String, dynamic>>> getUserByPhone(String phone) async {
    try {
      final cloudUser = await FirebaseService.getUserByPhone(phone);
      if (cloudUser != null) return [cloudUser];
    } catch (_) {}
    final dbClient = await db;
    return dbClient.query(
      'users',
      where: 'phone = ?',
      whereArgs: [phone],
    );
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final db1 = await db;
    final result = await db1.query("users", limit: 1);
    return result.isNotEmpty ? result.first : null;
  }

  static Future<void> updateUser(Map<String, dynamic> data) async {
    try { await FirebaseService.updatePatient(data); } catch (_) {}
    final db1 = await db;
    await db1.update("users", data);
  }

  /// ⭐ إضافة تقييم
  static Future<void> insertRating(String doctor, int rating) async {
    try { await FirebaseService.addRating(doctor, rating); } catch (_) {}
    final dbClient = await db;
    await dbClient.insert("ratings", {
      "doctor": doctor,
      "rating": rating,
    });
  }

  /// ⭐ حساب متوسط التقييم
  static Future<double> getDoctorRating(String doctor) async {
    try {
      final cloudRating = await FirebaseService.getDoctorRating(doctor);
      if (cloudRating > 0) return cloudRating;
    } catch (_) {}
    final dbClient = await db;

    final result = await dbClient.rawQuery('''
      SELECT AVG(rating) as avgRating
      FROM ratings
      WHERE doctor = ?
    ''', [doctor]);

    if (result.first["avgRating"] == null) return 0.0;

    return double.parse(result.first["avgRating"].toString());
  }

  static Future<int> insertDoctorProfile(Map<String, dynamic> data) async {
    try { await FirebaseService.saveDoctorProfile(data); } catch (_) {}
    final dbClient = await db;
    return dbClient.insert('doctor_profiles', data);
  }

  static Future<Map<String, dynamic>?> getLastDoctorProfile() async {
    final dbClient = await db;
    final result = await dbClient.query(
      'doctor_profiles',
      orderBy: 'id DESC',
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }
}
