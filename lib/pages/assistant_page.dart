import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../widgets/ai_avatar.dart';
import '../widgets/ai_thinking_indicator.dart';
import '../widgets/ai_suggestion_chip.dart';
import '../widgets/ai_progress_tracker.dart';
import '../widgets/enhanced_chat_bubble.dart';
import '../widgets/enhanced_voice_button.dart';
import '../widgets/hospital_selector.dart';
import '../controllers/location_controller.dart';

class AssistantPage extends StatefulWidget {
  final LocationController locationController;

  const AssistantPage({
    super.key,
    required this.locationController,
  });

  @override
  State<AssistantPage> createState() => _AssistantPageState();
}

class _AssistantPageState extends State<AssistantPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  AIState _aiState = AIState.idle;
  VoiceButtonState _voiceState = VoiceButtonState.idle;
  AIProgressStage _currentStage = AIProgressStage.symptomAnalysis;
  String _currentSymptom = '';

  @override
  void initState() {
    super.initState();
    // Add welcome message
    _messages.add(ChatMessage(
      text: "Hello! I'm your AI health assistant. Please describe your symptoms and I'll help you find the right doctor.",
      isUser: false,
      timestamp: DateTime.now(),
      suggestions: [
        AISuggestionChip(
          text: "I have a headache",
          icon: Icons.sick,
          onTap: () => _sendQuickMessage("I have a headache"),
        ),
        AISuggestionChip(
          text: "I have a fever",
          icon: Icons.thermostat,
          onTap: () => _sendQuickMessage("I have a fever"),
        ),
        AISuggestionChip(
          text: "I have chest pain",
          icon: Icons.favorite,
          onTap: () => _sendQuickMessage("I have chest pain"),
        ),
      ],
    ));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendQuickMessage(String message) {
    _messageController.text = message;
    _sendMessage();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text.trim();
    setState(() {
      _messages.add(ChatMessage(
        text: userMessage,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isTyping = true;
      _aiState = AIState.thinking;
      _currentSymptom = userMessage;
      _currentStage = AIProgressStage.symptomAnalysis;
    });

    _messageController.clear();
    _scrollToBottom();

    // Simulate AI response
    Future.delayed(const Duration(seconds: 2), () {
      _generateAIResponse(userMessage);
    });
  }

  void _generateAIResponse(String userMessage) {
    setState(() {
      _isTyping = false;
      _aiState = AIState.responding;
      _currentStage = AIProgressStage.doctorMatching;
      
      // Get location context for AI response
      final locationContext = widget.locationController.getLocationContext();
      
      // Simulate AI analysis and doctor suggestions
      if (userMessage.toLowerCase().contains('headache') || 
          userMessage.toLowerCase().contains('head pain')) {
        _messages.add(ChatMessage(
          text: "I understand you're experiencing headache symptoms. Based on your description and location context ($locationContext), I recommend consulting with a neurologist or general physician. Here are some specialists in your area:",
          isUser: false,
          timestamp: DateTime.now(),
          doctorSuggestions: [
            DoctorSuggestion(
              name: "Dr. Sarah Johnson",
              specialty: "Neurologist",
              rating: 4.8,
              distance: "2.3 km",
              availability: "Tomorrow 2:00 PM",
            ),
            DoctorSuggestion(
              name: "Dr. Michael Chen",
              specialty: "General Physician",
              rating: 4.6,
              distance: "1.8 km",
              availability: "Today 4:30 PM",
            ),
          ],
          suggestions: [
            AISuggestionChip(
              text: "Book with Dr. Johnson",
              icon: Icons.calendar_today,
              onTap: () => _sendQuickMessage("Book appointment with Dr. Johnson"),
            ),
            AISuggestionChip(
              text: "Find more specialists",
              icon: Icons.search,
              onTap: () => _sendQuickMessage("Show me more neurologists"),
            ),
          ],
        ));
      } else if (userMessage.toLowerCase().contains('fever') ||
                userMessage.toLowerCase().contains('temperature')) {
        _messages.add(ChatMessage(
          text: "I see you're experiencing fever symptoms. This could be due to various causes. Based on your location ($locationContext), I recommend seeing a general physician or infectious disease specialist. Here are some options:",
          isUser: false,
          timestamp: DateTime.now(),
          doctorSuggestions: [
            DoctorSuggestion(
              name: "Dr. Emily Davis",
              specialty: "General Physician",
              rating: 4.7,
              distance: "1.2 km",
              availability: "Today 3:00 PM",
            ),
            DoctorSuggestion(
              name: "Dr. Robert Wilson",
              specialty: "Infectious Disease",
              rating: 4.9,
              distance: "3.1 km",
              availability: "Tomorrow 10:00 AM",
            ),
          ],
          suggestions: [
            AISuggestionChip(
              text: "Book with Dr. Davis",
              icon: Icons.calendar_today,
              onTap: () => _sendQuickMessage("Book appointment with Dr. Davis"),
            ),
            AISuggestionChip(
              text: "Get urgent care",
              icon: Icons.emergency,
              onTap: () => _sendQuickMessage("I need urgent care"),
            ),
          ],
        ));
      } else if (userMessage.toLowerCase().contains('chest pain') ||
                userMessage.toLowerCase().contains('heart')) {
        _messages.add(ChatMessage(
          text: "Chest pain is a serious symptom that requires immediate attention. Based on your location ($locationContext), I strongly recommend seeing a cardiologist or visiting urgent care. Here are some specialists:",
          isUser: false,
          timestamp: DateTime.now(),
          doctorSuggestions: [
            DoctorSuggestion(
              name: "Dr. Lisa Martinez",
              specialty: "Cardiologist",
              rating: 4.9,
              distance: "2.8 km",
              availability: "Today 5:00 PM",
            ),
            DoctorSuggestion(
              name: "Dr. James Thompson",
              specialty: "Emergency Medicine",
              rating: 4.8,
              distance: "1.5 km",
              availability: "Immediate",
            ),
          ],
          suggestions: [
            AISuggestionChip(
              text: "Urgent care now",
              icon: Icons.emergency,
              onTap: () => _sendQuickMessage("I need urgent care immediately"),
            ),
            AISuggestionChip(
              text: "Book cardiologist",
              icon: Icons.calendar_today,
              onTap: () => _sendQuickMessage("Book with cardiologist"),
            ),
          ],
        ));
      } else {
        // Generic response
        _messages.add(ChatMessage(
          text: "I understand your symptoms. Based on your location ($locationContext), I can help you find the right specialist. Could you please provide more details about your symptoms?",
          isUser: false,
          timestamp: DateTime.now(),
          suggestions: [
            AISuggestionChip(
              text: "Find nearby doctors",
              icon: Icons.search,
              onTap: () => _sendQuickMessage("Find nearby doctors"),
            ),
            AISuggestionChip(
              text: "Change location",
              icon: Icons.location_on,
              onTap: () => _showHospitalSelector(),
            ),
          ],
        ));
      }
      
      _aiState = AIState.idle;
      _currentStage = AIProgressStage.completed;
    });

    _scrollToBottom();
  }

  void _showHospitalSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => HospitalSelectorModal(
        locationController: widget.locationController,
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

    return Column(
      children: [
        // Compact AI Progress Tracker
        Container(
          padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
          child: AIProgressTracker(
            currentStage: _currentStage,
            showLabels: !isSmallScreen, // Hide labels on small screens
          ),
        ),

        // Hospital Selector
        HospitalSelector(
          locationController: widget.locationController,
          onTap: _showHospitalSelector,
        ),

        // Compact Context Summary (if symptoms are mentioned)
        if (_currentSymptom.isNotEmpty)
          Container(
            margin: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 12 : 16,
              vertical: isSmallScreen ? 4 : 6,
            ),
            padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.primaryColor.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: isSmallScreen ? 14 : 16,
                  color: AppTheme.primaryColor,
                ),
                SizedBox(width: isSmallScreen ? 6 : 8),
                Expanded(
                  child: Text(
                    'Analyzing: $_currentSymptom',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                      fontSize: isSmallScreen ? 11 : 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

        // Chat messages - Give more space
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            itemCount: _messages.length + (_isTyping ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _messages.length) {
                return AIThinkingIndicator(
                  message: "Analyzing your symptoms and finding the best doctors...",
                  showDots: true,
                );
              }
              return _buildMessage(_messages[index]);
            },
          ),
        ),

        // Compact Input area with AI Avatar
        Container(
          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            boxShadow: AppTheme.cardShadow,
          ),
          child: Row(
            children: [
              // AI Avatar - Smaller on small screens
              AIAvatar(
                state: _aiState,
                size: isSmallScreen ? 32 : 40,
                onTap: () {
                  // AI avatar tap action
                },
              ),
              
              SizedBox(width: isSmallScreen ? 8 : 12),

              // Text input
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.textLight.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Describe your symptoms...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 12 : 16,
                        vertical: isSmallScreen ? 8 : 12,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),
              
              SizedBox(width: isSmallScreen ? 8 : 12),
              
              // Enhanced Voice Button - Smaller on small screens
              EnhancedVoiceButton(
                state: _voiceState,
                size: isSmallScreen ? 36 : 48,
                onTap: () {
                  setState(() {
                    _voiceState = VoiceButtonState.listening;
                  });
                  
                  // Simulate voice processing
                  Future.delayed(const Duration(seconds: 2), () {
                    setState(() {
                      _voiceState = VoiceButtonState.idle;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Voice input coming soon!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  });
                },
              ),
              
              SizedBox(width: isSmallScreen ? 8 : 12),
              
              // Send button - Smaller on small screens
              GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                  decoration: AppTheme.buttonDecoration,
                  child: Icon(
                    Icons.send,
                    color: Colors.white,
                    size: isSmallScreen ? 16 : 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessage(ChatMessage message) {
    return EnhancedChatBubble(
      message: message.text,
      isUser: message.isUser,
      timestamp: message.timestamp,
      suggestions: message.suggestions,
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<DoctorSuggestion>? doctorSuggestions;
  final List<Widget>? suggestions;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.doctorSuggestions,
    this.suggestions,
  });
}

class DoctorSuggestion {
  final String name;
  final String specialty;
  final double rating;
  final String distance;
  final String availability;

  DoctorSuggestion({
    required this.name,
    required this.specialty,
    required this.rating,
    required this.distance,
    required this.availability,
  });
} 