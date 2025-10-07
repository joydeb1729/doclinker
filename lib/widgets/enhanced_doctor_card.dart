import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../services/doctor_matching_service.dart';

class EnhancedDoctorCard extends StatelessWidget {
  final MatchedDoctor doctor;
  final VoidCallback? onBookTap;

  const EnhancedDoctorCard({super.key, required this.doctor, this.onBookTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with photo, name, and match score
            Row(
              children: [
                // Doctor photo placeholder
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  backgroundImage: doctor.profileImage != null
                      ? NetworkImage(doctor.profileImage!)
                      : null,
                  child: doctor.profileImage == null
                      ? Text(
                          doctor.name.isNotEmpty ? doctor.name[0] : 'D',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        )
                      : null,
                ),

                const SizedBox(width: 16),

                // Name and specialty
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctor.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        doctor.specialty,
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (doctor.subSpecialties.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          doctor.subSpecialties.take(2).join(', '),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                // Match score badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getMatchScoreColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _getMatchScoreColor().withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${(doctor.matchScore * 100).toInt()}%',
                        style: TextStyle(
                          color: _getMatchScoreColor(),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'match',
                        style: TextStyle(
                          color: _getMatchScoreColor(),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Stats row
            Row(
              children: [
                // Rating
                Icon(Icons.star, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${doctor.rating.toStringAsFixed(1)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  ' (${doctor.reviewCount})',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),

                const SizedBox(width: 16),

                // Distance
                Icon(Icons.location_on, color: Colors.grey.shade600, size: 16),
                const SizedBox(width: 4),
                Text(
                  doctor.distance,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),

                const SizedBox(width: 16),

                // Experience
                Icon(Icons.work_outline, color: Colors.grey.shade600, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${doctor.yearsExperience} yrs',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),

                const Spacer(),

                // Fee
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '৳${doctor.consultationFee.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Hospital affiliation and availability
            Row(
              children: [
                Icon(
                  Icons.local_hospital,
                  color: Colors.grey.shade600,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    doctor.hospitalAffiliation,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Availability
            Row(
              children: [
                Icon(
                  doctor.availableToday
                      ? Icons.schedule
                      : Icons.schedule_outlined,
                  color: doctor.availableToday ? Colors.green : Colors.orange,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'Next available: ${doctor.nextAvailable}',
                  style: TextStyle(
                    color: doctor.availableToday
                        ? Colors.green.shade700
                        : Colors.orange.shade700,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Action button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onBookTap,
                icon: const Icon(Icons.calendar_today, size: 16),
                label: const Text('Book Now', style: TextStyle(fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getMatchScoreColor() {
    if (doctor.matchScore >= 0.9) return Colors.green;
    if (doctor.matchScore >= 0.8) return Colors.blue;
    if (doctor.matchScore >= 0.7) return Colors.orange;
    return Colors.red;
  }
}
