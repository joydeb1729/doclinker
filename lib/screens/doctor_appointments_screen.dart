import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app_theme.dart';
import '../models/appointment.dart';
import '../services/appointment_service.dart' as appointment_service;

class DoctorAppointmentsScreen extends ConsumerStatefulWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  ConsumerState<DoctorAppointmentsScreen> createState() =>
      _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState
    extends ConsumerState<DoctorAppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Appointment> _appointments = [];
  Map<String, int> _statistics = {};
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAppointments();
    _loadStatistics();
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
          .AppointmentService.getDoctorAppointments(user.uid);
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

  Future<void> _loadStatistics() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final stats = await appointment_service
          .AppointmentService.getDoctorStatistics(user.uid);
      setState(() {
        _statistics = stats;
      });
    } catch (e) {
      // Handle error silently for statistics
      debugPrint('Error loading statistics: $e');
    }
  }

  List<Appointment> _filterAppointments(String filter) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDay = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );

    switch (filter) {
      case 'today':
        return _appointments.where((apt) {
            final appointmentDay = DateTime(
              apt.appointmentDate.year,
              apt.appointmentDate.month,
              apt.appointmentDate.day,
            );
            return appointmentDay.isAtSameMomentAs(today) &&
                apt.status != AppointmentStatus.cancelled;
          }).toList()
          ..sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));

      case 'upcoming':
        return _appointments
            .where(
              (apt) =>
                  apt.appointmentDate.isAfter(today) &&
                  apt.status != AppointmentStatus.cancelled &&
                  apt.status != AppointmentStatus.completed,
            )
            .toList()
          ..sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));

      case 'pending':
        return _appointments
            .where((apt) => apt.status == AppointmentStatus.pending)
            .toList()
          ..sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));

      case 'date':
        return _appointments.where((apt) {
            final appointmentDay = DateTime(
              apt.appointmentDate.year,
              apt.appointmentDate.month,
              apt.appointmentDate.day,
            );
            return appointmentDay.isAtSameMomentAs(selectedDay) &&
                apt.status != AppointmentStatus.cancelled;
          }).toList()
          ..sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));

      default:
        return _appointments
          ..sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));
    }
  }

  Future<void> _updateAppointmentStatus(
    Appointment appointment,
    AppointmentStatus newStatus,
  ) async {
    try {
      // Show loading state
      setState(() {
        _isLoading = true;
      });

      await appointment_service.AppointmentService.updateAppointmentStatus(
        appointment.id,
        newStatus,
        note: 'Status updated by doctor',
      );

      // Update local appointment status immediately
      final updatedAppointments = _appointments.map((apt) {
        if (apt.id == appointment.id) {
          return Appointment(
            id: apt.id,
            patientId: apt.patientId,
            patientName: apt.patientName,
            doctorId: apt.doctorId,
            doctorName: apt.doctorName,
            appointmentDate: apt.appointmentDate,
            timeSlot: apt.timeSlot,
            status: newStatus, // Update status
            type: apt.type,
            reason: apt.reason,
            symptoms: apt.symptoms,
            fee: apt.fee,
            isPaid: apt.isPaid,
            createdAt: apt.createdAt,
            updatedAt: DateTime.now(),
            notes: apt.notes,
          );
        }
        return apt;
      }).toList();

      setState(() {
        _appointments = updatedAppointments;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Appointment ${newStatus.name} successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Reload from server to ensure consistency
      await _loadAppointments();
      await _loadStatistics();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update appointment: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _updatePaymentStatus(Appointment appointment) async {
    try {
      await appointment_service.AppointmentService.updatePaymentStatus(
        appointment.id,
        true,
      );

      // Update local appointment payment status immediately
      final updatedAppointments = _appointments.map((apt) {
        if (apt.id == appointment.id) {
          return Appointment(
            id: apt.id,
            patientId: apt.patientId,
            patientName: apt.patientName,
            doctorId: apt.doctorId,
            doctorName: apt.doctorName,
            appointmentDate: apt.appointmentDate,
            timeSlot: apt.timeSlot,
            status: apt.status,
            type: apt.type,
            reason: apt.reason,
            symptoms: apt.symptoms,
            fee: apt.fee,
            isPaid: true, // Update payment status
            createdAt: apt.createdAt,
            updatedAt: DateTime.now(),
            notes: apt.notes,
          );
        }
        return apt;
      }).toList();

      setState(() {
        _appointments = updatedAppointments;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment status updated to Paid'),
          backgroundColor: Colors.green,
        ),
      );

      // Reload from server to ensure consistency
      await _loadAppointments();
      await _loadStatistics();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update payment status: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: AppTheme.primaryColor),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        toolbarHeight: 0, // Remove the title area
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Today'),
            Tab(text: 'Upcoming'),
            Tab(text: 'Pending'),
            Tab(text: 'By Date'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadAppointments();
              _loadStatistics();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistics overview
          Container(
            color: Colors.grey.shade50,
            padding: const EdgeInsets.all(16),
            child: _buildStatisticsRow(),
          ),

          // Tab content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAppointmentsList('today'),
                      _buildAppointmentsList('upcoming'),
                      _buildAppointmentsList('pending'),
                      _buildDateAppointmentsList(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Today',
            _statistics['todayCount'] ?? 0,
            Icons.today,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            'Pending',
            _statistics['pendingCount'] ?? 0,
            Icons.hourglass_empty,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            'This Month',
            _statistics['monthlyCount'] ?? 0,
            Icons.calendar_month,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            'Completed',
            _statistics['completedCount'] ?? 0,
            Icons.check_circle,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, int count, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 20),
          const SizedBox(height: 4),
          Text(
            count.toString(),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDateAppointmentsList() {
    return Column(
      children: [
        // Date selector
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Selected Date: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _selectDate,
                icon: const Icon(Icons.calendar_today, size: 16),
                label: const Text('Select Date'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(child: _buildAppointmentsList('date')),
      ],
    );
  }

  Widget _buildAppointmentsList(String filter) {
    final filteredAppointments = _filterAppointments(filter);

    if (filteredAppointments.isEmpty) {
      String emptyMessage = 'No appointments';
      IconData emptyIcon = Icons.calendar_today_outlined;

      switch (filter) {
        case 'today':
          emptyMessage = 'No appointments today';
          emptyIcon = Icons.today_outlined;
          break;
        case 'upcoming':
          emptyMessage = 'No upcoming appointments';
          emptyIcon = Icons.schedule_outlined;
          break;
        case 'pending':
          emptyMessage = 'No pending appointments';
          emptyIcon = Icons.hourglass_empty_outlined;
          break;
        case 'date':
          emptyMessage = 'No appointments on selected date';
          emptyIcon = Icons.event_available_outlined;
          break;
      }

      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(emptyIcon, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(
                emptyMessage,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Your ${filter == 'date' ? 'selected date' : filter} appointments will appear here',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                textAlign: TextAlign.center,
              ),
            ],
          ),
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
    final now = DateTime.now();

    // Parse time from time slot (handle formats like "10:00 AM - 11:00 AM" or "10:00")
    DateTime appointmentDateTime;
    try {
      // Extract the start time from time slot
      String timeString = appointment.timeSlot;

      // If it's a range (contains '-'), take the first part
      if (timeString.contains('-')) {
        timeString = timeString.split('-')[0].trim();
      }

      // Remove AM/PM and parse
      timeString = timeString
          .replaceAll(RegExp(r'\s*(AM|PM)\s*', caseSensitive: false), '')
          .trim();

      final timeParts = timeString.split(':');
      if (timeParts.length >= 2) {
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);

        appointmentDateTime = DateTime(
          appointment.appointmentDate.year,
          appointment.appointmentDate.month,
          appointment.appointmentDate.day,
          hour,
          minute,
        );
      } else {
        // Fallback: use date only
        appointmentDateTime = appointment.appointmentDate;
      }
    } catch (e) {
      // Fallback: use date only if time parsing fails
      appointmentDateTime = appointment.appointmentDate;
    }

    final isToday = DateTime(
      appointment.appointmentDate.year,
      appointment.appointmentDate.month,
      appointment.appointmentDate.day,
    ).isAtSameMomentAs(DateTime(now.year, now.month, now.day));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with patient name and status
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.patientName,
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

            // Date and time with urgency indicator
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                Flexible(
                  flex: 2,
                  child: Text(
                    '${appointment.appointmentDate.day}/${appointment.appointmentDate.month}/${appointment.appointmentDate.year}',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: isToday ? AppTheme.primaryColor : null,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Flexible(
                  flex: 3,
                  child: Text(
                    appointment.timeSlot,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color:
                          isToday &&
                              appointmentDateTime.isBefore(
                                now.add(const Duration(hours: 1)),
                              )
                          ? Colors.red
                          : null,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isToday &&
                    appointmentDateTime.isBefore(
                      now.add(const Duration(hours: 1)),
                    ))
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Soon',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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
                  Expanded(
                    child: Text(
                      'Fee: ৳${appointment.fee.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
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
              if (!appointment.isPaid) ...[
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => _updatePaymentStatus(appointment),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.green.shade700),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.payment, size: 14, color: Colors.white),
                          SizedBox(width: 6),
                          Text(
                            'Mark as Paid',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],

            // Action buttons based on status
            if (appointment.status == AppointmentStatus.pending) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _updateAppointmentStatus(
                        appointment,
                        AppointmentStatus.cancelled,
                      ),
                      icon: const Icon(Icons.cancel_outlined, size: 16),
                      label: const Text(
                        'Decline',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateAppointmentStatus(
                        appointment,
                        AppointmentStatus.confirmed,
                      ),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text(
                        'Confirm',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (appointment.status == AppointmentStatus.confirmed &&
                isToday) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateAppointmentStatus(
                        appointment,
                        AppointmentStatus.inProgress,
                      ),
                      icon: const Icon(Icons.play_arrow, size: 16),
                      label: const Text(
                        'Start',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (appointment.status == AppointmentStatus.inProgress) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateAppointmentStatus(
                        appointment,
                        AppointmentStatus.completed,
                      ),
                      icon: const Icon(Icons.check_circle, size: 16),
                      label: const Text(
                        'Complete',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
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
