import 'package:flutter/material.dart';
import 'package:legal_ai/core/constants.dart';

class AuthCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget form;

  const AuthCard({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.form,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top Orange Header (from Login Mockup)
        Container(
          height: 100,
          color: kPrimaryColor,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: kLightTextColor,
                borderRadius: BorderRadius.circular(kBorderRadius),
              ),
              child: const Icon(
                Icons.gavel, // Placeholder for the Scales of Justice icon
                size: 30,
                color: kPrimaryColor,
              ),
            ),
          ),
        ),
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              color: kDarkBackgroundColor,
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 0),
                padding: const EdgeInsets.all(30.0),
                decoration: const BoxDecoration(
                  color: kLightTextColor, // White background for the card
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(kLargeBorderRadius),
                    topRight: Radius.circular(kLargeBorderRadius),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: kDarkTextColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: kDarkTextColor.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 30),
                      form,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
