import 'package:flutter/material.dart';
import 'package:my_app/models/user_model.dart'; // Import User model
import 'dashboard_page.dart';
import 'listings_page.dart';
import 'reservations_page.dart';
import 'messages_page.dart';
import 'profile_page.dart';

class OwnerPage extends StatefulWidget {
  final User user; // Add user parameter

  const OwnerPage({super.key, required this.user}); // Make user required

  @override
  _OwnerPageState createState() => _OwnerPageState();
}

class _OwnerPageState extends State<OwnerPage> {
  int _selectedIndex = 0;

  // Late initialization for page options to pass user data
  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    // Initialize the pages with user data
    _widgetOptions = <Widget>[
      DashboardPage(),
      ListingsPage(),
      ReservationsPage(),
      MessagesPage(),
      ProfilePage(),
    ];
  }

  // @override
  // void initState() {
  //   super.initState();
  //   // Initialize the pages with user data
  //   _widgetOptions = <Widget>[
  //     DashboardPage(user: widget.user),
  //     ListingsPage(user: widget.user),
  //     ReservationsPage(user: widget.user),
  //     MessagesPage(user: widget.user),
  //     ProfilePage(user: widget.user),
  //   ];
  // }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartStay Property Owner'),
        // You could also use the user's name here
        // title: Text('Welcome, ${widget.user.fullName}'),
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Listings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Reservations',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }
}
