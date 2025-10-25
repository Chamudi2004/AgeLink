import 'package:flutter/material.dart';
import 'constants.dart';
import 'home_screen.dart';
import 'schedule_page.dart';
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
    SchedulePage(),     // Index 1
    NotificationPage(), // Index 2
  ];

  // 2. Updated tap handler
  // It now needs the 'context' to be able to find the Scaffold
  void _onItemTapped(int index, BuildContext context) {
    if (index == 3) {
      // If "Menu" (index 3) is tapped, open the drawer
      Scaffold.of(context).openEndDrawer();
    } else {
      // For Home, Schedule, Notification, just change the page
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 3. The drawer is added here, so it's ready to be opened
      endDrawer: const AppMenuDrawer(),

      // 4. The AppBar is back to its original state (static icon)
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

      // 5. The body shows one of the 3 pages
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),


      // 6. The BottomNavigationBar
      // We wrap it in a 'Builder' to get a new 'context'
      // This is necessary so that 'Scaffold.of(context)' in our
      // _onItemTapped function can find the Scaffold.
      bottomNavigationBar: Builder(
          builder: (context) { // This 'context' is *under* the Scaffold
            return BottomNavigationBar(
              backgroundColor: Colors.white,
              selectedItemColor: Constants.darkBlue,
              unselectedItemColor: Constants.mediumGrey,
              currentIndex: _selectedIndex,
              // Pass the new 'context' to our tap handler
              onTap: (index) => _onItemTapped(index, context),
              type: BottomNavigationBarType.fixed,

              // 7. The 4 items are back in the list-
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