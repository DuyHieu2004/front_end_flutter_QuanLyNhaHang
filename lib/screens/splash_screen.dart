import 'package:flutter/material.dart';
import 'package:front_end_app/utils/QuickAlert.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:front_end_app/services/auth_service.dart';
import 'package:front_end_app/screens/home_screen.dart';
import 'package:front_end_app/screens/login_screen.dart';
import 'package:front_end_app/screens/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   QuickAlertService.showAlertLoading(context, "Đang tải dữ liệu...");
    //   _checkAppStatus();
    // });
    _checkAppStatus();
  }

  Future<void> _checkAppStatus() async {
    await Future.delayed(Duration(seconds: 2));

    final prefs = await SharedPreferences.getInstance();

    bool hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

    if (!mounted) return;

    if (!hasSeenOnboarding) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => OnboardingScreen()),
      );
    } else {
      String? token = await _authService.getToken();
      if (!mounted) return;

      if (token != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/splash.jpg',
            fit: BoxFit.cover,
          ),
          Container(
            color: Colors.black.withOpacity(0.4),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                SizedBox(height: 20),

              ],
            ),
          ),
        ],
      ),
    );
  }
}