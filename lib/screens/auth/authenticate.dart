import 'package:flutter/material.dart';
import 'package:legal_ai/screens/auth/register_screen.dart';
import 'package:legal_ai/screens/auth/sign_in_screen.dart';

class Authenticate extends StatefulWidget {
  const Authenticate({Key? key}) : super(key: key);

  @override
  State<Authenticate> createState() => _AuthenticateState();
}

class _AuthenticateState extends State<Authenticate> {
  bool showSignIn = true;

  void toggleView() {
    setState(() => showSignIn = !showSignIn);
  }

  @override
  Widget build(BuildContext context) {
    return showSignIn
        ? SignInScreen(toggleView: toggleView)
        : RegisterScreen(toggleView: toggleView);
  }
}
