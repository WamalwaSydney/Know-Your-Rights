// lib/presentation/screens/main/home_screen.dart (UPDATED)
import 'package:flutter/material.dart';
import 'package:legal_ai/core/services/auth_service.dart';
import 'package:legal_ai/core/constants.dart';
import 'package:legal_ai/screens/main/ai_assistant_screen.dart';
import 'package:legal_ai/screens/main/contract_review_screen.dart';
import 'package:legal_ai/screens/main/legal_library_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _auth = AuthService();
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    AIAssistantScreen(),
    ContractReviewScreen(),
    LegalLibraryScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Know Your Rights',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'AI Legal Assistant',
              style: TextStyle(
                fontSize: 12,
                color: kLightTextColor.withOpacity(0.7),
              ),
            ),
          ],
        ),
        leading: const Padding(
          padding: EdgeInsets.all(8.0),
          child: Icon(Icons.gavel, color: kPrimaryColor, size: 28),
        ),
        actions: <Widget>[
          // Settings Button
          IconButton(
            icon: const Icon(Icons.settings, color: kPrimaryColor),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
          // Logout Button
          IconButton(
            icon: const Icon(Icons.logout, color: kPrimaryColor),
            tooltip: 'Sign Out',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: kDarkCardColor,
                  title: const Text(
                    'Sign Out',
                    style: TextStyle(color: kLightTextColor),
                  ),
                  content: const Text(
                    'Are you sure you want to sign out?',
                    style: TextStyle(color: kLightTextColor),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        'Sign Out',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await _auth.signOut();
              }
            },
          ),
        ],
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.smart_toy_outlined),
            activeIcon: Icon(Icons.smart_toy),
            label: 'AI Assistant',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.gavel_outlined),
            activeIcon: Icon(Icons.gavel),
            label: 'Contract Review',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books_outlined),
            activeIcon: Icon(Icons.library_books),
            label: 'Library',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: kPrimaryColor,
        onTap: _onItemTapped,
      ),
    );
  }
}