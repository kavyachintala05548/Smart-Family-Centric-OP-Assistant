import 'package:flutter/material.dart';
import '../specialist/specialist_screen.dart';
import '../appointments/appointments_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    Widget activeScreen;
    switch (index) {
      case 0:
        activeScreen = const SpecialistScreen();
        break;
      case 1:
        activeScreen = const AppointmentsScreen();
        break;
      case 2:
        activeScreen = const NotificationsScreen();
        break;
      case 3:
        activeScreen = const ProfileScreen();
        break;
      default:
        activeScreen = const SpecialistScreen();
    }

    return Scaffold(
      body: activeScreen,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.search), label: 'Find Doctor'),
          NavigationDestination(icon: Icon(Icons.event), label: 'Appointments'),
          NavigationDestination(icon: Icon(Icons.notifications), label: 'Alerts'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
