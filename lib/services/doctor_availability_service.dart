import 'package:cloud_firestore/cloud_firestore.dart';

class AvailableSlot {
  final String id;
  final String time;
  final double fee;
  final bool isBooked;
  final String? bookedBy;
  final String? appointmentId;

  AvailableSlot({
    required this.id,
    required this.time,
    required this.fee,
    this.isBooked = false,
    this.bookedBy,
    this.appointmentId,
  });
}

class DoctorAvailabilityService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get doctor's available slots for a specific date directly from profile
  static Future<List<AvailableSlot>> getDoctorAvailableSlots(
    String doctorId,
    DateTime date,
  ) async {
    try {
      print(
        '🔍 Getting availability for doctor: $doctorId on ${date.toString()}',
      );

      // Query by uid field since that's how MatchedDoctor gets the ID
      final querySnapshot = await _firestore
          .collection('doctor_profiles')
          .where('uid', isEqualTo: doctorId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        print('❌ No doctor profile found with uid: $doctorId');
        return [];
      }

      final doctorDoc = querySnapshot.docs.first;

      final data = doctorDoc.data();
      final weeklyAvailability =
          data['weeklyAvailability'] as Map<String, dynamic>? ?? {};
      final consultationFee = (data['consultationFee'] ?? 50.0).toDouble();

      print('✅ Found doctor: ${data['fullName']}');

      // Get day name (e.g., "Monday", "Tuesday")
      final dayName = _getDayName(date.weekday);
      final daySlots = weeklyAvailability[dayName] as List<dynamic>? ?? [];

      print(
        '� Checking availability for $dayName: ${daySlots.length} slots found',
      );

      if (daySlots.isEmpty) {
        print('⚠️ No availability for $dayName');
        return []; // No availability for this day
      }

      // Get existing bookings for this date
      final existingBookings = await _getExistingBookings(doctorId, date);

      // Convert slots to AvailableSlot objects
      final availableSlots = <AvailableSlot>[];

      for (int i = 0; i < daySlots.length; i++) {
        final timeSlot = daySlots[i].toString();
        final slotId = '${doctorId}_${_formatDateForId(date)}_$i';

        // Check if this slot is already booked
        final booking = existingBookings[timeSlot];

        availableSlots.add(
          AvailableSlot(
            id: slotId,
            time: timeSlot,
            fee: consultationFee,
            isBooked: booking != null,
            bookedBy: booking?['patientId'],
            appointmentId: booking?['appointmentId'],
          ),
        );
      }

      return availableSlots;
    } catch (e) {
      print('❌ Error getting doctor availability: $e');
      throw Exception('Failed to get doctor availability: $e');
    }
  }

  /// Get existing bookings for a specific doctor and date
  static Future<Map<String, Map<String, dynamic>>> _getExistingBookings(
    String doctorId,
    DateTime date,
  ) async {
    try {
      // Ultra-simplified query using only doctorId to avoid any composite index issues
      // We'll filter everything else on the client side
      final querySnapshot = await _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .get();

      final bookings = <String, Map<String, dynamic>>{};
      final targetDate = DateTime(date.year, date.month, date.day);

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final status = data['status'] as String?;
        final timeSlot = data['timeSlot'] as String?;
        final appointmentDate = (data['appointmentDate'] as Timestamp?)
            ?.toDate();

        // Filter everything on client side to avoid index requirements
        if (timeSlot != null &&
            status != null &&
            appointmentDate != null &&
            ['pending', 'confirmed', 'completed'].contains(status)) {
          // Check if appointment is on the same date
          final appointmentDay = DateTime(
            appointmentDate.year,
            appointmentDate.month,
            appointmentDate.day,
          );
          if (appointmentDay == targetDate) {
            bookings[timeSlot] = {
              'appointmentId': doc.id,
              'patientId': data['patientId'],
              'status': status,
            };
          }
        }
      }

      return bookings;
    } catch (e) {
      print('❌ Error getting existing bookings: $e');
      return {};
    }
  }

  /// Book a time slot directly by creating appointment
  static Future<String> bookTimeSlot({
    required String doctorId,
    required String doctorName,
    required DateTime date,
    required String timeSlot,
    required String patientId,
    required String patientName,
    required String reason,
    required String appointmentType,
    required double fee,
  }) async {
    try {
      // Check if slot is still available
      final availableSlots = await getDoctorAvailableSlots(doctorId, date);
      final targetSlot = availableSlots.firstWhere(
        (slot) => slot.time == timeSlot,
        orElse: () => throw Exception('Time slot not found'),
      );

      if (targetSlot.isBooked) {
        throw Exception('Time slot is no longer available');
      }

      // Create appointment directly
      final appointmentData = {
        'patientId': patientId,
        'doctorId': doctorId,
        'patientName': patientName,
        'doctorName': doctorName,
        'appointmentDate': Timestamp.fromDate(date),
        'timeSlot': timeSlot,
        'type': appointmentType,
        'status': 'pending',
        'reason': reason,
        'fee': fee,
        'isPaid': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final appointmentRef = await _firestore
          .collection('appointments')
          .add(appointmentData);
      return appointmentRef.id;
    } catch (e) {
      print('❌ Error booking time slot: $e');
      throw Exception('Failed to book time slot: $e');
    }
  }

  /// Get doctor's consultation fee from profile
  static Future<double> getDoctorConsultationFee(String doctorId) async {
    try {
      final doctorDoc = await _firestore
          .collection('doctor_profiles')
          .doc(doctorId)
          .get();

      if (!doctorDoc.exists) {
        return 50.0; // Default fee
      }

      final data = doctorDoc.data() as Map<String, dynamic>;
      return (data['consultationFee'] ?? 50.0).toDouble();
    } catch (e) {
      print('❌ Error getting consultation fee: $e');
      return 50.0; // Default fee
    }
  }

  /// Helper method to get day name from weekday number
  static String _getDayName(int weekday) {
    const days = [
      'Monday', // 1
      'Tuesday', // 2
      'Wednesday', // 3
      'Thursday', // 4
      'Friday', // 5
      'Saturday', // 6
      'Sunday', // 7
    ];
    return days[weekday - 1];
  }

  /// Helper method to format date for ID generation
  static String _formatDateForId(DateTime date) {
    return '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
  }
}
