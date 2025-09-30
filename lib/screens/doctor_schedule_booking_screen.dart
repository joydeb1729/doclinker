import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app_theme.dart';
import '../services/doctor_matching_service.dart';
import '../services/doctor_availability_service.dart';
import '../models/appointment.dart';

class DoctorScheduleBookingScreen extends ConsumerStatefulWidget {
  final MatchedDoctor doctor;

  const DoctorScheduleBookingScreen({super.key, required this.doctor});

  @override
  ConsumerState<DoctorScheduleBookingScreen> createState() =>
      _DoctorScheduleBookingScreenState();
}

class _DoctorScheduleBookingScreenState
    extends ConsumerState<DoctorScheduleBookingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<DateTime, List<AvailableSlot>> _weeklySchedule = {};
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();
  AvailableSlot? _selectedSlot;

  final TextEditingController _reasonController = TextEditingController();
  AppointmentType _selectedAppointmentType = AppointmentType.consultation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _loadWeeklySchedule();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadWeeklySchedule() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final Map<DateTime, List<AvailableSlot>> scheduleMap = {};
      final today = DateTime.now();

      // Load schedule for next 7 days
      for (int i = 0; i < 7; i++) {
        final date = today.add(Duration(days: i));
        final slots = await DoctorAvailabilityService.getDoctorAvailableSlots(
          widget.doctor.id,
          date,
        );
        // Use date-only key to match retrieval logic
        final dateKey = DateTime(date.year, date.month, date.day);
        scheduleMap[dateKey] = slots;
      }

      setState(() {
        _weeklySchedule = scheduleMap;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading weekly schedule: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load doctor availability: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _bookAppointment() async {
    if (_selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a time slot')),
      );
      return;
    }

    if (_reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a reason for the appointment'),
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to book an appointment')),
      );
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      await DoctorAvailabilityService.bookTimeSlot(
        doctorId: widget.doctor.id,
        doctorName: widget.doctor.name,
        date: _selectedDate,
        timeSlot: _selectedSlot!.time,
        patientId: user.uid,
        patientName: user.displayName ?? 'Unknown Patient',
        reason: _reasonController.text.trim(),
        appointmentType: _selectedAppointmentType.name,
        fee: _selectedSlot!.fee,
      );

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Appointment booked successfully! Waiting for doctor confirmation.',
            ),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.of(context).pop(); // Go back to previous screen
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to book appointment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: const Text('Book Appointment'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildDoctorInfo(),
                _buildDateTabs(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        SizedBox(
                          height: _selectedSlot != null
                              ? 300
                              : 500, // Adjust height based on booking section
                          child: _buildScheduleView(),
                        ),
                        if (_selectedSlot != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: _buildBookingSection(),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildDoctorInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppTheme.primaryColor,
                child: Text(
                  widget.doctor.name.substring(0, 2).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.doctor.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.doctor.specialty,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${widget.doctor.consultationFee.toStringAsFixed(0)} per consultation',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'ℹ️ Times and prices shown are from doctor\'s profile',
              style: TextStyle(fontSize: 12, color: AppTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTabs() {
    final today = DateTime.now();
    final dates = List.generate(7, (index) => today.add(Duration(days: index)));

    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        isScrollable: true, // Make tabs scrollable to prevent overflow
        labelColor: AppTheme.primaryColor,
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: AppTheme.primaryColor,
        tabAlignment: TabAlignment.start,
        onTap: (index) {
          setState(() {
            _selectedDate = dates[index];
            _selectedSlot = null; // Clear selection when changing date
          });
        },
        tabs: dates
            .map(
              (date) => Tab(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _getDayName(date.weekday),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        date.day.toString(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildScheduleView() {
    return SizedBox(
      height: _selectedSlot != null ? 300 : 500,
      child: TabBarView(
        controller: _tabController,
        children: List.generate(7, (index) {
          final date = DateTime.now().add(Duration(days: index));
          final slots =
              _weeklySchedule[DateTime(date.year, date.month, date.day)] ?? [];

          if (slots.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.schedule, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No availability on ${_getDayName(date.weekday)}',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return _buildTimeSlotsList(slots, date);
        }),
      ),
    );
  }

  Widget _buildTimeSlotsList(List<AvailableSlot> slots, DateTime date) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available Times for ${_getFormattedDate(date)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 2.8, // Increased to give more height
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
              ),
              itemCount: slots.length,
              itemBuilder: (context, index) {
                final slot = slots[index];
                final isSelected = _selectedSlot?.id == slot.id;
                final isBooked = slot.isBooked;

                return GestureDetector(
                  onTap: isBooked
                      ? null
                      : () {
                          setState(() {
                            _selectedDate = date;
                            _selectedSlot = slot;
                          });
                        },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isBooked
                          ? Colors.grey[300]
                          : isSelected
                          ? AppTheme.primaryColor
                          : Colors.white,
                      border: Border.all(
                        color: isBooked
                            ? Colors.grey[400]!
                            : isSelected
                            ? AppTheme.primaryColor
                            : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              slot.time,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isBooked
                                    ? Colors.grey[600]
                                    : isSelected
                                    ? Colors.white
                                    : AppTheme.textPrimary,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Flexible(
                            child: Text(
                              isBooked
                                  ? 'Booked'
                                  : '\$${slot.fee.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 9,
                                color: isBooked
                                    ? Colors.grey[600]
                                    : isSelected
                                    ? Colors.white
                                    : AppTheme.primaryColor,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Booking Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // Selected slot info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppTheme.primaryColor.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.schedule, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Selected: ${_selectedSlot!.time}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '\$${_selectedSlot!.fee.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Appointment type
          const Text(
            'Appointment Type',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<AppointmentType>(
            value: _selectedAppointmentType,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: AppTheme.primaryColor,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            items: AppointmentType.values.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(_getAppointmentTypeDisplay(type)),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedAppointmentType = value;
                });
              }
            },
          ),

          const SizedBox(height: 16),

          // Reason field
          const Text(
            'Reason for Visit',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _reasonController,
            maxLines: 3,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: AppTheme.primaryColor,
                  width: 2,
                ),
              ),
              hintText:
                  'Describe your symptoms or reason for the appointment...',
              hintStyle: TextStyle(color: Colors.grey.shade500),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),

          const SizedBox(height: 16),

          // Book button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _bookAppointment,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                elevation: 2,
                shadowColor: AppTheme.primaryColor.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Book Appointment',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  String _getFormattedDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  String _getAppointmentTypeDisplay(AppointmentType type) {
    switch (type) {
      case AppointmentType.consultation:
        return 'Consultation';
      case AppointmentType.followUp:
        return 'Follow-up';
      case AppointmentType.checkup:
        return 'Check-up';
      case AppointmentType.procedure:
        return 'Procedure';
      case AppointmentType.emergency:
        return 'Emergency';
    }
  }
}
