import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../app_theme.dart';
import '../../models/doctor_profile.dart';
import '../../models/appointment.dart' show Appointment;
import '../../providers/auth_provider.dart';
import '../../services/navigation_service.dart';
import '../../services/appointment_service.dart' as appointment_service;
import '../doctor_appointments_screen.dart';

class DoctorDashboard extends ConsumerStatefulWidget {
  const DoctorDashboard({super.key});

  @override
  ConsumerState<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends ConsumerState<DoctorDashboard> {
  int _selectedIndex = 0;
  DoctorProfile? _doctorProfile;
  bool _isLoading = true;
  Map<String, int> _appointmentStats = {};
  Map<String, double> _revenueStats = {};
  List<Appointment> _todayAppointments = [];

  @override
  void initState() {
    super.initState();
    _loadDoctorProfile();
    _loadDashboardData();
  }

  Future<void> _loadDoctorProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doctorService = DoctorService();
        final profile = await doctorService.getOrCreateDoctorProfile(
          user.uid,
          user.email ?? '',
          user.displayName ?? 'Doctor',
        );
        setState(() {
          _doctorProfile = profile;
          _isLoading = false;
        });
      } catch (e) {
        print('Error loading doctor profile: $e');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadDashboardData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('❌ No authenticated user found for dashboard');
      return;
    }

    try {
      print('🏥 Loading dashboard data for doctor: ${user.uid}');

      // Load appointment statistics with fallback
      final appointmentStats = await appointment_service
          .AppointmentService.getDoctorAppointmentStats(user.uid);
      final revenueStats = await appointment_service
          .AppointmentService.getDoctorRevenueStats(user.uid);

      // Load today's appointments
      final today = DateTime.now();
      final todayAppointments = await appointment_service
          .AppointmentService.getDoctorAppointmentsByDate(user.uid, today);

      print(
        '✅ Dashboard loaded successfully - Total appointments: ${appointmentStats['total'] ?? 'Unknown'}',
      );

      if (mounted) {
        setState(() {
          // Ensure we have valid data with fallbacks
          _appointmentStats = {
            'total': appointmentStats['total'] ?? 0,
            'todayCount': appointmentStats['todayCount'] ?? 0,
            'thisWeek': appointmentStats['thisWeek'] ?? 0,
            'monthlyCount': appointmentStats['monthlyCount'] ?? 0,
            'pendingCount': appointmentStats['pendingCount'] ?? 0,
            'confirmed': appointmentStats['confirmed'] ?? 0,
            'completedCount': appointmentStats['completedCount'] ?? 0,
          };
          _revenueStats = {
            'total': revenueStats['total'] ?? 0.0,
            'todayRevenue': revenueStats['todayRevenue'] ?? 0.0,
            'weeklyRevenue': revenueStats['weeklyRevenue'] ?? 0.0,
            'monthlyRevenue': revenueStats['monthlyRevenue'] ?? 0.0,
          };
          _todayAppointments = todayAppointments;
        });
      }
    } catch (e) {
      print('❌ Error loading dashboard data: $e');
      // Set empty data on error
      if (mounted) {
        setState(() {
          _appointmentStats = {
            'total': 0,
            'todayCount': 0,
            'thisWeek': 0,
            'monthlyCount': 0,
            'pendingCount': 0,
            'confirmed': 0,
            'completedCount': 0,
          };
          _revenueStats = {
            'total': 0.0,
            'todayRevenue': 0.0,
            'weeklyRevenue': 0.0,
            'monthlyRevenue': 0.0,
          };
          _todayAppointments = [];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            NavigationService.navigateToLogin(context);
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          appBar: AppBar(
            title: Text(
              _getAppBarTitle(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadDashboardData,
                tooltip: 'Refresh Data',
              ),
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                  // TODO: Navigate to notifications
                },
              ),
              IconButton(
                icon: const Icon(Icons.person_outline),
                onPressed: () {
                  Navigator.of(context).pushNamed('/doctor-profile');
                },
              ),
            ],
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : IndexedStack(
                  index: _selectedIndex,
                  children: [
                    _buildOverviewTab(),
                    _buildAppointmentsTab(),
                    _buildAnalyticsTab(),
                  ],
                ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppTheme.primaryColor,
            unselectedItemColor: AppTheme.textSecondary,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                activeIcon: Icon(Icons.dashboard),
                label: 'Overview',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today_outlined),
                activeIcon: Icon(Icons.calendar_today),
                label: 'Appointments',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.analytics_outlined),
                activeIcon: Icon(Icons.analytics),
                label: 'Analytics',
              ),
            ],
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => NavigationService.navigateToLogin(context),
                child: const Text('Go to Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Appointments';
      case 2:
        return 'Analytics';
      default:
        return 'Dashboard';
    }
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeCard(),
          const SizedBox(height: 24),
          _buildQuickStats(),
          const SizedBox(height: 24),
          _buildTodaySchedule(),
          const SizedBox(height: 24),
          _buildRecentActivity(),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.gradientDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back, ${_doctorProfile?.fullName ?? 'Doctor'}!',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _doctorProfile?.specializationsText ?? 'General Practitioner',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          if (_doctorProfile?.isCurrentlyAvailable == true)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Currently Available',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Currently Offline',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Stats',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Today\'s Appointments',
                '${_appointmentStats['todayCount'] ?? 0}',
                Icons.calendar_today,
                AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Total Appointments',
                '${_appointmentStats['total'] ?? 0}',
                Icons.people,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Pending',
                '${_appointmentStats['pendingCount'] ?? 0}',
                Icons.pending_actions,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Revenue (Month)',
                '৳${(_revenueStats['monthlyRevenue'] ?? 0.0).toStringAsFixed(0)}',
                Icons.attach_money,
                Colors.blue,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaySchedule() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Today\'s Schedule',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () => setState(() => _selectedIndex = 1),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_todayAppointments.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 48,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No appointments today',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ..._todayAppointments
              .take(3)
              .map(
                (appointment) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildAppointmentCard(
                    appointment.patientName,
                    appointment.timeSlot,
                    appointment.reason ?? 'Consultation',
                    appointment.status.name,
                  ),
                ),
              ),
      ],
    );
  }

  Widget _buildAppointmentCard(
    String patientName,
    String time,
    String type,
    String status,
  ) {
    Color statusColor;
    switch (status) {
      case 'confirmed':
        statusColor = Colors.green;
        break;
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'in-progress':
        statusColor = Colors.blue;
        break;
      default:
        statusColor = AppTheme.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patientName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  type,
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                time,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Appointment Summary',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              _buildActivityItem(
                'Completed Appointments',
                '${_appointmentStats['completedCount'] ?? 0} appointments finished',
                Icons.check_circle,
                'Total',
              ),
              const Divider(),
              _buildActivityItem(
                'Confirmed Appointments',
                '${_appointmentStats['confirmed'] ?? 0} appointments scheduled',
                Icons.calendar_month,
                'Upcoming',
              ),
              const Divider(),
              _buildActivityItem(
                'This Week Revenue',
                '৳${(_revenueStats['weeklyRevenue'] ?? 0.0).toStringAsFixed(2)}',
                Icons.monetization_on,
                'Earnings',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(
    String title,
    String subtitle,
    IconData icon,
    String time,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentsTab() {
    return const DoctorAppointmentsScreen();
  }

  Widget _buildAnalyticsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 64,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'Analytics & Reports',
            style: TextStyle(fontSize: 18, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Coming soon...',
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}
