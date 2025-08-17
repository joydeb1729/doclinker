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

  const AssistantPage({super.key, required this.locationController});

  @override
  State<AssistantPage> createState() => _AssistantPageState();
}

// Define the chat modes
enum ChatMode { simpleChat, doctorMatching }

class _AssistantPageState extends State<AssistantPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  AIState _aiState = AIState.idle;
  VoiceButtonState _voiceState = VoiceButtonState.idle;
  AIProgressStage _currentStage = AIProgressStage.symptomAnalysis;
  String _currentSymptom = '';
  ChatMode _currentMode =
      ChatMode.doctorMatching; // Default to doctor matching mode

  @override
  void initState() {
    super.initState();
    // Add welcome message based on current mode
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    String welcomeText;
    List<Widget> suggestions;

    if (_currentMode == ChatMode.doctorMatching) {
      welcomeText =
          "Hello! I'm your AI health assistant. Please describe your symptoms and I'll help you find the right doctor.";
      suggestions = [
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
      ];
    } else {
      welcomeText =
          "Hello! I'm your AI health assistant. How can I help you today?";
      suggestions = [
        AISuggestionChip(
          text: "Health tips",
          icon: Icons.health_and_safety,
          onTap: () => _sendQuickMessage("Give me some health tips"),
        ),
        AISuggestionChip(
          text: "About DocLinker",
          icon: Icons.info,
          onTap: () => _sendQuickMessage("Tell me about DocLinker"),
        ),
      ];
    }

    _messages.add(
      ChatMessage(
        text: welcomeText,
        isUser: false,
        timestamp: DateTime.now(),
        suggestions: suggestions,
      ),
    );
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
      _messages.add(
        ChatMessage(text: userMessage, isUser: true, timestamp: DateTime.now()),
      );
      _isTyping = true;
      _aiState = AIState.thinking;

      // Only update symptom and progress in doctor matching mode
      if (_currentMode == ChatMode.doctorMatching) {
        _currentSymptom = userMessage;
        _currentStage = AIProgressStage.symptomAnalysis;
      }
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

      if (_currentMode == ChatMode.doctorMatching) {
        _currentStage = AIProgressStage.doctorMatching;

        // Get location context for AI response
        final locationContext = widget.locationController.getLocationContext();

        // Simulate AI analysis and doctor suggestions
        if (userMessage.toLowerCase().contains('headache') ||
            userMessage.toLowerCase().contains('head pain')) {
          _messages.add(
            ChatMessage(
              text:
                  "I understand you're experiencing headache symptoms. Based on your description and location context ($locationContext), I recommend consulting with a neurologist or general physician. Here are some specialists in your area:",
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
                  onTap: () =>
                      _sendQuickMessage("Book appointment with Dr. Johnson"),
                ),
                AISuggestionChip(
                  text: "Find more specialists",
                  icon: Icons.search,
                  onTap: () => _sendQuickMessage("Show me more neurologists"),
                ),
              ],
            ),
          );
        } else if (userMessage.toLowerCase().contains('fever') ||
            userMessage.toLowerCase().contains('temperature')) {
          _messages.add(
            ChatMessage(
              text:
                  "I see you're experiencing fever symptoms. This could be due to various causes. Based on your location ($locationContext), I recommend seeing a general physician or infectious disease specialist. Here are some options:",
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
                  onTap: () =>
                      _sendQuickMessage("Book appointment with Dr. Davis"),
                ),
                AISuggestionChip(
                  text: "Get urgent care",
                  icon: Icons.emergency,
                  onTap: () => _sendQuickMessage("I need urgent care"),
                ),
              ],
            ),
          );
        } else if (userMessage.toLowerCase().contains('chest pain') ||
            userMessage.toLowerCase().contains('heart')) {
          _messages.add(
            ChatMessage(
              text:
                  "Chest pain is a serious symptom that requires immediate attention. Based on your location ($locationContext), I strongly recommend seeing a cardiologist or visiting urgent care. Here are some specialists:",
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
                  onTap: () =>
                      _sendQuickMessage("I need urgent care immediately"),
                ),
                AISuggestionChip(
                  text: "Book cardiologist",
                  icon: Icons.calendar_today,
                  onTap: () => _sendQuickMessage("Book with cardiologist"),
                ),
              ],
            ),
          );
        } else {
          // Generic response for doctor matching mode
          _messages.add(
            ChatMessage(
              text:
                  "I understand your symptoms. Based on your location ($locationContext), I can help you find the right specialist. Could you please provide more details about your symptoms?",
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
            ),
          );
        }

        _currentStage = AIProgressStage.completed;
      } else {
        // Simple chat mode responses
        if (userMessage.toLowerCase().contains('health tips') ||
            userMessage.toLowerCase().contains('advice')) {
          _messages.add(
            ChatMessage(
              text:
                  "Here are some general health tips:\n\n1. Stay hydrated by drinking at least 8 glasses of water daily\n2. Aim for 7-8 hours of quality sleep each night\n3. Include fruits and vegetables in every meal\n4. Exercise for at least 30 minutes daily\n5. Practice mindfulness or meditation to reduce stress",
              isUser: false,
              timestamp: DateTime.now(),
              suggestions: [
                AISuggestionChip(
                  text: "Exercise tips",
                  icon: Icons.fitness_center,
                  onTap: () => _sendQuickMessage("Give me exercise tips"),
                ),
                AISuggestionChip(
                  text: "Nutrition advice",
                  icon: Icons.restaurant_menu,
                  onTap: () => _sendQuickMessage("Nutrition advice"),
                ),
              ],
            ),
          );
        } else if (userMessage.toLowerCase().contains('doclinker') ||
            userMessage.toLowerCase().contains('about')) {
          _messages.add(
            ChatMessage(
              text:
                  "DocLinker is an AI-powered healthcare platform that connects patients with the right doctors based on their symptoms and medical needs. Our intelligent matching system analyzes your symptoms and finds the most suitable healthcare providers in your area.",
              isUser: false,
              timestamp: DateTime.now(),
              suggestions: [
                AISuggestionChip(
                  text: "Find a doctor",
                  icon: Icons.search,
                  onTap: () => _toggleChatMode(ChatMode.doctorMatching),
                ),
                AISuggestionChip(
                  text: "Health tips",
                  icon: Icons.health_and_safety,
                  onTap: () => _sendQuickMessage("Give me some health tips"),
                ),
              ],
            ),
          );
        } else {
          // Generic simple chat response
          _messages.add(
            ChatMessage(
              text:
                  "I'm here to provide general health information and answer your questions. If you'd like to find a doctor based on your symptoms, you can switch to doctor matching mode.",
              isUser: false,
              timestamp: DateTime.now(),
              suggestions: [
                AISuggestionChip(
                  text: "Switch to doctor matching",
                  icon: Icons.medical_services,
                  onTap: () => _toggleChatMode(ChatMode.doctorMatching),
                ),
                AISuggestionChip(
                  text: "Health tips",
                  icon: Icons.health_and_safety,
                  onTap: () => _sendQuickMessage("Give me some health tips"),
                ),
              ],
            ),
          );
        }
      }

      _aiState = AIState.idle;
    });

    _scrollToBottom();
  }

  void _toggleChatMode(ChatMode newMode) {
    if (_currentMode != newMode) {
      setState(() {
        _currentMode = newMode;
        // Clear messages and add new welcome message
        _messages.clear();
        _addWelcomeMessage();
      });
    }
  }

  void _showHospitalSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          HospitalSelectorModal(locationController: widget.locationController),
    ).then((_) {
      // Force UI update when returning from the hospital selector
      setState(() {
        // Just triggering a rebuild to refresh the hospital name
      });
    });
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
        // Ultra-compact top bar with mode toggle and optional context
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 8 : 12,
            vertical: isSmallScreen ? 4 : 6,
          ),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            children: [
              // Mode toggle as a segmented control
              Container(
                height: isSmallScreen ? 28 : 32,
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.textLight.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Simple Chat Mode Button
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _toggleChatMode(ChatMode.simpleChat),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _currentMode == ChatMode.simpleChat
                                ? AppTheme.primaryColor
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: isSmallScreen ? 12 : 14,
                                color: _currentMode == ChatMode.simpleChat
                                    ? Colors.white
                                    : AppTheme.textSecondary,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Chat',
                                style: TextStyle(
                                  color: _currentMode == ChatMode.simpleChat
                                      ? Colors.white
                                      : AppTheme.textSecondary,
                                  fontWeight: FontWeight.w500,
                                  fontSize: isSmallScreen ? 10 : 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Doctor Matching Mode Button
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _toggleChatMode(ChatMode.doctorMatching),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _currentMode == ChatMode.doctorMatching
                                ? AppTheme.primaryColor
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.medical_services_outlined,
                                size: isSmallScreen ? 12 : 14,
                                color: _currentMode == ChatMode.doctorMatching
                                    ? Colors.white
                                    : AppTheme.textSecondary,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Find Doctor',
                                style: TextStyle(
                                  color: _currentMode == ChatMode.doctorMatching
                                      ? Colors.white
                                      : AppTheme.textSecondary,
                                  fontWeight: FontWeight.w500,
                                  fontSize: isSmallScreen ? 10 : 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Location/Hospital button (only in doctor matching mode)
              if (_currentMode == ChatMode.doctorMatching)
                Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: GestureDetector(
                    onTap: _showHospitalSelector,
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 8 : 10,
                        vertical: isSmallScreen ? 4 : 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: isSmallScreen ? 12 : 14,
                            color: AppTheme.accentColor,
                          ),
                          SizedBox(width: 4),
                          Text(
                            widget.locationController
                                .getLocationContext()
                                .split(',')[0],
                            style: TextStyle(
                              color: AppTheme.accentColor,
                              fontWeight: FontWeight.w500,
                              fontSize: isSmallScreen ? 10 : 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Mini progress indicator for doctor matching mode
        if (_currentMode == ChatMode.doctorMatching &&
            _currentSymptom.isNotEmpty)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 12 : 16,
              vertical: isSmallScreen ? 4 : 6,
            ),
            color: AppTheme.backgroundColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mini progress tracker
                AIProgressTracker(
                  currentStage: _currentStage,
                  showLabels: false, // Always hide labels to save space
                ),

                // Mini symptom indicator
                if (_currentSymptom.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 6 : 8,
                        vertical: isSmallScreen ? 2 : 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: isSmallScreen ? 10 : 12,
                            color: AppTheme.primaryColor,
                          ),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Analyzing: $_currentSymptom',
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w500,
                                fontSize: isSmallScreen ? 9 : 10,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

        // Chat messages - Maximize space
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 8 : 12,
              vertical: isSmallScreen ? 6 : 10,
            ),
            itemCount: _messages.length + (_isTyping ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _messages.length) {
                return AIThinkingIndicator(
                  message: _currentMode == ChatMode.doctorMatching
                      ? "Analyzing your symptoms and finding the best doctors..."
                      : "Thinking...",
                  showDots: true,
                );
              }
              return _buildMessage(_messages[index]);
            },
          ),
        ),

        // Streamlined input area
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 8 : 12,
            vertical: isSmallScreen ? 6 : 8,
          ),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 2,
                offset: Offset(0, -1),
              ),
            ],
          ),
          child: Row(
            children: [
              // AI Avatar - even smaller for minimal design
              AIAvatar(
                state: _aiState,
                size: isSmallScreen ? 28 : 32,
                onTap: () {
                  // AI avatar tap action
                },
              ),

              SizedBox(width: isSmallScreen ? 6 : 8),

              // Text input - clean, minimal design
              Expanded(
                child: Container(
                  height: isSmallScreen ? 36 : 40,
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.textLight.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Text field
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: isSmallScreen ? 12 : 14,
                          ),
                          child: TextField(
                            controller: _messageController,
                            decoration: InputDecoration(
                              hintText: _currentMode == ChatMode.doctorMatching
                                  ? 'Describe your symptoms...'
                                  : 'Type your message...',
                              hintStyle: TextStyle(
                                color: AppTheme.textLight,
                                fontSize: isSmallScreen ? 12 : 14,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 8),
                              isDense: true,
                            ),
                            style: TextStyle(fontSize: isSmallScreen ? 13 : 15),
                            maxLines: 1,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                      ),

                      // Voice button
                      Container(
                        margin: EdgeInsets.only(right: 2),
                        child: EnhancedVoiceButton(
                          state: _voiceState,
                          size: isSmallScreen ? 28 : 30,
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
                      ),

                      // Send button
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _sendMessage,
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          ),
                          child: Container(
                            height: double.infinity,
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 10 : 12,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(20),
                                bottomRight: Radius.circular(20),
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.send,
                                color: Colors.white,
                                size: isSmallScreen ? 14 : 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
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
