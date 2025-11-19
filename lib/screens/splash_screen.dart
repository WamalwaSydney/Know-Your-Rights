import 'package:flutter/material.dart';
import 'package:legal_ai/core/constants.dart';
import 'package:legal_ai/screens/wrapper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 3), () {});
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Wrapper()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Placeholder for the icon (Scales of Justice)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: kLightTextColor,
                borderRadius: BorderRadius.circular(kBorderRadius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.gavel, // Using a standard icon as a placeholder for the custom image
                size: 60,
                color: kPrimaryColor,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Know Your Rights',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: kLightTextColor,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'AI Legal Assistant',
              style: TextStyle(
                fontSize: 16,
                color: kLightTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
