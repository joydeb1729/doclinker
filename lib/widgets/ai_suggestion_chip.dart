import 'package:flutter/material.dart';
import '../app_theme.dart';

class AISuggestionChip extends StatefulWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool isHighlighted;
  final Color? color;

  const AISuggestionChip({
    super.key,
    required this.text,
    this.icon,
    this.onTap,
    this.isHighlighted = false,
    this.color,
  });

  @override
  State<AISuggestionChip> createState() => _AISuggestionChipState();
}

class _AISuggestionChipState extends State<AISuggestionChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() {
      _isPressed = true;
    });
    _animationController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() {
      _isPressed = false;
    });
    _animationController.reverse();
  }

  void _handleTapCancel() {
    setState(() {
      _isPressed = false;
    });
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final chipColor = widget.color ?? AppTheme.primaryColor;
    
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              margin: const EdgeInsets.only(right: 8, bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: widget.isHighlighted
                    ? chipColor.withOpacity(0.15)
                    : AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.isHighlighted
                      ? chipColor
                      : chipColor.withOpacity(0.3),
                  width: widget.isHighlighted ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: chipColor.withOpacity(_isPressed ? 0.3 : 0.1),
                    blurRadius: _isPressed ? 8 : 4,
                    offset: Offset(0, _isPressed ? 2 : 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    Icon(
                      widget.icon,
                      size: 16,
                      color: widget.isHighlighted
                          ? chipColor
                          : chipColor.withOpacity(0.7),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    widget.text,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: widget.isHighlighted
                          ? chipColor
                          : AppTheme.textPrimary,
                      fontWeight: widget.isHighlighted
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class AISuggestionChips extends StatelessWidget {
  final List<AISuggestionChip> chips;
  final String? title;

  const AISuggestionChips({
    super.key,
    required this.chips,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Wrap(
            children: chips,
          ),
        ],
      ),
    );
  }
} 