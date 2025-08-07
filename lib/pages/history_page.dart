import 'package:flutter/material.dart';
import '../app_theme.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

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
          Text(
            'Health History',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: isSmallScreen ? 20 : 24,
            ),
          ),
          SizedBox(height: isSmallScreen ? 2 : 4),
          Text(
            'Your medical consultations and records',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
              fontSize: isSmallScreen ? 12 : 14,
            ),
          ),
          
          SizedBox(height: isSmallScreen ? 16 : 24),
          
          // Recent Consultations
          Text(
            'Recent Consultations',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: isSmallScreen ? 16 : 18,
            ),
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          
          _buildConsultationCard(
            context,
            doctorName: 'Dr. Sarah Johnson',
            specialty: 'Cardiologist',
            date: 'Dec 10, 2024',
            diagnosis: 'Hypertension - Stage 1',
            status: 'Completed',
            color: AppTheme.primaryColor,
            isSmallScreen: isSmallScreen,
          ),
          
          SizedBox(height: isSmallScreen ? 8 : 12),
          
          _buildConsultationCard(
            context,
            doctorName: 'Dr. Michael Chen',
            specialty: 'Dermatologist',
            date: 'Nov 25, 2024',
            diagnosis: 'Eczema - Mild',
            status: 'Completed',
            color: AppTheme.accentColor,
            isSmallScreen: isSmallScreen,
          ),
          
          SizedBox(height: isSmallScreen ? 8 : 12),
          
          _buildConsultationCard(
            context,
            doctorName: 'Dr. Emily Davis',
            specialty: 'General Physician',
            date: 'Nov 15, 2024',
            diagnosis: 'Seasonal Allergy',
            status: 'Completed',
            color: AppTheme.successColor,
            isSmallScreen: isSmallScreen,
          ),
          
          SizedBox(height: isSmallScreen ? 16 : 24),
          
          // Health Records
          Text(
            'Health Records',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: isSmallScreen ? 16 : 18,
            ),
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          
          Row(
            children: [
              Expanded(
                child: _buildRecordCard(
                  context,
                  icon: Icons.bloodtype,
                  title: 'Blood Tests',
                  subtitle: 'Last updated: Dec 5, 2024',
                  color: AppTheme.primaryColor,
                  isSmallScreen: isSmallScreen,
                ),
              ),
              SizedBox(width: isSmallScreen ? 8 : 12),
              Expanded(
                child: _buildRecordCard(
                  context,
                  icon: Icons.favorite,
                  title: 'Heart Rate',
                  subtitle: 'Last reading: 72 bpm',
                  color: AppTheme.accentColor,
                  isSmallScreen: isSmallScreen,
                ),
              ),
            ],
          ),
          
          SizedBox(height: isSmallScreen ? 8 : 12),
          
          Row(
            children: [
              Expanded(
                child: _buildRecordCard(
                  context,
                  icon: Icons.monitor_weight,
                  title: 'Weight',
                  subtitle: 'Last updated: Dec 8, 2024',
                  color: AppTheme.successColor,
                  isSmallScreen: isSmallScreen,
                ),
              ),
              SizedBox(width: isSmallScreen ? 8 : 12),
              Expanded(
                child: _buildRecordCard(
                  context,
                  icon: Icons.thermostat,
                  title: 'Temperature',
                  subtitle: 'Last reading: 98.6°F',
                  color: AppTheme.errorColor,
                  isSmallScreen: isSmallScreen,
                ),
              ),
            ],
          ),
          
          SizedBox(height: isSmallScreen ? 16 : 24),
          
          // Medications
          Text(
            'Current Medications',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: isSmallScreen ? 16 : 18,
            ),
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          
          _buildMedicationCard(
            context,
            name: 'Lisinopril',
            dosage: '10mg daily',
            prescribedBy: 'Dr. Sarah Johnson',
            startDate: 'Dec 10, 2024',
            color: AppTheme.primaryColor,
            isSmallScreen: isSmallScreen,
          ),
          
          SizedBox(height: isSmallScreen ? 8 : 12),
          
          _buildMedicationCard(
            context,
            name: 'Cetirizine',
            dosage: '10mg as needed',
            prescribedBy: 'Dr. Emily Davis',
            startDate: 'Nov 15, 2024',
            color: AppTheme.accentColor,
            isSmallScreen: isSmallScreen,
          ),
          
          SizedBox(height: isSmallScreen ? 16 : 24),
          
          // Quick Stats
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
            decoration: AppTheme.cardDecoration,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        context,
                        icon: Icons.medical_services,
                        value: '8',
                        label: 'Total Visits',
                        color: AppTheme.primaryColor,
                        isSmallScreen: isSmallScreen,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        context,
                        icon: Icons.medication,
                        value: '2',
                        label: 'Active Meds',
                        color: AppTheme.accentColor,
                        isSmallScreen: isSmallScreen,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        context,
                        icon: Icons.favorite,
                        value: 'Good',
                        label: 'Health Status',
                        color: AppTheme.successColor,
                        isSmallScreen: isSmallScreen,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isSmallScreen ? 16 : 20),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 10 : 12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.download,
                        color: AppTheme.primaryColor,
                        size: isSmallScreen ? 18 : 20,
                      ),
                      SizedBox(width: isSmallScreen ? 6 : 8),
                      Text(
                        'Download Health Records',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: isSmallScreen ? 14 : 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsultationCard(
    BuildContext context, {
    required String doctorName,
    required String specialty,
    required String date,
    required String diagnosis,
    required String status,
    required Color color,
    bool isSmallScreen = false,
  }) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: isSmallScreen ? 32 : 40,
                height: isSmallScreen ? 32 : 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
                ),
                child: Icon(
                  Icons.person,
                  color: color,
                  size: isSmallScreen ? 16 : 20,
                ),
              ),
              SizedBox(width: isSmallScreen ? 8 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctorName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: isSmallScreen ? 14 : 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      specialty,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                        fontSize: isSmallScreen ? 11 : 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 6 : 8,
                  vertical: isSmallScreen ? 3 : 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.successColor,
                    fontWeight: FontWeight.w600,
                    fontSize: isSmallScreen ? 9 : 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 8 : 12),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: isSmallScreen ? 12 : 14,
                color: AppTheme.textLight,
              ),
              SizedBox(width: isSmallScreen ? 3 : 4),
              Text(
                date,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textLight,
                  fontSize: isSmallScreen ? 10 : 12,
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 6 : 8),
          Text(
            'Diagnosis: $diagnosis',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: isSmallScreen ? 11 : 12,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRecordCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    bool isSmallScreen = false,
  }) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: isSmallScreen ? 32 : 40,
            height: isSmallScreen ? 32 : 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
            ),
            child: Icon(
              icon,
              color: color,
              size: isSmallScreen ? 16 : 20,
            ),
          ),
          SizedBox(height: isSmallScreen ? 8 : 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: isSmallScreen ? 14 : 16,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: isSmallScreen ? 2 : 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
              fontSize: isSmallScreen ? 10 : 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationCard(
    BuildContext context, {
    required String name,
    required String dosage,
    required String prescribedBy,
    required String startDate,
    required Color color,
    bool isSmallScreen = false,
  }) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: isSmallScreen ? 32 : 40,
                height: isSmallScreen ? 32 : 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
                ),
                child: Icon(
                  Icons.medication,
                  color: color,
                  size: isSmallScreen ? 16 : 20,
                ),
              ),
              SizedBox(width: isSmallScreen ? 8 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: isSmallScreen ? 14 : 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      dosage,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                        fontSize: isSmallScreen ? 11 : 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 8 : 12),
          Row(
            children: [
              Icon(
                Icons.person,
                size: isSmallScreen ? 12 : 14,
                color: AppTheme.textLight,
              ),
              SizedBox(width: isSmallScreen ? 3 : 4),
              Expanded(
                child: Text(
                  'Prescribed by: $prescribedBy',
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
          SizedBox(height: isSmallScreen ? 2 : 4),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: isSmallScreen ? 12 : 14,
                color: AppTheme.textLight,
              ),
              SizedBox(width: isSmallScreen ? 3 : 4),
              Text(
                'Started: $startDate',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textLight,
                  fontSize: isSmallScreen ? 10 : 12,
                ),
              ),
            ],
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
        Icon(
          icon,
          color: color,
          size: isSmallScreen ? 20 : 24,
        ),
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