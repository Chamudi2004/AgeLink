import 'package:flutter/material.dart';
import 'constants.dart';
import 'home_screen.dart';
import 'medication_schedule_page.dart';
import 'notification_page.dart';
import 'app_menu_drawer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  // 1. The list of pages for the body (only 3 pages)
  static const List<Widget> _pages = <Widget>[
    HomeScreen(),       // Index 0
    MedicationSchedulePage(),     // Index 1
    NotificationPage(), // Index 2
  ];


  void _onItemTapped(int index, BuildContext context) {
    if (index == 3) {
      Scaffold.of(context).openEndDrawer();
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: const AppMenuDrawer(),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 120,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Image.asset(
            'assets/agelink_logo.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Center(
              child: Text(
                'Agelink',
                style: TextStyle(
                    color: Constants.darkBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
              ),
            ),
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

      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),



      bottomNavigationBar: Builder(
          builder: (context) {
            return BottomNavigationBar(
              backgroundColor: Colors.white,
              selectedItemColor: Constants.darkBlue,
              unselectedItemColor: Constants.mediumGrey,
              currentIndex: _selectedIndex,
              onTap: (index) => _onItemTapped(index, context),
              type: BottomNavigationBarType.fixed,

              items: const <BottomNavigationBarItem>[
                // Home
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Home',
                ),
                // Schedule
                BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_month),
                  label: 'Schedule',
                ),
                // Notification
                BottomNavigationBarItem(
                  icon: Icon(Icons.notifications),
                  label: 'Notification',
                ),
                // Menu
                BottomNavigationBarItem(
                  icon: Icon(Icons.menu),
                  label: 'Menu',
                ),
              ],
            );
          }
      ),
    );
  }
}