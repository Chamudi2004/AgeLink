// lib/home_page.dart

import 'package:flutter/material.dart';
import 'constants.dart';

// Import all your new pages
import 'home_screen.dart';
import 'schedule_page.dart';
import 'notification_page.dart';
import 'menu_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  // 1. Create a list of the pages you want to show
  static const List<Widget> _pages = <Widget>[
    HomeScreen(),       // Index 0
    SchedulePage(),     // Index 1
    NotificationPage(), // Index 2
    MenuPage(),         // Index 3
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
        backgroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 120,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          // Make sure your logo is in 'assets/agelink_logo.png'
          // and you have run 'flutter pub get' after updating pubspec.yaml
          child: Image.asset(
            'assets/agelink_logo.png',
            fit: BoxFit.contain,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: Constants.lightBlue,
              radius: 20,
              child: Icon(
                Icons.person,
                color: Constants.darkBlue,
                size: 24,
              ),
            ),
          ),
        ],
      ),

      // 2. Set the body to show the currently selected page from the list
      body: _pages.elementAt(_selectedIndex),

      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: Constants.darkBlue,
        unselectedItemColor: Constants.mediumGrey,
        currentIndex: _selectedIndex, // This is important
        onTap: _onItemTapped,      // This is important
        type: BottomNavigationBarType.fixed,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Column(
              children: [
                Icon(Icons.home),
                Text('Home', style: TextStyle(fontSize: 12)),
              ],
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Column(
              children: [
                Icon(Icons.calendar_month),
                Text('Schedule', style: TextStyle(fontSize: 12)),
              ],
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Column(
              children: [
                Icon(Icons.notifications),
                Text('Notification', style: TextStyle(fontSize: 12)),
              ],
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Column(
              children: [
                Icon(Icons.menu),
                Text('Menu', style: TextStyle(fontSize: 12)),
              ],
            ),
            label: '',
          ),
        ],
      ),
    );
  }
}