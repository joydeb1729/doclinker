import 'package:flutter/material.dart';
import '../app_theme.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  final List<OnboardingCard> _onboardingCards = [
    OnboardingCard(
      title: 'Smart Doctor Matching',
      description: 'Find the perfect doctor for your needs using our intelligent AI-powered matching system.',
      icon: Icons.psychology,
      heroTag: 'onboarding_icon_1',
      gradient: [AppTheme.primaryColor, AppTheme.accentColor],
    ),
    OnboardingCard(
      title: 'Book Consultations',
      description: 'Schedule appointments with ease, whether virtual or in-person consultations.',
      icon: Icons.calendar_today,
      heroTag: 'onboarding_icon_2',
      gradient: [AppTheme.accentColor, AppTheme.primaryColor],
    ),
    OnboardingCard(
      title: 'Secure Health Management',
      description: 'Access your medical records and appointments safely from any device.',
      icon: Icons.security,
      heroTag: 'onboarding_icon_3',
      gradient: [AppTheme.primaryColor, AppTheme.accentColor],
    ),
  ];

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    
    // Start initial animation
    _scaleController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scaleController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _onboardingCards.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      _getStarted();
    }
  }

  void _getStarted() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    
    // Trigger animations for new page
    _scaleController.reset();
    _fadeController.reset();
    _scaleController.forward();
    _fadeController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: _getStarted,
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
            
            // PageView with custom transitions
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _onboardingCards.length,
                physics: const ClampingScrollPhysics(), // Disable bouncing
                itemBuilder: (context, index) {
                  return _buildOnboardingPage(_onboardingCards[index], index);
                },
              ),
            ),
            
            // Bottom section with dots and buttons
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Dot indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _onboardingCards.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 32 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index 
                              ? AppTheme.primaryColor 
                              : AppTheme.textLight.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Next/Get Started button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                        ),
                      ),
                      child: Text(
                        _currentPage == _onboardingCards.length - 1 
                            ? 'Get Started' 
                            : 'Next',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingPage(OnboardingCard card, int index) {
    return AnimatedBuilder(
      animation: Listenable.merge([_scaleAnimation, _fadeAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Hero animated icon with gradient background
                  Hero(
                    tag: card.heroTag,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: card.gradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(AppTheme.borderRadius * 2),
                        boxShadow: [
                          BoxShadow(
                            color: card.gradient.first.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        card.icon,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Title with animation
                  AnimatedBuilder(
                    animation: _fadeAnimation,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _fadeAnimation.value,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - _fadeAnimation.value)),
                          child: Text(
                            card.title,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                              fontSize: 24,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Description with animation
                  AnimatedBuilder(
                    animation: _fadeAnimation,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _fadeAnimation.value,
                        child: Transform.translate(
                          offset: Offset(0, 30 * (1 - _fadeAnimation.value)),
                          child: Text(
                            card.description,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                              height: 1.5,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class OnboardingCard {
  final String title;
  final String description;
  final IconData icon;
  final String heroTag;
  final List<Color> gradient;

  OnboardingCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.heroTag,
    required this.gradient,
  });
} 