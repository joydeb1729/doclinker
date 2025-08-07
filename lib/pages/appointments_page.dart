import 'package:flutter/material.dart';
import '../app_theme.dart';

class AppointmentsPage extends StatelessWidget {
  const AppointmentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Appointments',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: isSmallScreen ? 12 : 14,
                          ),
                    ),
                    SizedBox(height: isSmallScreen ? 2 : 4),
                    Text(
                      'Manage your consultations',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                        fontSize: isSmallScreen ? 12 : 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 12 : 16,
                  vertical: isSmallScreen ? 6 : 8,
                ),
                decoration: AppTheme.buttonDecoration,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add,
                      color: Colors.white,
                      size: isSmallScreen ? 16 : 18,
                    ),
                    SizedBox(width: isSmallScreen ? 6 : 8),
                    Text(
                      'Book New',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: isSmallScreen ? 11 : 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: isSmallScreen ? 16 : 24),

          // Upcoming Appointments
          Text(
            'Upcoming',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: isSmallScreen ? 16 : 18,
            ),
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),

          _buildAppointmentCard(
            context,
            doctorName: 'Dr. Sarah Johnson',
            specialty: 'Cardiologist',
            date: 'Tomorrow',
            time: '2:00 PM',
            status: 'Confirmed',
            statusColor: AppTheme.successColor,
            avatarColor: AppTheme.primaryColor,
            isSmallScreen: isSmallScreen,
          ),

          SizedBox(height: isSmallScreen ? 8 : 12),

          _buildAppointmentCard(
            context,
            doctorName: 'Dr. Michael Chen',
            specialty: 'Dermatologist',
            date: 'Friday, Dec 15',
            time: '10:30 AM',
            status: 'Pending',
            statusColor: AppTheme.accentColor,
            avatarColor: AppTheme.accentColor,
            isSmallScreen: isSmallScreen,
          ),

          SizedBox(height: isSmallScreen ? 16 : 24),

          // Past Appointments
          Text(
            'Past Appointments',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: isSmallScreen ? 16 : 18,
            ),
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),

          _buildAppointmentCard(
            context,
            doctorName: 'Dr. Emily Davis',
            specialty: 'General Physician',
            date: 'Dec 5, 2024',
            time: '3:15 PM',
            status: 'Completed',
            statusColor: AppTheme.textLight,
            avatarColor: AppTheme.textLight,
            isPast: true,
            isSmallScreen: isSmallScreen,
          ),

          SizedBox(height: isSmallScreen ? 8 : 12),

          _buildAppointmentCard(
            context,
            doctorName: 'Dr. Robert Wilson',
            specialty: 'Orthopedic',
            date: 'Nov 28, 2024',
            time: '11:00 AM',
            status: 'Completed',
            statusColor: AppTheme.textLight,
            avatarColor: AppTheme.textLight,
            isPast: true,
            isSmallScreen: isSmallScreen,
          ),

          SizedBox(height: isSmallScreen ? 16 : 24),

          // Quick Stats
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
            decoration: AppTheme.cardDecoration,
            child: Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    icon: Icons.calendar_today,
                    value: '3',
                    label: 'This Month',
                    color: AppTheme.primaryColor,
                    isSmallScreen: isSmallScreen,
                  ),
                ),
                Container(
                  width: 1,
                  height: isSmallScreen ? 32 : 40,
                  color: AppTheme.textLight.withOpacity(0.2),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    icon: Icons.check_circle,
                    value: '12',
                    label: 'Total',
                    color: AppTheme.successColor,
                    isSmallScreen: isSmallScreen,
                  ),
                ),
                Container(
                  width: 1,
                  height: isSmallScreen ? 32 : 40,
                  color: AppTheme.textLight.withOpacity(0.2),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    icon: Icons.star,
                    value: '4.8',
                    label: 'Rating',
                    color: AppTheme.accentColor,
                    isSmallScreen: isSmallScreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(
    BuildContext context, {
    required String doctorName,
    required String specialty,
    required String date,
    required String time,
    required String status,
    required Color statusColor,
    required Color avatarColor,
    bool isPast = false,
    bool isSmallScreen = false,
  }) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: AppTheme.cardDecoration,
      child: Row(
        children: [
          // Doctor Avatar
          Container(
            width: isSmallScreen ? 40 : 48,
            height: isSmallScreen ? 40 : 48,
            decoration: BoxDecoration(
              color: avatarColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(isSmallScreen ? 20 : 24),
            ),
            child: Icon(
              Icons.person,
              color: avatarColor,
              size: isSmallScreen ? 20 : 24,
            ),
          ),

          SizedBox(width: isSmallScreen ? 12 : 16),

          // Appointment Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doctorName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isPast ? AppTheme.textLight : AppTheme.textPrimary,
                    fontSize: isSmallScreen ? 14 : 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: isSmallScreen ? 1 : 2),
                Text(
                  specialty,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontSize: isSmallScreen ? 11 : 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: isSmallScreen ? 6 : 8),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: isSmallScreen ? 12 : 14,
                      color: AppTheme.textLight,
                    ),
                    SizedBox(width: isSmallScreen ? 3 : 4),
                    Expanded(
                      child: Text(
                        '$date at $time',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textLight,
                          fontSize: isSmallScreen ? 10 : 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Status
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 6 : 8,
              vertical: isSmallScreen ? 3 : 4,
            ),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w600,
                fontSize: isSmallScreen ? 9 : 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    bool isSmallScreen = false,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: isSmallScreen ? 20 : 24),
        SizedBox(height: isSmallScreen ? 6 : 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: isSmallScreen ? 18 : 20,
          ),
        ),
        SizedBox(height: isSmallScreen ? 1 : 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
            fontSize: isSmallScreen ? 10 : 12,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
