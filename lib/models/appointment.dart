import 'package:cloud_firestore/cloud_firestore.dart';

enum AppointmentStatus {
  pending,
  confirmed,
  inProgress,
  completed,
  cancelled,
  noShow,
}

enum AppointmentType { consultation, followUp, emergency, checkup, procedure }

class Appointment {
  final String id;
  final String doctorId;
  final String patientId;
  final String doctorName;
  final String patientName;
  final DateTime appointmentDate;
  final String timeSlot; // e.g., "10:00 - 11:00"
  final AppointmentType type;
  final AppointmentStatus status;
  final String? reason;
  final String? symptoms;
  final String? diagnosis;
  final String? prescription;
  final String? notes;
  final double fee;
  final bool isPaid;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? patientPhone;
  final String? doctorPhone;

  Appointment({
    required this.id,
    required this.doctorId,
    required this.patientId,
    required this.doctorName,
    required this.patientName,
    required this.appointmentDate,
    required this.timeSlot,
    required this.type,
    required this.status,
    this.reason,
    this.symptoms,
    this.diagnosis,
    this.prescription,
    this.notes,
    required this.fee,
    this.isPaid = false,
    required this.createdAt,
    required this.updatedAt,
    this.patientPhone,
    this.doctorPhone,
  });

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'doctorId': doctorId,
      'patientId': patientId,
      'doctorName': doctorName,
      'patientName': patientName,
      'appointmentDate': Timestamp.fromDate(appointmentDate),
      'timeSlot': timeSlot,
      'type': type.name,
      'status': status.name,
      'reason': reason,
      'symptoms': symptoms,
      'diagnosis': diagnosis,
      'prescription': prescription,
      'notes': notes,
      'fee': fee,
      'isPaid': isPaid,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'patientPhone': patientPhone,
      'doctorPhone': doctorPhone,
    };
  }

  // Create from Firestore document
  factory Appointment.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Appointment(
      id: doc.id,
      doctorId: data['doctorId'] ?? '',
      patientId: data['patientId'] ?? '',
      doctorName: data['doctorName'] ?? '',
      patientName: data['patientName'] ?? '',
      appointmentDate:
          _safeParseTimestamp(data['appointmentDate']) ?? DateTime.now(),
      timeSlot: data['timeSlot'] ?? '',
      type: AppointmentType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => AppointmentType.consultation,
      ),
      status: AppointmentStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => AppointmentStatus.pending,
      ),
      reason: data['reason'],
      symptoms: data['symptoms'],
      diagnosis: data['diagnosis'],
      prescription: data['prescription'],
      notes: data['notes'],
      fee: (data['fee'] ?? 0.0).toDouble(),
      isPaid: data['isPaid'] ?? false,
      createdAt: _safeParseTimestamp(data['createdAt']) ?? DateTime.now(),
      updatedAt: _safeParseTimestamp(data['updatedAt']) ?? DateTime.now(),
      patientPhone: data['patientPhone'],
      doctorPhone: data['doctorPhone'],
    );
  }

  // Create copy with updated fields
  Appointment copyWith({
    AppointmentStatus? status,
    String? reason,
    String? symptoms,
    String? diagnosis,
    String? prescription,
    String? notes,
    bool? isPaid,
    DateTime? updatedAt,
  }) {
    return Appointment(
      id: id,
      doctorId: doctorId,
      patientId: patientId,
      doctorName: doctorName,
      patientName: patientName,
      appointmentDate: appointmentDate,
      timeSlot: timeSlot,
      type: type,
      status: status ?? this.status,
      reason: reason ?? this.reason,
      symptoms: symptoms ?? this.symptoms,
      diagnosis: diagnosis ?? this.diagnosis,
      prescription: prescription ?? this.prescription,
      notes: notes ?? this.notes,
      fee: fee,
      isPaid: isPaid ?? this.isPaid,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      patientPhone: patientPhone,
      doctorPhone: doctorPhone,
    );
  }

  // Get formatted date string
  String get formattedDate {
    return '${appointmentDate.day}/${appointmentDate.month}/${appointmentDate.year}';
  }

  // Get formatted time
  String get formattedTime {
    return timeSlot;
  }

  // Get status color
  String get statusColor {
    switch (status) {
      case AppointmentStatus.pending:
        return 'orange';
      case AppointmentStatus.confirmed:
        return 'green';
      case AppointmentStatus.inProgress:
        return 'blue';
      case AppointmentStatus.completed:
        return 'teal';
      case AppointmentStatus.cancelled:
        return 'red';
      case AppointmentStatus.noShow:
        return 'grey';
    }
  }

  // Get type display name
  String get typeDisplayName {
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

  // Check if appointment is today
  bool get isToday {
    final now = DateTime.now();
    return appointmentDate.year == now.year &&
        appointmentDate.month == now.month &&
        appointmentDate.day == now.day;
  }

  // Check if appointment is upcoming
  bool get isUpcoming {
    return appointmentDate.isAfter(DateTime.now()) &&
        (status == AppointmentStatus.pending ||
            status == AppointmentStatus.confirmed);
  }

  // Safe parsing of Firestore Timestamps
  static DateTime? _safeParseTimestamp(dynamic value) {
    try {
      if (value == null) {
        return null;
      }
      if (value is Timestamp) {
        return value.toDate();
      }
      if (value is DateTime) {
        return value;
      }
      if (value is String) {
        // Try to parse ISO string format
        return DateTime.tryParse(value);
      }
      if (value is int) {
        // Treat as milliseconds since epoch
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      // If none of the above, return null
      print('Warning: Unexpected timestamp type: ${value.runtimeType}');
      return null;
    } catch (e) {
      print(
        'Error parsing timestamp: $e, value: $value, type: ${value.runtimeType}',
      );
      return null;
    }
  }
}

// Appointment Service for Firestore operations
class AppointmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'appointments';

  // Create appointment with transaction safety
  Future<String> createAppointment(Appointment appointment) async {
    try {
      final docRef = _firestore.collection(_collection).doc();

      return await _firestore.runTransaction((transaction) async {
        // Check for existing appointments at the same time slot
        final existingQuery = await _firestore
            .collection(_collection)
            .where('doctorId', isEqualTo: appointment.doctorId)
            .where(
              'appointmentDate',
              isEqualTo: Timestamp.fromDate(appointment.appointmentDate),
            )
            .where('timeSlot', isEqualTo: appointment.timeSlot)
            .where('status', whereIn: ['pending', 'confirmed'])
            .get();

        if (existingQuery.docs.isNotEmpty) {
          throw Exception('Time slot is already booked');
        }

        // Create the appointment with the generated ID
        final appointmentWithId = Appointment(
          id: docRef.id,
          doctorId: appointment.doctorId,
          patientId: appointment.patientId,
          doctorName: appointment.doctorName,
          patientName: appointment.patientName,
          appointmentDate: appointment.appointmentDate,
          timeSlot: appointment.timeSlot,
          type: appointment.type,
          status: appointment.status,
          reason: appointment.reason,
          symptoms: appointment.symptoms,
          diagnosis: appointment.diagnosis,
          prescription: appointment.prescription,
          notes: appointment.notes,
          fee: appointment.fee,
          isPaid: appointment.isPaid,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          patientPhone: appointment.patientPhone,
          doctorPhone: appointment.doctorPhone,
        );

        transaction.set(docRef, appointmentWithId.toFirestore());
        return docRef.id;
      });
    } catch (e) {
      throw Exception('Failed to create appointment: $e');
    }
  }

  // Get appointment by ID
  Future<Appointment?> getAppointment(String appointmentId) async {
    try {
      final doc = await _firestore
          .collection(_collection)
          .doc(appointmentId)
          .get();
      if (doc.exists) {
        return Appointment.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get appointment: $e');
    }
  }

  // Update appointment
  Future<void> updateAppointment(Appointment appointment) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(appointment.id)
          .update(appointment.toFirestore());
    } catch (e) {
      throw Exception('Failed to update appointment: $e');
    }
  }

  // Get doctor's appointments
  Future<List<Appointment>> getDoctorAppointments(
    String doctorId, {
    DateTime? startDate,
    DateTime? endDate,
    AppointmentStatus? status,
  }) async {
    try {
      Query query = _firestore
          .collection(_collection)
          .where('doctorId', isEqualTo: doctorId);

      if (startDate != null) {
        query = query.where(
          'appointmentDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        );
      }

      if (endDate != null) {
        query = query.where(
          'appointmentDate',
          isLessThanOrEqualTo: Timestamp.fromDate(endDate),
        );
      }

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      final querySnapshot = await query.get();

      final appointments = querySnapshot.docs
          .map((doc) => Appointment.fromFirestore(doc))
          .toList();

      // Sort on client side to avoid composite index
      appointments.sort(
        (a, b) => a.appointmentDate.compareTo(b.appointmentDate),
      );
      return appointments;
    } catch (e) {
      throw Exception('Failed to get doctor appointments: $e');
    }
  }

  // Get patient's appointments
  Future<List<Appointment>> getPatientAppointments(
    String patientId, {
    DateTime? startDate,
    DateTime? endDate,
    AppointmentStatus? status,
  }) async {
    try {
      Query query = _firestore
          .collection(_collection)
          .where('patientId', isEqualTo: patientId);

      if (startDate != null) {
        query = query.where(
          'appointmentDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        );
      }

      if (endDate != null) {
        query = query.where(
          'appointmentDate',
          isLessThanOrEqualTo: Timestamp.fromDate(endDate),
        );
      }

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      final querySnapshot = await query.get();

      final appointments = querySnapshot.docs
          .map((doc) => Appointment.fromFirestore(doc))
          .toList();

      // Sort on client side to avoid composite index
      appointments.sort(
        (a, b) => a.appointmentDate.compareTo(b.appointmentDate),
      );
      return appointments;
    } catch (e) {
      throw Exception('Failed to get patient appointments: $e');
    }
  }

  // Get today's appointments for doctor
  Future<List<Appointment>> getTodayAppointments(String doctorId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

      return await getDoctorAppointments(
        doctorId,
        startDate: startOfDay,
        endDate: endOfDay,
      );
    } catch (e) {
      throw Exception('Failed to get today\'s appointments: $e');
    }
  }

  // Cancel appointment
  Future<void> cancelAppointment(String appointmentId, String reason) async {
    try {
      await _firestore.collection(_collection).doc(appointmentId).update({
        'status': AppointmentStatus.cancelled.name,
        'notes': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to cancel appointment: $e');
    }
  }

  // Update appointment status
  Future<void> updateAppointmentStatus(
    String appointmentId,
    AppointmentStatus status, {
    String? notes,
  }) async {
    try {
      final updateData = {
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (notes != null) {
        updateData['notes'] = notes;
      }

      await _firestore
          .collection(_collection)
          .doc(appointmentId)
          .update(updateData);
    } catch (e) {
      throw Exception('Failed to update appointment status: $e');
    }
  }

  // Delete appointment
  Future<void> deleteAppointment(String appointmentId) async {
    try {
      await _firestore.collection(_collection).doc(appointmentId).delete();
    } catch (e) {
      throw Exception('Failed to delete appointment: $e');
    }
  }

  // Get appointments statistics
  Future<Map<String, int>> getAppointmentStats(String doctorId) async {
    try {
      final appointments = await getDoctorAppointments(doctorId);

      final stats = <String, int>{
        'total': appointments.length,
        'pending': 0,
        'confirmed': 0,
        'completed': 0,
        'cancelled': 0,
      };

      for (final appointment in appointments) {
        switch (appointment.status) {
          case AppointmentStatus.pending:
            stats['pending'] = (stats['pending'] ?? 0) + 1;
            break;
          case AppointmentStatus.confirmed:
            stats['confirmed'] = (stats['confirmed'] ?? 0) + 1;
            break;
          case AppointmentStatus.completed:
            stats['completed'] = (stats['completed'] ?? 0) + 1;
            break;
          case AppointmentStatus.cancelled:
            stats['cancelled'] = (stats['cancelled'] ?? 0) + 1;
            break;
          default:
            break;
        }
      }

      return stats;
    } catch (e) {
      throw Exception('Failed to get appointment statistics: $e');
    }
  }
}
