import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appointment.dart';
import '../models/doctor_profile.dart';
import '../models/patient_profile.dart';

// Simple UserProfile class for appointments (kept for backward compatibility)
class UserProfile {
  final String uid;
  final String name;
  final String email;
  final bool isDoctor;
  final DateTime createdAt;

  UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.isDoctor,
    required this.createdAt,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      uid: data['uid'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      isDoctor: data['isDoctor'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// Comprehensive service for managing appointments in Firestore
class AppointmentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _appointmentsCollection = 'appointments';
  static const String _doctorProfilesCollection = 'doctor_profiles';
  static const String _usersCollection = 'users';

  /// Create a new appointment
  static Future<String> createAppointment({
    required String patientId,
    required String doctorId,
    required DateTime appointmentDate,
    required String timeSlot,
    required AppointmentType type,
    String? reason,
    String? symptoms,
    double? consultationFee,
  }) async {
    try {
      // Get patient and doctor information
      // First try to get patient from patient_profiles collection
      final patientProfileDoc = await _firestore
          .collection('patient_profiles')
          .doc(patientId)
          .get();

      String patientName;
      if (patientProfileDoc.exists) {
        final patientProfile = PatientProfile.fromFirestore(patientProfileDoc);
        patientName = patientProfile.fullName;
      } else {
        // Fall back to users collection for backward compatibility
        final patientDoc = await _firestore
            .collection(_usersCollection)
            .doc(patientId)
            .get();

        if (!patientDoc.exists) {
          throw Exception('Patient profile not found');
        }

        final userProfile = UserProfile.fromFirestore(patientDoc);
        patientName = userProfile.name;
      }

      final doctorDoc = await _firestore
          .collection(_doctorProfilesCollection)
          .doc(doctorId)
          .get();

      if (!doctorDoc.exists) {
        throw Exception('Doctor profile not found');
      }

      final doctorProfile = DoctorProfile.fromFirestore(doctorDoc);

      // Check if time slot is available
      final isAvailable = await isTimeSlotAvailable(
        doctorId,
        appointmentDate,
        timeSlot,
      );
      if (!isAvailable) {
        throw Exception('Time slot is not available');
      }

      // Create appointment document
      final appointmentRef = _firestore
          .collection(_appointmentsCollection)
          .doc();
      final appointment = Appointment(
        id: appointmentRef.id,
        doctorId: doctorId,
        patientId: patientId,
        doctorName: doctorProfile.fullName,
        patientName: patientName,
        appointmentDate: appointmentDate,
        timeSlot: timeSlot,
        type: type,
        status: AppointmentStatus.pending,
        reason: reason,
        symptoms: symptoms,
        fee: consultationFee ?? doctorProfile.consultationFee,
        isPaid: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        patientPhone: null, // Add phone to UserProfile if needed
        doctorPhone: null, // Add phone to DoctorProfile if needed
      );

      await appointmentRef.set(appointment.toFirestore());

      print('✅ Appointment created successfully: ${appointmentRef.id}');
      return appointmentRef.id;
    } catch (e) {
      print('❌ Error creating appointment: $e');
      throw Exception('Failed to create appointment: $e');
    }
  }

  /// Check if a time slot is available for a doctor
  static Future<bool> isTimeSlotAvailable(
    String doctorId,
    DateTime date,
    String timeSlot,
  ) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final querySnapshot = await _firestore
          .collection(_appointmentsCollection)
          .where('doctorId', isEqualTo: doctorId)
          .where(
            'appointmentDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where(
            'appointmentDate',
            isLessThanOrEqualTo: Timestamp.fromDate(endOfDay),
          )
          .where('timeSlot', isEqualTo: timeSlot)
          .where(
            'status',
            whereIn: [
              AppointmentStatus.pending.name,
              AppointmentStatus.confirmed.name,
              AppointmentStatus.inProgress.name,
            ],
          )
          .get();

      return querySnapshot.docs.isEmpty;
    } catch (e) {
      print('❌ Error checking time slot availability: $e');
      return false;
    }
  }

