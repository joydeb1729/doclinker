import 'package:flutter/material.dart';
import '../app_theme.dart';

enum AIProgressStage {
  symptomAnalysis,
  doctorMatching,
  appointmentBooking,
  completed,
}

class AIProgressTracker extends StatelessWidget {
  final AIProgressStage currentStage;
  final bool showLabels;

  const AIProgressTracker({
    super.key,
    required this.currentStage,
    this.showLabels = true,
  });

  @override
  Widget build(BuildContext context) {
    final stages = AIProgressStage.values;
    final currentIndex = stages.indexOf(currentStage);
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 12 : 20,
        vertical: isSmallScreen ? 8 : 16,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          if (showLabels) ...[
            Row(
              children: [
                Icon(
                  Icons.psychology,
                  size: isSmallScreen ? 14 : 16,
                  color: AppTheme.primaryColor,
                ),
                SizedBox(width: isSmallScreen ? 6 : 8),
                Text(
                  'AI Assistant Progress',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: isSmallScreen ? 10 : 12,
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 8 : 12),
          ],
          Row(
            children: List.generate(stages.length, (index) {
              final stage = stages[index];
              final isCompleted = index < currentIndex;
              final isCurrent = index == currentIndex;
              final isActive = isCompleted || isCurrent;

              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            width: isSmallScreen ? 20 : 24,
                            height: isSmallScreen ? 20 : 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isCompleted
                                  ? AppTheme.successColor
                                  : isCurrent
                                      ? AppTheme.primaryColor
                                      : AppTheme.textLight.withOpacity(0.3),
                              border: isCurrent
                                  ? Border.all(
                                      color: AppTheme.primaryColor, width: 2)
                                  : null,
                            ),
                            child: isCompleted
                                ? Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: isSmallScreen ? 10 : 14,
                                  )
                                : isCurrent
                                    ? Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppTheme.primaryColor,
                                        ),
                                        child: Icon(
                                          Icons.psychology,
                                          color: Colors.white,
                                          size: isSmallScreen ? 8 : 12,
                                        ),
                                      )
                                    : null,
                          ),
                          if (showLabels) ...[
                            SizedBox(height: isSmallScreen ? 2 : 4),
                            Text(
                              _getStageLabel(stage),
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: isActive
                                    ? AppTheme.textPrimary
                                    : AppTheme.textLight,
                                fontWeight: isCurrent
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                fontSize: isSmallScreen ? 8 : 10,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (index < stages.length - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 2 : 4),
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? AppTheme.successColor
                                : AppTheme.textLight.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  String _getStageLabel(AIProgressStage stage) {
    switch (stage) {
      case AIProgressStage.symptomAnalysis:
        return 'Analysis';
      case AIProgressStage.doctorMatching:
        return 'Matching';
      case AIProgressStage.appointmentBooking:
        return 'Booking';
      case AIProgressStage.completed:
        return 'Complete';
    }
  }
} 