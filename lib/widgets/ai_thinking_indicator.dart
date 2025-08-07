import 'package:flutter/material.dart';
import '../app_theme.dart';

class AIThinkingIndicator extends StatefulWidget {
  final String? message;
  final bool showDots;

  const AIThinkingIndicator({
    super.key,
    this.message,
    this.showDots = true,
  });

  @override
  State<AIThinkingIndicator> createState() => _AIThinkingIndicatorState();
}

class _AIThinkingIndicatorState extends State<AIThinkingIndicator>
    with TickerProviderStateMixin {
  late List<AnimationController> _dotControllers;
  late List<Animation<double>> _dotAnimations;

  @override
  void initState() {
    super.initState();
    _dotControllers = List.generate(
      3,
      (index) => AnimationController(
        duration: Duration(milliseconds: 600 + (index * 200)),
        vsync: this,
      ),
    );

    _dotAnimations = _dotControllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ));
    }).toList();

    _startAnimations();
  }

  void _startAnimations() {
    for (var controller in _dotControllers) {
      controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    for (var controller in _dotControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    
    return Container(
      margin: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: isSmallScreen ? 28 : 32,
            height: isSmallScreen ? 28 : 32,
            decoration: AppTheme.gradientDecoration,
            child: Icon(
              Icons.medical_services,
              color: Colors.white,
              size: isSmallScreen ? 14 : 16,
            ),
          ),
          SizedBox(width: isSmallScreen ? 8 : 12),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.cardShadow,
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.message != null) ...[
                    Text(
                      widget.message!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontStyle: FontStyle.italic,
                        fontSize: isSmallScreen ? 13 : 14,
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 6 : 8),
                  ],
                  if (widget.showDots) ...[
                    Row(
                      children: [
                        Text(
                          'AI is thinking',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                            fontSize: isSmallScreen ? 10 : 12,
                          ),
                        ),
                        SizedBox(width: isSmallScreen ? 6 : 8),
                        ...List.generate(3, (index) {
                          return AnimatedBuilder(
                            animation: _dotAnimations[index],
                            builder: (context, child) {
                              return Container(
                                margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 1.5 : 2),
                                width: isSmallScreen ? 5 : 6,
                                height: isSmallScreen ? 5 : 6,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(
                                    0.3 + (0.7 * _dotAnimations[index].value),
                                  ),
                                  shape: BoxShape.circle,
                                ),
                              );
                            },
                          );
                        }),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 