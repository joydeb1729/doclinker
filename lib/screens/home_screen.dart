import 'package:flutter/material.dart';
import '../widgets/main_layout.dart';
import '../pages/assistant_page.dart';
import '../pages/appointments_page.dart';
import '../pages/history_page.dart';
import '../pages/nearby_page.dart';
import '../controllers/location_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late LocationController _locationController;

  @override
  void initState() {
    super.initState();
    _locationController = LocationController();
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      pages: [
        AssistantPage(locationController: _locationController),
        AppointmentsPage(),
        HistoryPage(),
        NearbyPage(locationController: _locationController),
      ],
    );
  }
} 