import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../app_theme.dart';
import '../../models/appointment.dart';

class DoctorAppointmentScreen extends ConsumerStatefulWidget {
  const DoctorAppointmentScreen({super.key});

  @override
  ConsumerState<DoctorAppointmentScreen> createState() =>
      _DoctorAppointmentScreenState();
}

class _DoctorAppointmentScreenState
    extends ConsumerState<DoctorAppointmentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AppointmentService _appointmentService = AppointmentService();

  List<Appointment> _pendingAppointments = [];
  List<Appointment> _confirmedAppointments = [];
  List<Appointment> _completedAppointments = [];
  List<Appointment> _rejectedAppointments = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAppointments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final allAppointments = await _appointmentService.getDoctorAppointments(
        user.uid,
      );

      setState(() {
        _pendingAppointments = allAppointments
            .where((apt) => apt.status == AppointmentStatus.pending)
            .toList();
        _confirmedAppointments = allAppointments
            .where((apt) => apt.status == AppointmentStatus.confirmed)
            .toList();
        _completedAppointments = allAppointments
            .where((apt) => apt.status == AppointmentStatus.completed)
            .toList();
        _rejectedAppointments = allAppointments
            .where((apt) => apt.status == AppointmentStatus.cancelled)
            .toList();
      });
    } catch (e) {
      print('Error loading appointments: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load appointments: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _updateAppointmentStatus(
    String appointmentId,
    AppointmentStatus status, {
    String? notes,
  }) async {
    try {
      await _appointmentService.updateAppointmentStatus(
        appointmentId,
        status,
        notes: notes,
      );
      await _loadAppointments(); // Reload to update UI

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Appointment ${status.name} successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error updating appointment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update appointment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAppointmentActions(Appointment appointment) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildAppointmentActionsSheet(appointment),
    );
  }

  Widget _buildAppointmentActionsSheet(Appointment appointment) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Appointment Actions',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            'Patient: ${appointment.patientName}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(
            'Time: ${appointment.timeSlot}',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 20),

          if (appointment.status == AppointmentStatus.pending) ...[
            _buildActionButton(
              'Accept Appointment',
              Icons.check_circle,
              Colors.green,
              () => _updateAppointmentStatus(
                appointment.id,
                AppointmentStatus.confirmed,
              ),
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              'Reject Appointment',
              Icons.cancel,
              Colors.red,
              () => _showRejectDialog(appointment),
            ),
          ],

          if (appointment.status == AppointmentStatus.confirmed) ...[
            _buildActionButton(
              'Mark as Completed',
              Icons.check_circle_outline,
              Colors.blue,
              () => _showCompletionDialog(appointment),
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              'Cancel Appointment',
              Icons.cancel_outlined,
              Colors.orange,
              () => _showCancelDialog(appointment),
            ),
          ],

          const SizedBox(height: 12),
          _buildActionButton(
            'View Details',
            Icons.info_outline,
            AppTheme.primaryColor,
            () => _showAppointmentDetails(appointment),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String text,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.pop(context);
          onPressed();
        },
        icon: Icon(icon, color: Colors.white),
        label: Text(text, style: const TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  void _showRejectDialog(Appointment appointment) {
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Appointment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Are you sure you want to reject this appointment?'),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Reason (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateAppointmentStatus(
                appointment.id,
                AppointmentStatus.cancelled,
                notes: notesController.text.trim().isEmpty
                    ? null
                    : notesController.text.trim(),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showCompletionDialog(Appointment appointment) {
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Appointment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Mark this appointment as completed?'),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Treatment Notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateAppointmentStatus(
                appointment.id,
                AppointmentStatus.completed,
                notes: notesController.text.trim().isEmpty
                    ? null
                    : notesController.text.trim(),
              );
            },
            child: const Text('Complete'),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(Appointment appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: const Text(
          'Are you sure you want to cancel this appointment?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateAppointmentStatus(
                appointment.id,
                AppointmentStatus.cancelled,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text(
              'Cancel Appointment',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showAppointmentDetails(Appointment appointment) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.medical_information, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Appointment Details',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 16),

              _buildDetailRow('Patient', appointment.patientName),
              _buildDetailRow('Date', appointment.formattedDate),
              _buildDetailRow('Time', appointment.timeSlot),
              _buildDetailRow('Type', appointment.type.name.toUpperCase()),
              _buildDetailRow('Status', appointment.status.name.toUpperCase()),
              _buildDetailRow('Fee', '৳${appointment.fee.toStringAsFixed(2)}'),

              if (appointment.symptoms?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                _buildDetailRow('Symptoms', appointment.symptoms!),
              ],

              if (appointment.notes?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                _buildDetailRow('Notes', appointment.notes!),
              ],

              if (appointment.patientPhone?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                _buildDetailRow('Patient Phone', appointment.patientPhone!),
              ],

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: AppTheme.textSecondary,
              indicatorColor: AppTheme.primaryColor,
              tabs: [
                Tab(
                  text: 'Pending',
                  icon: Badge(
                    label: Text('${_pendingAppointments.length}'),
                    child: const Icon(Icons.schedule),
                  ),
                ),
                Tab(
                  text: 'Confirmed',
                  icon: Badge(
                    label: Text('${_confirmedAppointments.length}'),
                    child: const Icon(Icons.check_circle),
                  ),
                ),
                Tab(
                  text: 'Completed',
                  icon: Badge(
                    label: Text('${_completedAppointments.length}'),
                    child: const Icon(Icons.done_all),
                  ),
                ),
                Tab(
                  text: 'Rejected',
                  icon: Badge(
                    label: Text('${_rejectedAppointments.length}'),
                    child: const Icon(Icons.cancel),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadAppointments,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildAppointmentList(
                          _pendingAppointments,
                          'No pending appointments',
                        ),
                        _buildAppointmentList(
                          _confirmedAppointments,
                          'No confirmed appointments',
                        ),
                        _buildAppointmentList(
                          _completedAppointments,
                          'No completed appointments',
                        ),
                        _buildAppointmentList(
                          _rejectedAppointments,
                          'No rejected appointments',
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentList(
    List<Appointment> appointments,
    String emptyMessage,
  ) {
    if (appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: AppTheme.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appointment = appointments[index];
        return _buildAppointmentCard(appointment);
      },
    );
  }

  Widget _buildAppointmentCard(Appointment appointment) {
    Color statusColor = _getStatusColor(appointment.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showAppointmentActions(appointment),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: statusColor.withOpacity(0.1),
                    child: Text(
                      appointment.patientName.isNotEmpty
                          ? appointment.patientName[0].toUpperCase()
                          : 'P',
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appointment.patientName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${appointment.formattedDate} • ${appointment.timeSlot}',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      appointment.status.name.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (appointment.symptoms?.isNotEmpty == true) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.medical_services,
                        size: 16,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          appointment.symptoms!,
                          style: const TextStyle(fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (appointment.fee > 0) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.attach_money,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                    Text(
                      '৳${appointment.fee.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return Colors.orange;
      case AppointmentStatus.confirmed:
        return Colors.blue;
      case AppointmentStatus.completed:
        return Colors.green;
      case AppointmentStatus.cancelled:
        return Colors.red;
      default:
        return AppTheme.textSecondary;
    }
  }
}
