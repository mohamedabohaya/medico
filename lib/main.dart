import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'doctor_register_screen.dart';
import 'firebase_service.dart';
import 'doctor_profile_setup_screen.dart';
import 'doctor_dashboard_screen.dart';
import 'doctor_rejected_screen.dart';
import 'doctor_approved_screen.dart';
import 'doctor_waiting_screen.dart';
import 'login_screen.dart';
import 'navigation.dart';
import 'session_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (_) {
    // Firebase options must be replaced by running: flutterfire configure
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        canvasColor: Colors.white,
        dialogBackgroundColor: Colors.white,
        popupMenuTheme: const PopupMenuThemeData(color: Colors.white),
        bottomSheetTheme: const BottomSheetThemeData(backgroundColor: Colors.white),
        datePickerTheme: const DatePickerThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
        ),
        dropdownMenuTheme: const DropdownMenuThemeData(
          menuStyle: MenuStyle(backgroundColor: WidgetStatePropertyAll(Colors.white)),
        ),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, surface: Colors.white),
        useMaterial3: true,
      ),
      routes: {'/main': (_) => const MainNavigation()},
      home: const SplashScreen(),
    );
  }
}

//////////////////////////////////////////////////////////////
/// 1️⃣ Splash Screen
//////////////////////////////////////////////////////////////

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AnimationScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade700,
      body: Center(
        child: Text(
          "MediGo",
          style: TextStyle(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

//////////////////////////////////////////////////////////////
/// 2️⃣ Animation Screen
//////////////////////////////////////////////////////////////

class AnimationScreen extends StatefulWidget {
  const AnimationScreen({super.key});

  @override
  State<AnimationScreen> createState() => _AnimationScreenState();
}

class _AnimationScreenState extends State<AnimationScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController controller;
  late Animation<double> scaleAnimation;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    scaleAnimation = Tween<double>(begin: 0.5, end: 1.2).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeInOut),
    );

    controller.forward();

    Timer(const Duration(seconds: 3), () async {
      final nextScreen = await _getStartScreen();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => nextScreen),
      );
    });
  }

  Future<Widget> _getStartScreen() async {
    final savedDoctorPhone = await SessionManager.getLoggedInDoctorPhone();
    final savedDoctorRequestId = await SessionManager.getLoggedInDoctorRequestId();

    if (savedDoctorPhone != null && savedDoctorPhone.isNotEmpty) {
      final doctorRequest = savedDoctorRequestId != null && savedDoctorRequestId.isNotEmpty
          ? await FirebaseService.getDoctorRequestById(savedDoctorRequestId)
          : await FirebaseService.getDoctorRequestByPhone(savedDoctorPhone);

      if (doctorRequest != null) {
        final requestId = doctorRequest['id']?.toString();
        final phone = doctorRequest['phone']?.toString() ?? savedDoctorPhone;
        final status = doctorRequest['status']?.toString() ?? 'pending';

        if (status == 'approved') {
          final profile = await FirebaseService.getDoctorProfile(
            doctorRequestId: requestId,
            phone: phone,
          );

          if (profile == null) {
            return DoctorProfileSetupScreen(
              doctorRequestId: requestId,
              phone: phone,
            );
          }

          return DoctorDashboardScreen(
            doctorRequestId: requestId,
            phone: phone,
          );
        }

        if (status == 'rejected') {
          final seenRejected = await SessionManager.hasSeenDoctorStatus(
            phone: phone,
            status: 'rejected',
          );
          if (!seenRejected) {
            await SessionManager.markDoctorStatusSeen(
              phone: phone,
              status: 'rejected',
            );
            return DoctorRejectedScreen(
              reason: doctorRequest['rejectionReason']?.toString(),
            );
          }
          await SessionManager.logoutDoctor();
          return const HomeScreen();
        }

        await SessionManager.markDoctorStatusSeen(phone: phone, status: 'pending');
        return DoctorWaitingScreen(doctorId: requestId);
      }

      await SessionManager.logoutDoctor();
    }

    final savedPhone = await SessionManager.getLoggedInPhone();
    if (savedPhone != null) return const MainNavigation();

    return const HomeScreen();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ScaleTransition(
          scale: scaleAnimation,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.local_pharmacy, size: 80, color: Colors.blue),
              SizedBox(height: 10),
              Text(
                "MediGo",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//////////////////////////////////////////////////////////////
/// 3️⃣ Home Screen
//////////////////////////////////////////////////////////////

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [

            const SizedBox(height: 30),

            const Text(
              "احجز موعدك الآن",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),

            const SizedBox(height: 30),

            // صورة (تقدر تبدلها بأي asset)
            Expanded(
              child: Image.asset('assets/images/splah.jpg')
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [

                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {

                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PhoneScreen(fromDoctor: true,)),
                        );
                        // Navigator.push(
                        //   context,
                        //   MaterialPageRoute(builder: (_) => const DoctorRegisterScreen()),
                        // );

                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: const Text("سجل ك دكتور",style: TextStyle(color: Colors.white,fontWeight: FontWeight.w700,fontSize: 14),),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PhoneScreen(fromDoctor: false,)),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child:  Text("سجل ك مريض",style: TextStyle(fontWeight: FontWeight.w700,fontSize: 14,color: Colors.black),),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}