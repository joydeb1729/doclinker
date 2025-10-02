import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app_theme.dart';
import '../models/appointment.dart';
import '../services/appointment_service.dart' as appointment_service;

class PatientAppointmentsScreen extends ConsumerStatefulWidget {
  const PatientAppointmentsScreen({super.key});

  @override
  ConsumerState<PatientAppointmentsScreen> createState() =>
      _PatientAppointmentsScreenState();
}

class _PatientAppointmentsScreenState
    extends ConsumerState<PatientAppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Appointment> _appointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAppointments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAppointments() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final appointments = await appointment_service
          .AppointmentService.getPatientAppointments(user.uid);
      setState(() {
        _appointments = appointments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading appointments: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  List<Appointment> _filterAppointments(String filter) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (filter) {
      case 'upcoming':
        return _appointments
            .where(
              (apt) =>
                  apt.appointmentDate.isAfter(today) &&
                  apt.status != AppointmentStatus.cancelled &&
                  apt.status != AppointmentStatus.completed,
            )
            .toList();
      case 'past':
        return _appointments
            .where(
              (apt) =>
                  apt.appointmentDate.isBefore(today) ||
                  apt.status == AppointmentStatus.completed,
            )
            .toList();
      case 'cancelled':
        return _appointments
            .where((apt) => apt.status == AppointmentStatus.cancelled)
            .toList();
      default:
        return _appointments;
    }
  }

  Future<void> _cancelAppointment(Appointment appointment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: const Text(
          'Are you sure you want to cancel this appointment?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await appointment_service.AppointmentService.cancelAppointment(
          appointment.id,
          reason: 'Cancelled by patient',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );

        _loadAppointments(); // Reload appointments
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel appointment: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  // Helper method to create responsive action buttons
  Widget _buildActionButtons(Appointment appointment, bool isUpcoming) {
    if (!isUpcoming) return const SizedBox.shrink();
    
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    
    if (isSmallScreen) {
      // Stack buttons vertically on very small screens
      return Column(
        children: [
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _cancelAppointment(appointment),
              icon: const Icon(Icons.cancel_outlined, size: 16),
              label: const Text(
                'Cancel',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Reschedule feature coming soon!'),
                  ),
                );
              },
              icon: const Icon(Icons.schedule, size: 16),
              label: const Text(
                'Reschedule',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 1,
              ),
            ),
          ),
        ],
      );
    }
    
    // Side-by-side layout for normal screens
    return Column(
      children: [
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _cancelAppointment(appointment),
                icon: const Icon(Icons.cancel_outlined, size: 16),
                label: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Reschedule feature coming soon!'),
                    ),
                  );
                },
                icon: const Icon(Icons.schedule, size: 16),
                label: const Text(
                  'Reschedule',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 1,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Appointments'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
            Tab(text: 'Cancelled'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAppointments,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAppointmentsList('upcoming'),
                _buildAppointmentsList('past'),
                _buildAppointmentsList('cancelled'),
              ],
            ),
    );
  }

  Widget _buildAppointmentsList(String filter) {
    final filteredAppointments = _filterAppointments(filter);

    if (filteredAppointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No ${filter} appointments',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Your ${filter} appointments will appear here',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAppointments,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredAppointments.length,
        itemBuilder: (context, index) {
          final appointment = filteredAppointments[index];
          return _buildAppointmentCard(appointment);
        },
      ),
    );
  }

  Widget _buildAppointmentCard(Appointment appointment) {
    final isUpcoming =
        appointment.appointmentDate.isAfter(DateTime.now()) &&
        appointment.status != AppointmentStatus.cancelled &&
        appointment.status != AppointmentStatus.completed;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with doctor name and status
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.doctorName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getAppointmentTypeLabel(appointment.type),
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(appointment.status),
              ],
            ),

            const SizedBox(height: 12),

            // Date and time
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                Text(
                  '${appointment.appointmentDate.day}/${appointment.appointmentDate.month}/${appointment.appointmentDate.year}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 16),
                Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  appointment.timeSlot,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),

            if (appointment.reason != null) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.description,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Reason: ${appointment.reason}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ],

            if (appointment.fee > 0) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.payment, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    'Fee: ৳${appointment.fee.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: appointment.isPaid ? Colors.green : Colors.orange,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      appointment.isPaid ? 'Paid' : 'Pending',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // Action buttons with responsive design
            _buildActionButtons(appointment, isUpcoming),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(AppointmentStatus status) {
    Color color;
    String label;

    switch (status) {
      case AppointmentStatus.pending:
        color = Colors.orange;
        label = 'Pending';
        break;
      case AppointmentStatus.confirmed:
        color = Colors.blue;
        label = 'Confirmed';
        break;
      case AppointmentStatus.inProgress:
        color = Colors.green;
        label = 'In Progress';
        break;
      case AppointmentStatus.completed:
        color = Colors.green;
        label = 'Completed';
        break;
      case AppointmentStatus.cancelled:
        color = Colors.red;
        label = 'Cancelled';
        break;
      case AppointmentStatus.noShow:
        color = Colors.grey;
        label = 'No Show';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _getAppointmentTypeLabel(AppointmentType type) {
    switch (type) {
      case AppointmentType.consultation:
        return 'General Consultation';
      case AppointmentType.followUp:
        return 'Follow-up Visit';
      case AppointmentType.emergency:
        return 'Emergency';
      case AppointmentType.checkup:
        return 'Regular Checkup';
      case AppointmentType.procedure:
        return 'Medical Procedure';
    }
  }
}