  /// Get appointments for a patient
  static Future<List<Appointment>> getPatientAppointments(
    String patientId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(_appointmentsCollection)
          .where('patientId', isEqualTo: patientId)
          .get();

      final appointments = querySnapshot.docs
          .map((doc) => Appointment.fromFirestore(doc))
          .toList();

      // Sort on client side to avoid composite index
      appointments.sort(
        (a, b) => b.appointmentDate.compareTo(a.appointmentDate),
      );
      return appointments;
    } catch (e) {
      print('❌ Error getting patient appointments: $e');
      throw Exception('Failed to get patient appointments: $e');
    }
  }

  /// Get appointments for a doctor
  static Future<List<Appointment>> getDoctorAppointments(
    String doctorId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(_appointmentsCollection)
          .where('doctorId', isEqualTo: doctorId)
          .get();

      final appointments = querySnapshot.docs
          .map((doc) => Appointment.fromFirestore(doc))
          .toList();

      // Sort on client side to avoid composite index
      appointments.sort(
        (a, b) => a.appointmentDate.compareTo(b.appointmentDate),
      );
      return appointments;
    } catch (e) {
      print('❌ Error getting doctor appointments: $e');
      throw Exception('Failed to get doctor appointments: $e');
    }
  }

  /// Get upcoming appointments for a doctor (today and future)
  static Future<List<Appointment>> getDoctorUpcomingAppointments(
    String doctorId,
  ) async {
    try {
      final today = DateTime.now();
      final startOfToday = DateTime(today.year, today.month, today.day);

      final querySnapshot = await _firestore
          .collection(_appointmentsCollection)
          .where('doctorId', isEqualTo: doctorId)
          .get();

      final appointments = querySnapshot.docs
          .map((doc) => Appointment.fromFirestore(doc))
          .where((appointment) {
            final appointmentDay = DateTime(
              appointment.appointmentDate.year,
              appointment.appointmentDate.month,
              appointment.appointmentDate.day,
            );
            return appointmentDay.isAtSameMomentAs(startOfToday) ||
                appointmentDay.isAfter(startOfToday);
          })
          .where(
            (appointment) => [
              AppointmentStatus.pending,
              AppointmentStatus.confirmed,
              AppointmentStatus.inProgress,
            ].contains(appointment.status),
          )
          .toList();

      // Sort on client side to avoid composite index
      appointments.sort(
        (a, b) => a.appointmentDate.compareTo(b.appointmentDate),
      );
      return appointments;
    } catch (e) {
      print('❌ Error getting doctor upcoming appointments: $e');
      throw Exception('Failed to get upcoming appointments: $e');
    }
  }

  /// Get appointments for a specific date (for doctors)
  static Future<List<Appointment>> getDoctorAppointmentsByDate(
    String doctorId,
    DateTime date,
  ) async {
    try {
      final targetDate = DateTime(date.year, date.month, date.day);

      final querySnapshot = await _firestore
          .collection(_appointmentsCollection)
          .where('doctorId', isEqualTo: doctorId)
          .get();

      final appointments = querySnapshot.docs
          .map((doc) => Appointment.fromFirestore(doc))
          .where((appointment) {
            final appointmentDay = DateTime(
              appointment.appointmentDate.year,
              appointment.appointmentDate.month,
              appointment.appointmentDate.day,
            );
            return appointmentDay == targetDate;
          })
          .toList();

      // Sort on client side to avoid composite index
      appointments.sort(
        (a, b) => a.appointmentDate.compareTo(b.appointmentDate),
      );
      return appointments;
    } catch (e) {
      print('❌ Error getting appointments by date: $e');
      throw Exception('Failed to get appointments by date: $e');
    }
  }

  /// Update appointment status
  static Future<void> updateAppointmentStatus(
    String appointmentId,
    AppointmentStatus newStatus, {
    String? note,
  }) async {
    try {
      final updateData = {
        'status': newStatus.name,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (note != null) {
        updateData['notes'] = note;
      }

      await _firestore
          .collection(_appointmentsCollection)
          .doc(appointmentId)
          .update(updateData);

      print(
        '✅ Appointment status updated: $appointmentId -> ${newStatus.name}',
      );
    } catch (e) {
      print('❌ Error updating appointment status: $e');
      throw Exception('Failed to update appointment status: $e');
    }
  }

  /// Update appointment payment status
  static Future<void> updatePaymentStatus(
    String appointmentId,
    bool isPaid,
  ) async {
    try {
      final updateData = {
        'isPaid': isPaid,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (isPaid) {
        updateData['paidAt'] = FieldValue.serverTimestamp();
      }

      await _firestore
          .collection(_appointmentsCollection)
          .doc(appointmentId)
          .update(updateData);

      print(
        '✅ Payment status updated: $appointmentId -> ${isPaid ? 'Paid' : 'Pending'}',
      );
    } catch (e) {
      print('❌ Error updating payment status: $e');
      throw Exception('Failed to update payment status: $e');
    }
  }

  /// Cancel appointment
  static Future<void> cancelAppointment(
    String appointmentId, {
    String? reason,
  }) async {
    try {
      final updateData = {
        'status': AppointmentStatus.cancelled.name,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (reason != null) {
        updateData['cancellationReason'] = reason;
      }

      await _firestore
          .collection(_appointmentsCollection)
          .doc(appointmentId)
          .update(updateData);

      print('✅ Appointment cancelled: $appointmentId');
    } catch (e) {
      print('❌ Error cancelling appointment: $e');
      throw Exception('Failed to cancel appointment: $e');
    }
  }

  /// Complete appointment with diagnosis and prescription
  static Future<void> completeAppointment({
    required String appointmentId,
    String? diagnosis,
    String? prescription,
    String? notes,
  }) async {
    try {
      await _firestore
          .collection(_appointmentsCollection)
          .doc(appointmentId)
          .update({
            'status': AppointmentStatus.completed.name,
            'diagnosis': diagnosis,
            'prescription': prescription,
            'notes': notes,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      print('✅ Appointment completed: $appointmentId');
    } catch (e) {
      print('❌ Error completing appointment: $e');
      throw Exception('Failed to complete appointment: $e');
    }
  }

  /// Start appointment (mark as in progress)
  static Future<void> startAppointment(String appointmentId) async {
    try {
      await updateAppointmentStatus(
        appointmentId,
        AppointmentStatus.inProgress,
      );
    } catch (e) {
      throw Exception('Failed to start appointment: $e');
    }
  }

  /// Confirm appointment
  static Future<void> confirmAppointment(String appointmentId) async {
    try {
      await updateAppointmentStatus(appointmentId, AppointmentStatus.confirmed);
    } catch (e) {
      throw Exception('Failed to confirm appointment: $e');
    }
  }

  /// Mark appointment as no-show
  static Future<void> markNoShow(String appointmentId) async {
    try {
      await updateAppointmentStatus(appointmentId, AppointmentStatus.noShow);
    } catch (e) {
      throw Exception('Failed to mark as no-show: $e');
    }
  }

  /// Get appointment statistics for doctor dashboard
  static Future<Map<String, int>> getDoctorStatistics(String doctorId) async {
    return getDoctorAppointmentStats(doctorId);
  }

  /// Get appointment statistics for doctor dashboard
  static Future<Map<String, int>> getDoctorAppointmentStats(
    String doctorId,
  ) async {
    try {
      // Validate doctor ID
      if (doctorId.isEmpty) {
        print('❌ Empty doctor ID provided');
        return {
          'total': 0,
          'todayCount': 0,
          'thisWeek': 0,
          'monthlyCount': 0,
          'pendingCount': 0,
          'confirmed': 0,
          'completedCount': 0,
        };
      }

      final querySnapshot = await _firestore
          .collection(_appointmentsCollection)
          .where('doctorId', isEqualTo: doctorId)
          .get();

      if (querySnapshot.docs.isEmpty) {
        print('ℹ️ No appointments found for doctor: $doctorId');
        return {
          'total': 0,
          'todayCount': 0,
          'thisWeek': 0,
          'monthlyCount': 0,
          'pendingCount': 0,
          'confirmed': 0,
          'completedCount': 0,
        };
      }

      final appointments = <Appointment>[];
      for (final doc in querySnapshot.docs) {
        try {
          final data = doc.data();
          print(
            '📋 Processing appointment ${doc.id} - doctorId: ${data['doctorId']}',
          );

          final appointment = Appointment.fromFirestore(doc);
          appointments.add(appointment);
        } catch (e) {
          print('⚠️ Failed to parse appointment ${doc.id}: $e');
          // Continue processing other appointments
        }
      }

      print(
        '📊 Successfully parsed ${appointments.length} appointments from ${querySnapshot.docs.length} documents',
      );

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfWeek = startOfWeek.add(const Duration(days: 7));
      final endOfMonth = DateTime(now.year, now.month + 1, 1);

      // Count today's appointments
      final todayAppointments = appointments.where((a) {
        final appointmentDay = DateTime(
          a.appointmentDate.year,
          a.appointmentDate.month,
          a.appointmentDate.day,
        );
        return appointmentDay.isAtSameMomentAs(today);
      }).length;

      // Count this week's appointments
      final weeklyAppointments = appointments.where((a) {
        return a.appointmentDate.isAfter(
              startOfWeek.subtract(const Duration(days: 1)),
            ) &&
            a.appointmentDate.isBefore(endOfWeek);
      }).length;

      // Count this month's appointments
      final monthlyAppointments = appointments.where((a) {
        return a.appointmentDate.isAfter(
              startOfMonth.subtract(const Duration(days: 1)),
            ) &&
            a.appointmentDate.isBefore(endOfMonth);
      }).length;

      // Count by status
      final pendingCount = appointments
          .where((a) => a.status == AppointmentStatus.pending)
          .length;
      final confirmedCount = appointments
          .where((a) => a.status == AppointmentStatus.confirmed)
          .length;
      final completedCount = appointments
          .where((a) => a.status == AppointmentStatus.completed)
          .length;

      final stats = {
        'total': appointments.length,
        'todayCount': todayAppointments,
        'thisWeek': weeklyAppointments,
        'monthlyCount': monthlyAppointments,
        'pendingCount': pendingCount,
        'confirmed': confirmedCount,
        'completedCount': completedCount,
      };

      print('✅ Appointment statistics calculated: $stats');
      return stats;
    } catch (e) {
      print('❌ Error getting appointment stats: $e');
      return {};
    }
  }

  /// Get revenue statistics for doctor dashboard
  static Future<Map<String, double>> getDoctorRevenueStats(
    String doctorId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(_appointmentsCollection)
          .where('doctorId', isEqualTo: doctorId)
          .where('isPaid', isEqualTo: true)
          .get();

      final paidAppointments = querySnapshot.docs
          .map((doc) => Appointment.fromFirestore(doc))
          .toList();

      final today = DateTime.now();
      final startOfToday = DateTime(today.year, today.month, today.day);
      final startOfWeek = startOfToday.subtract(
        Duration(days: today.weekday - 1),
      );
      final startOfMonth = DateTime(today.year, today.month, 1);

      final todayRevenue = paidAppointments
          .where(
            (a) =>
                a.appointmentDate.isAfter(startOfToday) &&
                a.appointmentDate.isBefore(startOfToday.add(Duration(days: 1))),
          )
          .fold<double>(0.0, (sum, appointment) => sum + appointment.fee);

      final weeklyRevenue = paidAppointments
          .where((a) => a.appointmentDate.isAfter(startOfWeek))
          .fold<double>(0.0, (sum, appointment) => sum + appointment.fee);

      final monthlyRevenue = paidAppointments
          .where((a) => a.appointmentDate.isAfter(startOfMonth))
          .fold<double>(0.0, (sum, appointment) => sum + appointment.fee);

      final totalRevenue = paidAppointments.fold<double>(
        0.0,
        (sum, appointment) => sum + appointment.fee,
      );

      return {
        'total': totalRevenue,
        'todayRevenue': todayRevenue,
        'weeklyRevenue': weeklyRevenue,
        'monthlyRevenue': monthlyRevenue,
      };
    } catch (e) {
      print('❌ Error getting revenue stats: $e');
      return {};
    }
  }

  /// Get available time slots for a doctor on a specific date
  static Future<List<String>> getAvailableTimeSlots(
    String doctorId,
    DateTime date,
  ) async {
    try {
      // Get doctor profile to check availability
      final doctorDoc = await _firestore
          .collection(_doctorProfilesCollection)
          .doc(doctorId)
          .get();

      if (!doctorDoc.exists) {
        throw Exception('Doctor not found');
      }

      final doctorProfile = DoctorProfile.fromFirestore(doctorDoc);

      // Get day of week (Monday = 0, Sunday = 6)
      final dayOfWeek = date.weekday - 1;
      final dayNames = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];
      final dayName = dayNames[dayOfWeek];

      // Get available time slots for this day from weeklyAvailability
      List<String> availableSlots = [];
      if (doctorProfile.weeklyAvailability.containsKey(dayName)) {
        availableSlots = List.from(
          doctorProfile.weeklyAvailability[dayName] ?? [],
        );
      }

      // Filter out past times for today
      if (_isSameDay(date, DateTime.now())) {
        final now = DateTime.now();
        availableSlots = availableSlots.where((slot) {
          final slotTime = _parseTimeSlot(slot, date);
          return slotTime?.isAfter(now) ?? false;
        }).toList();
      }

      // Get booked slots for this date
      final bookedSlots = await _getBookedTimeSlots(doctorId, date);

      // Remove booked slots
      availableSlots.removeWhere((slot) => bookedSlots.contains(slot));

      return availableSlots;
    } catch (e) {
      print('❌ Error getting available time slots: $e');
      throw Exception('Failed to get available time slots: $e');
    }
  }

  /// Helper method to get booked time slots
  static Future<List<String>> _getBookedTimeSlots(
    String doctorId,
    DateTime date,
  ) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final querySnapshot = await _firestore
          .collection(_appointmentsCollection)
          .where('doctorId', isEqualTo: doctorId)
          .where(
            'appointmentDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where(
            'appointmentDate',
            isLessThanOrEqualTo: Timestamp.fromDate(endOfDay),
          )
          .where(
            'status',
            whereIn: [
              AppointmentStatus.pending.name,
              AppointmentStatus.confirmed.name,
              AppointmentStatus.inProgress.name,
            ],
          )
          .get();

      return querySnapshot.docs
          .map((doc) => doc.data()['timeSlot'] as String)
          .toList();
    } catch (e) {
      print('❌ Error getting booked time slots: $e');
      return [];
    }
  }

  /// Helper methods
  static bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  static DateTime? _parseTimeSlot(String timeSlot, DateTime date) {
    try {
      // Parse "09:00 - 10:00" format, return start time
      final parts = timeSlot.split(' - ');
      if (parts.isEmpty) return null;

      final timeParts = parts[0].split(':');
      if (timeParts.length != 2) return null;

      final hour = int.tryParse(timeParts[0]);
      final minute = int.tryParse(timeParts[1]);

      if (hour == null || minute == null) return null;

      return DateTime(date.year, date.month, date.day, hour, minute);
    } catch (e) {
      return null;
    }
  }

  /// Stream appointments for patients (real-time updates)
  static Stream<List<Appointment>> streamPatientAppointments(String patientId) {
    return _firestore
        .collection(_appointmentsCollection)
        .where('patientId', isEqualTo: patientId)
        .snapshots()
        .map((snapshot) {
          final appointments = snapshot.docs
              .map((doc) => Appointment.fromFirestore(doc))
              .toList();
          // Sort on client side to avoid composite index
          appointments.sort(
            (a, b) => b.appointmentDate.compareTo(a.appointmentDate),
          );
          return appointments;
        });
  }

  /// Stream appointments for doctors
  static Stream<List<Appointment>> streamDoctorAppointments(String doctorId) {
    return _firestore
        .collection(_appointmentsCollection)
        .where('doctorId', isEqualTo: doctorId)
        .snapshots()
        .map((snapshot) {
          final appointments = snapshot.docs
              .map((doc) => Appointment.fromFirestore(doc))
              .toList();
          // Sort on client side to avoid composite index
          appointments.sort(
            (a, b) => a.appointmentDate.compareTo(b.appointmentDate),
          );
          return appointments;
        });
  }
}
