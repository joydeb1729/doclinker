import 'package:flutter/material.dart';
import '../app_theme.dart';

class EnhancedChatBubble extends StatefulWidget {
  final String message;
  final bool isUser;
  final DateTime timestamp;
  final List<Widget>? suggestions;
  final VoidCallback? onTap;

  const EnhancedChatBubble({
    super.key,
    required this.message,
    required this.isUser,
    required this.timestamp,
    this.suggestions,
    this.onTap,
  });

  @override
  State<EnhancedChatBubble> createState() => _EnhancedChatBubbleState();
}

class _EnhancedChatBubbleState extends State<EnhancedChatBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!widget.isUser) ...[
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
              ],
              
              Expanded(
                child: Column(
                  crossAxisAlignment: widget.isUser 
                      ? CrossAxisAlignment.end 
                      : CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                      decoration: BoxDecoration(
                        color: widget.isUser 
                            ? AppTheme.primaryColor 
                            : AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: widget.isUser
                                ? AppTheme.primaryColor.withOpacity(0.2)
                                : AppTheme.cardShadow.first.color,
                            blurRadius: widget.isUser ? 8 : 4,
                            offset: widget.isUser 
                                ? const Offset(0, 2)
                                : AppTheme.cardShadow.first.offset,
                          ),
                        ],
                        border: !widget.isUser
                            ? Border.all(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                width: 1,
                              )
                            : null,
                      ),
                      child: Text(
                        widget.message,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: widget.isUser 
                              ? Colors.white 
                              : AppTheme.textPrimary,
                          fontSize: isSmallScreen ? 13 : 14,
                        ),
                      ),
                    ),
                    
                    if (widget.suggestions != null) ...[
                      SizedBox(height: isSmallScreen ? 8 : 12),
                      ...widget.suggestions!,
                    ],
                    
                    SizedBox(height: isSmallScreen ? 2 : 4),
                    Text(
                      _formatTime(widget.timestamp),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textLight,
                        fontSize: isSmallScreen ? 9 : 10,
                      ),
                    ),
                  ],
                ),
              ),
              
              if (widget.isUser) ...[
                SizedBox(width: isSmallScreen ? 8 : 12),
                Container(
                  width: isSmallScreen ? 28 : 32,
                  height: isSmallScreen ? 28 : 32,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 16),
                  ),
                  child: Icon(
                    Icons.person,
                    color: AppTheme.primaryColor,
                    size: isSmallScreen ? 14 : 16,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
} 