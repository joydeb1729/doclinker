import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/doctor_profile.dart';

class DoctorSchedule {
  final String doctorId;
  final String doctorName;
  final DateTime date;
  final List<TimeSlot> availableSlots;
  final Map<String, dynamic> settings;

  DoctorSchedule({
    required this.doctorId,
    required this.doctorName,
    required this.date,
    required this.availableSlots,
    required this.settings,
  });

  factory DoctorSchedule.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DoctorSchedule(
      doctorId: data['doctorId'] ?? '',
      doctorName: data['doctorName'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      availableSlots:
          (data['availableSlots'] as List<dynamic>?)
              ?.map((slot) => TimeSlot.fromMap(slot))
              .toList() ??
          [],
      settings: data['settings'] ?? {},
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'doctorId': doctorId,
      'doctorName': doctorName,
      'date': Timestamp.fromDate(date),
      'availableSlots': availableSlots.map((slot) => slot.toMap()).toList(),
      'settings': settings,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

class TimeSlot {
  final String id;
  final String startTime;
  final String endTime;
  final bool isAvailable;
  final double fee;
  final String? bookedBy;
  final String? appointmentId;

  TimeSlot({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.isAvailable,
    required this.fee,
    this.bookedBy,
    this.appointmentId,
  });

  factory TimeSlot.fromMap(Map<String, dynamic> data) {
    return TimeSlot(
      id: data['id'] ?? '',
      startTime: data['startTime'] ?? '',
      endTime: data['endTime'] ?? '',
      isAvailable: data['isAvailable'] ?? true,
      fee: (data['fee'] ?? 0.0).toDouble(),
      bookedBy: data['bookedBy'],
      appointmentId: data['appointmentId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startTime': startTime,
      'endTime': endTime,
      'isAvailable': isAvailable,
      'fee': fee,
      'bookedBy': bookedBy,
      'appointmentId': appointmentId,
    };
  }

  TimeSlot copyWith({
    String? id,
    String? startTime,
    String? endTime,
    bool? isAvailable,
    double? fee,
    String? bookedBy,
    String? appointmentId,
  }) {
    return TimeSlot(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isAvailable: isAvailable ?? this.isAvailable,
      fee: fee ?? this.fee,
      bookedBy: bookedBy ?? this.bookedBy,
      appointmentId: appointmentId ?? this.appointmentId,
    );
  }
}

class DoctorScheduleService {
  static const String _schedulesCollection = 'doctor_schedules';
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get doctor's schedule for a specific date
  static Future<DoctorSchedule?> getDoctorScheduleForDate(
    String doctorId,
    DateTime date,
  ) async {
    try {
      final dateOnly = DateTime(date.year, date.month, date.day);

      final querySnapshot = await _firestore
          .collection(_schedulesCollection)
          .where('doctorId', isEqualTo: doctorId)
          .where('date', isEqualTo: Timestamp.fromDate(dateOnly))
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return DoctorSchedule.fromFirestore(querySnapshot.docs.first);
      }

      // If no schedule exists, create one based on doctor's profile
      return await _createScheduleForDate(doctorId, date);
    } catch (e) {
      print('❌ Error getting doctor schedule: $e');
      throw Exception('Failed to get doctor schedule: $e');
    }
  }

  /// Create or update schedule for a specific date (public method)
  static Future<DoctorSchedule?> _createScheduleForDate(
    String doctorId,
    DateTime date,
  ) async {
    // Check if schedule already exists to avoid duplicates
    final dateOnly = DateTime(date.year, date.month, date.day);
    final existingQuery = await _firestore
        .collection(_schedulesCollection)
        .where('doctorId', isEqualTo: doctorId)
        .where('date', isEqualTo: Timestamp.fromDate(dateOnly))
        .limit(1)
        .get();

    if (existingQuery.docs.isNotEmpty) {
      return DoctorSchedule.fromFirestore(existingQuery.docs.first);
    }

    // Create new schedule
    return await _createDefaultScheduleForDate(doctorId, date);
  }

  /// Get doctor's schedule for multiple dates
  static Future<List<DoctorSchedule>> getDoctorScheduleForDateRange(
    String doctorId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(_schedulesCollection)
          .where('doctorId', isEqualTo: doctorId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('date')
          .get();

      return querySnapshot.docs
          .map((doc) => DoctorSchedule.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('❌ Error getting doctor schedule range: $e');
      throw Exception('Failed to get doctor schedule range: $e');
    }
  }

  /// Book a specific time slot
  static Future<String> bookTimeSlot({
    required String doctorId,
    required DateTime date,
    required String timeSlotId,
    required String patientId,
    required String patientName,
    required String reason,
    required String appointmentType,
  }) async {
    try {
      final dateOnly = DateTime(date.year, date.month, date.day);

      // Get the schedule document
      final querySnapshot = await _firestore
          .collection(_schedulesCollection)
          .where('doctorId', isEqualTo: doctorId)
          .where('date', isEqualTo: Timestamp.fromDate(dateOnly))
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception('Doctor schedule not found for the selected date');
      }

      final scheduleDoc = querySnapshot.docs.first;
      final schedule = DoctorSchedule.fromFirestore(scheduleDoc);

      // Find the specific time slot
      final slotIndex = schedule.availableSlots.indexWhere(
        (slot) => slot.id == timeSlotId,
      );
      if (slotIndex == -1) {
        throw Exception('Time slot not found');
      }

      final timeSlot = schedule.availableSlots[slotIndex];
      if (!timeSlot.isAvailable) {
        throw Exception('Time slot is no longer available');
      }

      // Create appointment first
      final appointmentData = {
        'patientId': patientId,
        'doctorId': doctorId,
        'patientName': patientName,
        'doctorName': schedule.doctorName,
        'appointmentDate': Timestamp.fromDate(date),
        'timeSlot': '${timeSlot.startTime}-${timeSlot.endTime}',
        'type': appointmentType,
        'status': 'pending',
        'reason': reason,
        'fee': timeSlot.fee,
        'isPaid': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final appointmentRef = await _firestore
          .collection('appointments')
          .add(appointmentData);

      // Update the time slot to mark it as booked
      final updatedSlots = List<TimeSlot>.from(schedule.availableSlots);
      updatedSlots[slotIndex] = timeSlot.copyWith(
        isAvailable: false,
        bookedBy: patientId,
        appointmentId: appointmentRef.id,
      );

      // Update the schedule document
      await scheduleDoc.reference.update({
        'availableSlots': updatedSlots.map((slot) => slot.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Time slot booked successfully: ${appointmentRef.id}');
      return appointmentRef.id;
    } catch (e) {
      print('❌ Error booking time slot: $e');
      throw Exception('Failed to book time slot: $e');
    }
  }

  /// Create schedule for a doctor on a specific date using their profile availability
  static Future<DoctorSchedule> _createDefaultScheduleForDate(
    String doctorId,
    DateTime date,
  ) async {
    try {
      // Get doctor profile to get actual availability and settings
      final doctorDoc = await _firestore
          .collection('doctors')
          .doc(doctorId)
          .get();

      if (!doctorDoc.exists) {
        throw Exception('Doctor profile not found');
      }

      final doctorProfile = DoctorProfile.fromFirestore(doctorDoc);
      final dateOnly = DateTime(date.year, date.month, date.day);

      // Get the day of the week for this date
      final dayNames = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];
      final dayName = dayNames[date.weekday - 1];

      // Get available time slots for this day from doctor's profile
      final dayAvailability = doctorProfile.weeklyAvailability[dayName] ?? [];

      final List<TimeSlot> scheduleSlots = [];

      if (dayAvailability.isNotEmpty) {
        // Use doctor's actual availability
        for (int i = 0; i < dayAvailability.length; i++) {
          final timeSlot = dayAvailability[i];

          // Parse the time slot (assuming format like "09:00-09:30" or "09:00")
          String startTime, endTime;

          if (timeSlot.contains('-')) {
            final parts = timeSlot.split('-');
            startTime = parts[0].trim();
            endTime = parts[1].trim();
          } else {
            // If no end time specified, assume 30-minute slots
            startTime = timeSlot.trim();
            final startParts = startTime.split(':');
            final startHour = int.parse(startParts[0]);
            final startMinute = int.parse(startParts[1]);

            final endDateTime = DateTime(
              2000,
              1,
              1,
              startHour,
              startMinute,
            ).add(const Duration(minutes: 30));
            endTime =
                '${endDateTime.hour.toString().padLeft(2, '0')}:${endDateTime.minute.toString().padLeft(2, '0')}';
          }

          scheduleSlots.add(
            TimeSlot(
              id: '${dayName.toLowerCase()}_${i}_${startTime.replaceAll(':', '')}',
              startTime: startTime,
              endTime: endTime,
              isAvailable: true,
              fee: doctorProfile.consultationFee,
            ),
          );
        }
      } else {
        // If no specific availability set, create default business hours slots
        print(
          '⚠️ No availability set for $dayName, using default business hours',
        );
        for (int hour = 9; hour < 17; hour++) {
          for (int minute = 0; minute < 60; minute += 30) {
            final startTime =
                '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
            final endHour = minute == 30 ? hour + 1 : hour;
            final endMinute = minute == 30 ? 0 : 30;
            final endTime =
                '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}';

            scheduleSlots.add(
              TimeSlot(
                id: '${hour}_${minute}',
                startTime: startTime,
                endTime: endTime,
                isAvailable: true,
                fee: doctorProfile.consultationFee > 0
                    ? doctorProfile.consultationFee
                    : 50.0,
              ),
            );
          }
        }
      }

      final schedule = DoctorSchedule(
        doctorId: doctorId,
        doctorName: doctorProfile.fullName,
        date: dateOnly,
        availableSlots: scheduleSlots,
        settings: {
          'consultationFee': doctorProfile.consultationFee,
          'slotDuration': 30,
          'workingHours': {
            'start': scheduleSlots.isNotEmpty
                ? scheduleSlots.first.startTime
                : '09:00',
            'end': scheduleSlots.isNotEmpty
                ? scheduleSlots.last.endTime
                : '17:00',
          },
          'dayAvailability': dayAvailability,
        },
      );

      // Save to Firestore
      await _firestore
          .collection(_schedulesCollection)
          .add(schedule.toFirestore());

      print(
        '✅ Schedule created for doctor ${doctorProfile.fullName} on ${date.toString()} with ${scheduleSlots.length} slots',
      );
      return schedule;
    } catch (e) {
      print('❌ Error creating doctor schedule: $e');
      throw Exception('Failed to create doctor schedule: $e');
    }
  }

  /// Cancel a booking and make the slot available again
  static Future<void> cancelBooking(
    String doctorId,
    DateTime date,
    String appointmentId,
  ) async {
    try {
      final dateOnly = DateTime(date.year, date.month, date.day);

      // Get the schedule document
      final querySnapshot = await _firestore
          .collection(_schedulesCollection)
          .where('doctorId', isEqualTo: doctorId)
          .where('date', isEqualTo: Timestamp.fromDate(dateOnly))
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final scheduleDoc = querySnapshot.docs.first;
        final schedule = DoctorSchedule.fromFirestore(scheduleDoc);

        // Find and update the slot that was booked for this appointment
        final updatedSlots = schedule.availableSlots.map((slot) {
          if (slot.appointmentId == appointmentId) {
            return slot.copyWith(
              isAvailable: true,
              bookedBy: null,
              appointmentId: null,
            );
          }
          return slot;
        }).toList();

        // Update the schedule document
        await scheduleDoc.reference.update({
          'availableSlots': updatedSlots.map((slot) => slot.toMap()).toList(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      print('✅ Booking cancelled and slot made available');
    } catch (e) {
      print('❌ Error cancelling booking: $e');
      throw Exception('Failed to cancel booking: $e');
    }
  }

  /// Get available slots for next 7 days
  static Future<Map<DateTime, List<TimeSlot>>> getAvailableSlotsForWeek(
    String doctorId,
  ) async {
    final Map<DateTime, List<TimeSlot>> weeklySlots = {};
    final now = DateTime.now();

    for (int i = 0; i < 7; i++) {
      final date = now.add(Duration(days: i));
      final schedule = await getDoctorScheduleForDate(doctorId, date);

      if (schedule != null) {
        final availableSlots = schedule.availableSlots
            .where((slot) => slot.isAvailable)
            .toList();
        weeklySlots[DateTime(date.year, date.month, date.day)] = availableSlots;
      }
    }

    return weeklySlots;
  }

  /// Get doctor's actual availability from their profile
  static Future<Map<String, List<String>>> getDoctorAvailabilityFromProfile(
    String doctorId,
  ) async {
    try {
      final doctorDoc = await _firestore
          .collection('doctors')
          .doc(doctorId)
          .get();

      if (!doctorDoc.exists) {
        throw Exception('Doctor profile not found');
      }

      final doctorProfile = DoctorProfile.fromFirestore(doctorDoc);
      return doctorProfile.weeklyAvailability;
    } catch (e) {
      print('❌ Error getting doctor availability: $e');
      return {};
    }
  }

  /// Check if doctor has availability set for a specific day
  static Future<bool> isDoctorAvailableOnDay(
    String doctorId,
    String dayName,
  ) async {
    try {
      final availability = await getDoctorAvailabilityFromProfile(doctorId);
      return availability.containsKey(dayName) &&
          availability[dayName]!.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Initialize schedules for the next week for a doctor (avoids duplicates)
  static Future<void> initializeWeeklyScheduleForDoctor(String doctorId) async {
    final now = DateTime.now();
    int createdCount = 0;

    for (int i = 0; i < 7; i++) {
      final date = now.add(Duration(days: i));
      final schedule = await _createScheduleForDate(doctorId, date);
      if (schedule != null) createdCount++;
    }

    print(
      '✅ Weekly schedule checked for doctor $doctorId ($createdCount new schedules created)',
    );
  }
}
