import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/doctor_profile.dart';
import '../models/appointment.dart';

class TimeSlotUtils {
  // Convert time slot string to DateTime range for a specific date
  static Map<String, DateTime>? parseTimeSlot(String timeSlot, DateTime date) {
    try {
      final parts = timeSlot.split(' - ');
      if (parts.length != 2) return null;

      final startTime = _parseTimeString(parts[0].trim(), date);
      final endTime = _parseTimeString(parts[1].trim(), date);

      if (startTime == null || endTime == null) return null;

      return {'start': startTime, 'end': endTime};
    } catch (e) {
      log('Error parsing time slot "$timeSlot": $e');
      return null;
    }
  }

  // Parse time string (e.g., "09:00") and combine with date
  static DateTime? _parseTimeString(String timeStr, DateTime date) {
    try {
      final parts = timeStr.split(':');
      if (parts.length != 2) return null;

      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);

      if (hour == null || minute == null) return null;
      if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;

      return DateTime(date.year, date.month, date.day, hour, minute);
    } catch (e) {
      log('Error parsing time string "$timeStr": $e');
      return null;
    }
  }

  // Generate time slots for a given day from doctor's weekly availability
  static List<String> generateDayTimeSlots(
    Map<String, List<String>> weeklyAvailability,
    DateTime date,
  ) {
    final dayName = _getDayName(date.weekday);
    return weeklyAvailability[dayName] ?? [];
  }

  // Get day name from weekday number
  static String _getDayName(int weekday) {
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

  // Check for time slot overlaps
  static bool hasOverlap(String slot1, String slot2, DateTime date) {
    final range1 = parseTimeSlot(slot1, date);
    final range2 = parseTimeSlot(slot2, date);

    if (range1 == null || range2 == null) return false;

    final start1 = range1['start']!;
    final end1 = range1['end']!;
    final start2 = range2['start']!;
    final end2 = range2['end']!;

    // Check if any part of the ranges overlap
    return start1.isBefore(end2) && start2.isBefore(end1);
  }

  // Validate if time slot is valid (start before end, reasonable duration)
  static bool isValidTimeSlot(String timeSlot, DateTime date) {
    final range = parseTimeSlot(timeSlot, date);
    if (range == null) return false;

    final start = range['start']!;
    final end = range['end']!;

    // Start must be before end
    if (!start.isBefore(end)) return false;

    // Duration should be reasonable (15 minutes to 4 hours)
    final duration = end.difference(start);
    const minDuration = Duration(minutes: 15);
    const maxDuration = Duration(hours: 4);

    return duration >= minDuration && duration <= maxDuration;
  }

  // Check if a time slot is in the future
  static bool isFutureTimeSlot(String timeSlot, DateTime date) {
    final range = parseTimeSlot(timeSlot, date);
    if (range == null) return false;

    final start = range['start']!;
    return start.isAfter(DateTime.now());
  }

  // Get next available date for a doctor
  static DateTime? getNextAvailableDate(
    Map<String, List<String>> weeklyAvailability, {
    int maxDaysLookahead = 30,
  }) {
    final now = DateTime.now();

    for (int i = 1; i <= maxDaysLookahead; i++) {
      final date = now.add(Duration(days: i));
      final dayName = _getDayName(date.weekday);

      if (weeklyAvailability.containsKey(dayName) &&
          weeklyAvailability[dayName]!.isNotEmpty) {
        return date;
      }
    }

    return null;
  }
}

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AppointmentService _appointmentService = AppointmentService();
  final DoctorService _doctorService = DoctorService();

  // Get available time slots for a doctor on a specific date
  Future<List<String>> getAvailableTimeSlots(
    String doctorId,
    DateTime date,
  ) async {
    try {
      // Get doctor's profile to access weekly availability
      final doctorProfile = await _doctorService.getDoctorProfile(doctorId);
      if (doctorProfile == null) {
        throw Exception('Doctor not found');
      }

      // Generate time slots for the day
      final allTimeSlots = TimeSlotUtils.generateDayTimeSlots(
        doctorProfile.weeklyAvailability,
        date,
      );

      // Filter out past time slots for today
      final futureSlots = allTimeSlots.where((slot) {
        return TimeSlotUtils.isFutureTimeSlot(slot, date);
      }).toList();

      // Get already booked slots
      final bookedSlots = await _getBookedTimeSlots(doctorId, date);

      // Return available slots
      return futureSlots.where((slot) => !bookedSlots.contains(slot)).toList();
    } catch (e) {
      throw Exception('Failed to get available time slots: $e');
    }
  }

  // Book an appointment with transaction safety
  Future<String> bookAppointment({
    required String patientId,
    required String patientName,
    required String doctorId,
    required String doctorName,
    required DateTime appointmentDate,
    required String timeSlot,
    String? symptoms,
    AppointmentType type = AppointmentType.consultation,
  }) async {
    try {
      // Validate time slot
      if (!TimeSlotUtils.isValidTimeSlot(timeSlot, appointmentDate)) {
        throw Exception('Invalid time slot format');
      }

      // Check if slot is in the future
      if (!TimeSlotUtils.isFutureTimeSlot(timeSlot, appointmentDate)) {
        throw Exception('Cannot book appointments in the past');
      }

      // Get doctor profile for fee information
      final doctorProfile = await _doctorService.getDoctorProfile(doctorId);
      if (doctorProfile == null) {
        throw Exception('Doctor not found');
      }

      // Create appointment
      final appointment = Appointment(
        id: '', // Will be set by AppointmentService
        doctorId: doctorId,
        patientId: patientId,
        doctorName: doctorName,
        patientName: patientName,
        appointmentDate: appointmentDate,
        timeSlot: timeSlot,
        type: type,
        status: AppointmentStatus.pending,
        symptoms: symptoms,
        fee: doctorProfile.consultationFee,
        isPaid: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Create appointment with transaction safety (handled in AppointmentService)
      return await _appointmentService.createAppointment(appointment);
    } catch (e) {
      throw Exception('Failed to book appointment: $e');
    }
  }

  // Get booked time slots for a doctor on a specific date
  Future<Set<String>> _getBookedTimeSlots(
    String doctorId,
    DateTime date,
  ) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final querySnapshot = await _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .where(
            'appointmentDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where(
            'appointmentDate',
            isLessThanOrEqualTo: Timestamp.fromDate(endOfDay),
          )
          .where('status', whereIn: ['pending', 'confirmed'])
          .get();

      return querySnapshot.docs
          .map((doc) => doc.data()['timeSlot'] as String)
          .toSet();
    } catch (e) {
      throw Exception('Failed to get booked time slots: $e');
    }
  }

  // Cancel appointment
  Future<void> cancelAppointment(String appointmentId) async {
    try {
      await _appointmentService.updateAppointmentStatus(
        appointmentId,
        AppointmentStatus.cancelled,
      );
    } catch (e) {
      throw Exception('Failed to cancel appointment: $e');
    }
  }

  // Reschedule appointment
  Future<void> rescheduleAppointment(
    String appointmentId,
    DateTime newDate,
    String newTimeSlot,
  ) async {
    try {
      // Get current appointment
      final appointment = await _appointmentService.getAppointment(
        appointmentId,
      );
      if (appointment == null) {
        throw Exception('Appointment not found');
      }

      // Validate new time slot
      if (!TimeSlotUtils.isValidTimeSlot(newTimeSlot, newDate)) {
        throw Exception('Invalid time slot format');
      }

      if (!TimeSlotUtils.isFutureTimeSlot(newTimeSlot, newDate)) {
        throw Exception('Cannot reschedule to past time');
      }

      // Check availability of new slot
      final availableSlots = await getAvailableTimeSlots(
        appointment.doctorId,
        newDate,
      );
      if (!availableSlots.contains(newTimeSlot)) {
        throw Exception('Selected time slot is not available');
      }

      // Update appointment with transaction
      await _firestore.runTransaction((transaction) async {
        final appointmentRef = _firestore
            .collection('appointments')
            .doc(appointmentId);

        // Check again within transaction that slot is still available
        final conflictingQuery = await _firestore
            .collection('appointments')
            .where('doctorId', isEqualTo: appointment.doctorId)
            .where('appointmentDate', isEqualTo: Timestamp.fromDate(newDate))
            .where('timeSlot', isEqualTo: newTimeSlot)
            .where('status', whereIn: ['pending', 'confirmed'])
            .get();

        if (conflictingQuery.docs.isNotEmpty) {
          throw Exception('Time slot is no longer available');
        }

        transaction.update(appointmentRef, {
          'appointmentDate': Timestamp.fromDate(newDate),
          'timeSlot': newTimeSlot,
          'updatedAt': Timestamp.now(),
        });
      });
    } catch (e) {
      throw Exception('Failed to reschedule appointment: $e');
    }
  }

  // Get doctor's schedule for a date range
  Future<Map<DateTime, List<String>>> getDoctorSchedule(
    String doctorId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final doctorProfile = await _doctorService.getDoctorProfile(doctorId);
      if (doctorProfile == null) {
        throw Exception('Doctor not found');
      }

      final schedule = <DateTime, List<String>>{};
      final current = DateTime(startDate.year, startDate.month, startDate.day);
      final end = DateTime(endDate.year, endDate.month, endDate.day);

      while (!current.isAfter(end)) {
        final availableSlots = await getAvailableTimeSlots(doctorId, current);
        if (availableSlots.isNotEmpty) {
          schedule[current] = availableSlots;
        }
        current.add(const Duration(days: 1));
      }

      return schedule;
    } catch (e) {
      throw Exception('Failed to get doctor schedule: $e');
    }
  }
}
