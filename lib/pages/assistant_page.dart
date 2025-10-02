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
import '../services/chat_service.dart';
import '../services/doctor_matching_service.dart';
import '../screens/doctor_schedule_booking_screen.dart';

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

  // Separate message lists for each mode
  final List<ChatMessage> _chatMessages = [];
  final List<ChatMessage> _doctorMatchingMessages = [];

  bool _isTyping = false;
  AIState _aiState = AIState.idle;
  VoiceButtonState _voiceState = VoiceButtonState.idle;
  AIProgressStage _currentStage = AIProgressStage.symptomAnalysis;
  String _currentSymptom = '';
  ChatMode _currentMode = ChatMode.simpleChat; // Default to simple chat mode

  // Get current messages based on active mode
  List<ChatMessage> get _messages {
    return _currentMode == ChatMode.simpleChat
        ? _chatMessages
        : _doctorMatchingMessages;
  }

  @override
  void initState() {
    super.initState();
    // Initialize welcome messages for both modes
    _initializeWelcomeMessages();
  }

  void _initializeWelcomeMessages() {
    // Add welcome message for simple chat mode
    final chatWelcomeMessage = ChatMessage(
      text:
          "Hello! I'm your AI health assistant powered by advanced language models. How can I help you today?",
      isUser: false,
      timestamp: DateTime.now(),
      suggestions: [
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
      ],
    );
    _chatMessages.add(chatWelcomeMessage);

    // Add welcome message for doctor matching mode
    final doctorWelcomeMessage = ChatMessage(
      text:
          "Hello! I'm your AI health assistant powered by advanced language models. Please describe your symptoms and I'll help you find the right doctor.",
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
    );
    _doctorMatchingMessages.add(doctorWelcomeMessage);

    // Set default mode (simple chat)
    _currentMode = ChatMode.simpleChat;
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
    final userMessageObj = ChatMessage(
      text: userMessage,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      // Add to the appropriate message list
      if (_currentMode == ChatMode.simpleChat) {
        _chatMessages.add(userMessageObj);
      } else {
        _doctorMatchingMessages.add(userMessageObj);
      }

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

  void _generateAIResponse(String userMessage) async {
    setState(() {
      _isTyping = false;
      _aiState = AIState.responding;

      if (_currentMode == ChatMode.doctorMatching) {
        _currentStage = AIProgressStage.doctorMatching;
      }
    });

    try {
      if (_currentMode == ChatMode.doctorMatching) {
        // RAG-based doctor matching workflow
        await _handleDoctorMatching(userMessage);
      } else {
        // Simple chat mode - use regular AI response
        await _handleSimpleChat(userMessage);
      }
    } catch (e) {
      setState(() {
        final errorMessage = ChatMessage(
          text:
              "I'm sorry, I'm having trouble processing your request right now. Please try again or check your connection.",
          isUser: false,
          timestamp: DateTime.now(),
          suggestions: [
            AISuggestionChip(
              text: "Try again",
              icon: Icons.refresh,
              onTap: () => _generateAIResponse(userMessage),
            ),
            AISuggestionChip(
              text: "Check connection",
              icon: Icons.wifi,
              onTap: () => _checkApiHealth(),
            ),
          ],
        );

        // Add to appropriate message list
        if (_currentMode == ChatMode.simpleChat) {
          _chatMessages.add(errorMessage);
        } else {
          _doctorMatchingMessages.add(errorMessage);
        }

        _aiState = AIState.idle;
      });
    }

    _scrollToBottom();
  }

  // RAG-based doctor matching workflow
  Future<void> _handleDoctorMatching(String userMessage) async {
    try {
      // Step 1: Analyze symptoms and get specialty recommendations
      setState(() {
        _currentStage = AIProgressStage.symptomAnalysis;
      });

      final specialtyRecommendation =
          await DoctorMatchingService.analyzeSymptomsAndSuggestSpecialties(
            userMessage,
          );

      // Step 2: Show the specialty explanation to user
      setState(() {
        final explanationMessage = ChatMessage(
          text: specialtyRecommendation.explanation,
          isUser: false,
          timestamp: DateTime.now(),
        );
        _doctorMatchingMessages.add(explanationMessage);
      });

      // Brief pause to let user read the explanation
      await Future.delayed(Duration(milliseconds: 1500));

      // Step 3: Show loading message while searching for doctors
      setState(() {
        _currentStage = AIProgressStage.doctorMatching;
        final loadingMessage = ChatMessage(
          text: "Finding Best Doctor For You...",
          isUser: false,
          timestamp: DateTime.now(),
          isLoading: true,
        );
        _doctorMatchingMessages.add(loadingMessage);
      });

      // Step 4: Search for doctors by specialties
      final locationContext = widget.locationController.getLocationContext();
      final matchingResult =
          await DoctorMatchingService.findDoctorsBySpecialties(
            specialties: specialtyRecommendation.specialties,
            location: locationContext,
            originalQuery: userMessage,
            maxResults: 3,
          );

      // Step 5: Generate doctor results response
      String aiResponse = _generateDoctorResultsResponse(
        specialtyRecommendation,
        matchingResult,
      );

      setState(() {
        // Remove the loading message
        _doctorMatchingMessages.removeLast();

        // Add the final results
        final aiResponseMessage = ChatMessage(
          text: aiResponse,
          isUser: false,
          timestamp: DateTime.now(),
          doctorSuggestions: _convertToLegacyDoctorSuggestions(
            matchingResult.matchedDoctors,
          ),
          suggestions: _getDoctorMatchingSuggestions(matchingResult),
        );

        _doctorMatchingMessages.add(aiResponseMessage);
        _currentStage = AIProgressStage.completed;
        _aiState = AIState.idle;
      });
    } catch (e) {
      setState(() {
        // Remove loading message if it exists
        if (_doctorMatchingMessages.isNotEmpty &&
            _doctorMatchingMessages.last.text ==
                "Finding Best Doctor For You...") {
          _doctorMatchingMessages.removeLast();
        }

        final errorMessage = ChatMessage(
          text:
              "Sorry, I couldn't find matching doctors right now. This could be due to network issues or temporary service problems. Please try again.",
          isUser: false,
          timestamp: DateTime.now(),
        );
        _doctorMatchingMessages.add(errorMessage);
        _currentStage = AIProgressStage.completed;
        _aiState = AIState.idle;
      });
      throw Exception('Doctor matching failed: $e');
    }
  }

  // Simple chat workflow
  Future<void> _handleSimpleChat(String userMessage) async {
    try {
      String aiResponse = await ChatService.sendMessage(userMessage);

      setState(() {
        final aiResponseMessage = ChatMessage(
          text: aiResponse,
          isUser: false,
          timestamp: DateTime.now(),
          suggestions: _getSuggestions(userMessage, _currentMode),
        );

        _chatMessages.add(aiResponseMessage);
        _aiState = AIState.idle;
      });
    } catch (e) {
      throw Exception('Chat service failed: $e');
    }
  }

  // Generate comprehensive response for doctor matching
  String _generateDoctorResultsResponse(
    SpecialtyRecommendation recommendation,
    DoctorMatchingResult result,
  ) {
    final buffer = StringBuffer();

    if (result.matchedDoctors.isNotEmpty) {
      buffer.writeln(
        "🏥 Here are ${result.matchedDoctors.length} highly recommended doctors in your area:",
      );
    } else {
      buffer.writeln(
        "I couldn't find any doctors matching the suggested specialties in your area.",
      );
      buffer.writeln(
        "You may want to try expanding your search radius or consider telehealth consultations.",
      );
    }

    return buffer.toString();
  }

  // Convert new doctor format to legacy format for compatibility
  List<DoctorSuggestion> _convertToLegacyDoctorSuggestions(
    List<MatchedDoctor> matchedDoctors,
  ) {
    return matchedDoctors
        .map(
          (doctor) => DoctorSuggestion(
            name: doctor.name,
            specialty: doctor.specialty,
            rating: doctor.rating,
            distance: doctor.distance,
            availability: doctor.nextAvailable,
          ),
        )
        .toList();
  }

  // Generate suggestions for doctor matching results
  List<Widget> _getDoctorMatchingSuggestions(DoctorMatchingResult result) {
    List<Widget> suggestions = [];

    if (result.matchedDoctors.isNotEmpty) {
      // Add booking suggestion for top doctor
      final topDoctor = result.matchedDoctors.first;
      suggestions.add(
        AISuggestionChip(
          text: "Book with ${topDoctor.name.split(' ').last}",
          icon: Icons.calendar_today,
          onTap: () => _initiateBooking(topDoctor),
        ),
      );

      suggestions.add(
        AISuggestionChip(
          text: "See all ${result.matchedDoctors.length} doctors",
          icon: Icons.list,
          onTap: () => _showAllDoctors(result),
        ),
      );
    }

    suggestions.add(
      AISuggestionChip(
        text: "Refine symptoms",
        icon: Icons.edit,
        onTap: () =>
            _sendQuickMessage("I have additional symptoms to describe"),
      ),
    );

    suggestions.add(
      AISuggestionChip(
        text: "Emergency care",
        icon: Icons.emergency,
        onTap: () => _sendQuickMessage("I need emergency care immediately"),
      ),
    );

    return suggestions;
  }

  // Initiate booking process with selected doctor
  void _initiateBooking(MatchedDoctor doctor) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DoctorScheduleBookingScreen(doctor: doctor),
      ),
    );
  }

  // Show detailed view of all matching doctors
  void _showAllDoctors(DoctorMatchingResult result) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildDoctorListModal(result),
    );
  }

  // Build modal showing all matching doctors
  Widget _buildDoctorListModal(DoctorMatchingResult result) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Matching Doctors (${result.matchedDoctors.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          // Doctor list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: result.matchedDoctors.length,
              itemBuilder: (context, index) {
                final doctor = result.matchedDoctors[index];
                return _buildDoctorCard(doctor);
              },
            ),
          ),
        ],
      ),
    );
  }

  // Build individual doctor card
  Widget _buildDoctorCard(MatchedDoctor doctor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with name and match score
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctor.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        doctor.specialty,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(doctor.matchScore * 100).toInt()}% match',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Details
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text('${doctor.rating} (${doctor.reviewCount} reviews)'),
                const SizedBox(width: 16),
                Icon(Icons.location_on, color: Colors.grey, size: 16),
                const SizedBox(width: 4),
                Text(doctor.distance),
              ],
            ),

            const SizedBox(height: 8),

            // Availability and fee
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Next: ${doctor.nextAvailable}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
                Text(
                  '৳${doctor.consultationFee.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _sendQuickMessage("Tell me more about ${doctor.name}");
                    },
                    child: const Text('View Details'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _initiateBooking(doctor);
                    },
                    child: const Text('Book Now'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to check API health
  void _checkApiHealth() async {
    bool isHealthy = await ChatService.checkApiHealth();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isHealthy
                ? 'AI service is online and ready!'
                : 'AI service is offline. Using fallback responses.',
          ),
          backgroundColor: isHealthy ? Colors.green : Colors.orange,
        ),
      );
    }
  }

  // Helper method to get suggestion chips based on context
  List<Widget> _getSuggestions(String userMessage, ChatMode mode) {
    final lowerMessage = userMessage.toLowerCase();

    if (mode == ChatMode.doctorMatching) {
      if (lowerMessage.contains('headache') ||
          lowerMessage.contains('migraine')) {
        return [
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
        ];
      } else if (lowerMessage.contains('fever') ||
          lowerMessage.contains('cold')) {
        return [
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
        ];
      } else if (lowerMessage.contains('chest pain') ||
          lowerMessage.contains('heart')) {
        return [
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
        ];
      } else {
        return [
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
        ];
      }
    } else {
      // Simple chat mode suggestions
      if (lowerMessage.contains('doclinker')) {
        return [
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
        ];
      } else {
        return [
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
        ];
      }
    }
  }

  void _toggleChatMode(ChatMode newMode) {
    if (_currentMode != newMode) {
      setState(() {
        _currentMode = newMode;
        // Just switch modes - messages are preserved in separate lists
        // Reset any mode-specific state
        if (_currentMode == ChatMode.simpleChat) {
          _currentSymptom = '';
          _currentStage = AIProgressStage.symptomAnalysis;
        }
      });

      // Scroll to bottom to show latest message in the newly selected mode
      _scrollToBottom();
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
      isLoading: message.isLoading,
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<DoctorSuggestion>? doctorSuggestions;
  final List<Widget>? suggestions;
  final bool isLoading;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.doctorSuggestions,
    this.suggestions,
    this.isLoading = false,
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
