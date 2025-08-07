import 'package:flutter/material.dart';
import '../app_theme.dart';

enum VoiceButtonState { idle, listening, processing }

class EnhancedVoiceButton extends StatefulWidget {
  final VoiceButtonState state;
  final VoidCallback? onTap;
  final double size;

  const EnhancedVoiceButton({
    super.key,
    this.state = VoiceButtonState.idle,
    this.onTap,
    this.size = 48,
  });

  @override
  State<EnhancedVoiceButton> createState() => _EnhancedVoiceButtonState();
}

class _EnhancedVoiceButtonState extends State<EnhancedVoiceButton>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rippleController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rippleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _rippleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rippleController,
      curve: Curves.easeOut,
    ));

    _updateAnimation();
  }

  @override
  void didUpdateWidget(EnhancedVoiceButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _updateAnimation();
    }
  }

  void _updateAnimation() {
    switch (widget.state) {
      case VoiceButtonState.idle:
        _pulseController.stop();
        _rippleController.stop();
        break;
      case VoiceButtonState.listening:
        _pulseController.repeat(reverse: true);
        _rippleController.repeat();
        break;
      case VoiceButtonState.processing:
        _pulseController.repeat(reverse: true);
        _rippleController.repeat();
        break;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseController, _rippleController]),
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Ripple effect
              if (widget.state != VoiceButtonState.idle)
                Transform.scale(
                  scale: 1.0 + (_rippleAnimation.value * 0.5),
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.accentColor.withOpacity(
                        0.3 * (1.0 - _rippleAnimation.value),
                      ),
                    ),
                  ),
                ),
              
              // Main button
              Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    color: _getButtonColor(),
                    borderRadius: BorderRadius.circular(widget.size / 2),
                    boxShadow: [
                      BoxShadow(
                        color: _getButtonColor().withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    _getButtonIcon(),
                    color: Colors.white,
                    size: widget.size * 0.4,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Color _getButtonColor() {
    switch (widget.state) {
      case VoiceButtonState.idle:
        return AppTheme.accentColor;
      case VoiceButtonState.listening:
        return AppTheme.errorColor;
      case VoiceButtonState.processing:
        return AppTheme.primaryColor;
    }
  }

  IconData _getButtonIcon() {
    switch (widget.state) {
      case VoiceButtonState.idle:
        return Icons.mic;
      case VoiceButtonState.listening:
        return Icons.mic;
      case VoiceButtonState.processing:
        return Icons.psychology;
    }
  }
} 