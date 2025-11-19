import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:legal_ai/screens/auth/authenticate.dart';
import 'package:legal_ai/screens/main/home_screen.dart';
import 'package:provider/provider.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Access the user data from the StreamProvider in main.dart
    final user = Provider.of<User?>(context);

    // return either the Home or Authenticate widget
    if (user == null) {
      return const Authenticate();
    } else {
      return HomeScreen();
    }
  }
}