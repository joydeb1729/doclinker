import 'package:flutter/material.dart';
import '../app_theme.dart';

enum AIState { idle, listening, thinking, responding }

class AIAvatar extends StatefulWidget {
  final AIState state;
  final double size;
  final VoidCallback? onTap;

  const AIAvatar({
    super.key,
    this.state = AIState.idle,
    this.size = 40,
    this.onTap,
  });

  @override
  State<AIAvatar> createState() => _AIAvatarState();
}

class _AIAvatarState extends State<AIAvatar>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    _updateAnimation();
  }

  @override
  void didUpdateWidget(AIAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _updateAnimation();
    }
  }

  void _updateAnimation() {
    switch (widget.state) {
      case AIState.idle:
        _pulseController.stop();
        _glowController.stop();
        break;
      case AIState.listening:
        _pulseController.repeat(reverse: true);
        _glowController.repeat(reverse: true);
        break;
      case AIState.thinking:
        _pulseController.repeat(reverse: true);
        _glowController.repeat(reverse: true);
        break;
      case AIState.responding:
        _pulseController.repeat(reverse: true);
        _glowController.repeat(reverse: true);
        break;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseController, _glowController]),
        builder: (context, child) {
          return Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(
                    0.3 * _glowAnimation.value,
                  ),
                  blurRadius: 20 * _glowAnimation.value,
                  spreadRadius: 2 * _glowAnimation.value,
                ),
              ],
            ),
            child: Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                decoration: AppTheme.gradientDecoration,
                child: _buildAvatarContent(),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAvatarContent() {
    switch (widget.state) {
      case AIState.idle:
        return const Icon(
          Icons.medical_services,
          color: Colors.white,
          size: 20,
        );
      case AIState.listening:
        return Stack(
          alignment: Alignment.center,
          children: [
            const Icon(
              Icons.medical_services,
              color: Colors.white,
              size: 20,
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppTheme.accentColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentColor.withOpacity(0.6),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      case AIState.thinking:
        return const Icon(
          Icons.psychology,
          color: Colors.white,
          size: 20,
        );
      case AIState.responding:
        return const Icon(
          Icons.chat_bubble,
          color: Colors.white,
          size: 20,
        );
    }
  }
} 