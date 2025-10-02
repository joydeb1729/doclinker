import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app_theme.dart';
import '../models/doctor_profile.dart';
import '../models/appointment.dart';
import '../services/appointment_service.dart' as appointment_service;

class BookAppointmentScreen extends ConsumerStatefulWidget {
  final DoctorProfile doctor;

  const BookAppointmentScreen({super.key, required this.doctor});

  @override
  ConsumerState<BookAppointmentScreen> createState() =>
      _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends ConsumerState<BookAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _symptomsController = TextEditingController();

  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  AppointmentType _selectedType = AppointmentType.consultation;
  bool _isLoading = false;
  bool _isLoadingSlots = false;
  List<String> _availableTimeSlots = [];

  @override
  void dispose() {
    _reasonController.dispose();
    _symptomsController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
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
        _selectedTimeSlot = null; // Reset time slot when date changes
        _availableTimeSlots = [];
      });
      _loadAvailableTimeSlots();
    }
  }

  List<String> _getAvailableTimeSlots() {
    if (_selectedDate == null) return [];

    final dayName = _getDayName(_selectedDate!.weekday);
    return widget.doctor.weeklyAvailability[dayName] ?? [];
  }

  Future<void> _loadAvailableTimeSlots() async {
    if (_selectedDate == null) return;

    setState(() {
      _isLoadingSlots = true;
    });

    try {
      final slots =
          await appointment_service.AppointmentService.getAvailableTimeSlots(
            widget.doctor.uid,
            _selectedDate!,
          );

      setState(() {
        _availableTimeSlots = slots;
        _isLoadingSlots = false;
      });
    } catch (e) {
      setState(() {
        _availableTimeSlots = [];
        _isLoadingSlots = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading available slots: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return 'Monday';
    }
  }

  Future<void> _bookAppointment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null || _selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select date and time'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to book an appointment'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final appointmentId =
          await appointment_service.AppointmentService.createAppointment(
            patientId: user.uid,
            doctorId: widget.doctor.uid,
            appointmentDate: _selectedDate!,
            timeSlot: _selectedTimeSlot!,
            type: _selectedType,
            reason: _reasonController.text.trim().isEmpty
                ? null
                : _reasonController.text.trim(),
            symptoms: _symptomsController.text.trim().isEmpty
                ? null
                : _symptomsController.text.trim(),
            consultationFee: widget.doctor.consultationFee,
          );

      if (mounted) {
        // Show success dialog with appointment details
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Appointment Booked!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your appointment has been successfully booked.'),
                const SizedBox(height: 8),
                Text(
                  'Appointment ID: $appointmentId',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text('Doctor: Dr. ${widget.doctor.fullName}'),
                Text(
                  'Date: ${_selectedDate?.day}/${_selectedDate?.month}/${_selectedDate?.year}',
                ),
                Text('Time: $_selectedTimeSlot'),
                Text(
                  'Fee: ৳${widget.doctor.consultationFee.toStringAsFixed(2)}',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Go back to previous screen
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to book appointment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Book Appointment'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildDoctorCard(),
              const SizedBox(height: 24),
              _buildAppointmentForm(),
              const SizedBox(height: 32),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _bookAppointment,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text('Book Appointment'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                child: Text(
                  widget.doctor.fullName.isNotEmpty
                      ? widget.doctor.fullName[0].toUpperCase()
                      : 'D',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dr. ${widget.doctor.fullName}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.doctor.specializationsText,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.doctor.hospitalAffiliation,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.star, color: Colors.orange, size: 16),
              const SizedBox(width: 4),
              Text(
                widget.doctor.averageRating.toStringAsFixed(1),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 16),
              Icon(Icons.work_outline, color: AppTheme.textSecondary, size: 16),
              const SizedBox(width: 4),
              Text(
                '${widget.doctor.yearsOfExperience} years exp.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(width: 16),
              Icon(Icons.attach_money, color: AppTheme.textSecondary, size: 16),
              const SizedBox(width: 4),
              Text(
                '৳${widget.doctor.consultationFee}',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Appointment Details',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // Appointment Type
          const Text(
            'Appointment Type',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<AppointmentType>(
            value: _selectedType,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.medical_services_outlined),
            ),
            items: AppointmentType.values.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(_getTypeDisplayName(type)),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedType = value;
                });
              }
            },
          ),

          const SizedBox(height: 16),

          // Date Selection
          const Text(
            'Select Date',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _selectDate,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined),
                  const SizedBox(width: 12),
                  Text(
                    _selectedDate != null
                        ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                        : 'Select appointment date',
                    style: TextStyle(
                      color: _selectedDate != null ? Colors.black : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Time Slot Selection
          const Text(
            'Select Time',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          if (_selectedDate != null) ...[
            if (_getAvailableTimeSlots().isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: const Text(
                  'No available time slots for selected date',
                  style: TextStyle(color: Colors.red),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _getAvailableTimeSlots().map((timeSlot) {
                  final isSelected = _selectedTimeSlot == timeSlot;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedTimeSlot = timeSlot),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryColor
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        timeSlot,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontWeight: isSelected
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
          ] else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Text('Please select a date first'),
            ),

          const SizedBox(height: 16),

          // Reason for visit
          TextFormField(
            controller: _reasonController,
            decoration: const InputDecoration(
              labelText: 'Reason for Visit*',
              prefixIcon: Icon(Icons.edit_note_outlined),
            ),
            maxLines: 2,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please provide a reason for the visit';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Symptoms (optional)
          TextFormField(
            controller: _symptomsController,
            decoration: const InputDecoration(
              labelText: 'Symptoms (Optional)',
              prefixIcon: Icon(Icons.sick_outlined),
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  String _getTypeDisplayName(AppointmentType type) {
    switch (type) {
      case AppointmentType.consultation:
        return 'Consultation';
      case AppointmentType.followUp:
        return 'Follow-up';
      case AppointmentType.emergency:
        return 'Emergency';
      case AppointmentType.checkup:
        return 'Check-up';
      case AppointmentType.procedure:
        return 'Procedure';
    }
  }
}
