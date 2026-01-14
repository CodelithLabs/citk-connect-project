// Purpose: Main AI Agent that connects to Firebase and Gemini
// ===========================================================================

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:citk_connect/ai/bus_schedule_data.dart';
import 'package:citk_connect/ai/campus_data.dart';
import 'package:citk_connect/ai/function_declarations.dart';
import 'package:citk_connect/ai/timetable_data.dart';
import 'package:intl/intl.dart';

/// Provider for the CITK AI Agent
final citkAgentProvider = Provider<CITKAIAgent>((ref) {
  // Get API key from environment variable (injected at build time via --dart-define)
  // Falls back to empty string if not provided (will be handled during initialization)
  final apiKey =
      const String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  return CITKAIAgent(
    apiKey: apiKey,
    firestore: FirebaseFirestore.instance,
  );
});

/// CITK Knowledge retrieved from Firebase
class CITKKnowledge {
  final Map<String, dynamic> library;
  final Map<String, dynamic> hostels;
  final List<dynamic> buses;
  final Map<String, dynamic> busSchedule;
  final Map<String, dynamic> timetable;
  final Map<String, dynamic> departments;
  final Map<String, dynamic> facilities;
  final Map<String, dynamic> contacts;

  CITKKnowledge({
    required this.library,
    required this.hostels,
    required this.buses,
    required this.busSchedule,
    required this.timetable,
    required this.departments,
    required this.facilities,
    required this.contacts,
  });

  factory CITKKnowledge.fromFirestore(Map<String, dynamic> data) {
    return CITKKnowledge(
      library: data['library'] ?? {},
      hostels: data['hostels'] ?? {},
      buses: data['buses'] ?? [],
      busSchedule: data['bus_schedule'] ?? {},
      timetable: data['timetable'] ?? {},
      departments: data['departments'] ?? {},
      facilities: data['facilities'] ?? {},
      contacts: data['contacts'] ?? {},
    );
  }

  String toContextString() {
    return '''
CITK Campus Information:

Library: ${library['timings']} at ${library['location']}
Contact: ${library['contact']}

Hostels:
Boys: ${(hostels['boys'] as List).map((h) => h['name']).join(', ')}
Girls: ${(hostels['girls'] as List).map((h) => h['name']).join(', ')}

Bus Routes: ${buses.length} routes available
First route: ${buses.isNotEmpty ? buses[0]['route'] : 'N/A'}

Bus Schedule (Effective ${busSchedule['meta']?['effective_from'] ?? 'Unknown'}):
Weekdays:
  Morning: CIT->Town ${busSchedule['weekdays']?['morning']?['cit_to_town']}, Town->CIT ${busSchedule['weekdays']?['morning']?['town_to_cit']}
  Afternoon: CIT->Town ${busSchedule['weekdays']?['afternoon']?['cit_to_town']}, Town->CIT ${busSchedule['weekdays']?['afternoon']?['town_to_cit']}
  Evening: CIT->Town ${busSchedule['weekdays']?['evening']?['cit_to_town']}, Town->CIT ${busSchedule['weekdays']?['evening']?['town_to_cit']}
Weekends:
  Morning: CIT->Town ${busSchedule['weekends']?['morning']?['cit_to_town']}, Town->CIT ${busSchedule['weekends']?['morning']?['town_to_cit']}
  Afternoon: CIT->Town ${busSchedule['weekends']?['afternoon']?['cit_to_town']}, Town->CIT ${busSchedule['weekends']?['afternoon']?['town_to_cit']}
  Evening: CIT->Town ${busSchedule['weekends']?['evening']?['cit_to_town']}, Town->CIT ${busSchedule['weekends']?['evening']?['town_to_cit']}

Academic Timetable (2026):
$timetable
''';
  }
}

/// Notice model from Firebase
class CITKNotice {
  final String id;
  final String title;
  final String date;
  final String url;
  final String category;
  final List<String> targetAudience;
  final String summary;
  final bool isImportant;
  final Map<String, dynamic>? entities;

  CITKNotice({
    required this.id,
    required this.title,
    required this.date,
    required this.url,
    required this.category,
    required this.targetAudience,
    required this.summary,
    required this.isImportant,
    this.entities,
  });

  factory CITKNotice.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final aiAnalysis = data['ai_analysis'] as Map<String, dynamic>;

    return CITKNotice(
      id: doc.id,
      title: data['meta']['title'],
      date: data['meta']['date'],
      url: data['meta']['url'],
      category: aiAnalysis['category'] ?? 'General',
      targetAudience: List<String>.from(aiAnalysis['target_audience'] ?? []),
      summary: aiAnalysis['summary'] ?? '',
      isImportant: aiAnalysis['is_important'] ?? false,
      entities: aiAnalysis['entities'],
    );
  }
}

/// AI Actions the agent can execute
enum AIAction {
  openBusTracker,
  openMap,
  openHostels,
  openLibrary,
  openTimetable,
  openComplaints,
  openNotices,
  openProfile,
  showNoticeDetail,
  searchNotices,
  callEmergency,
  findNextClass,
  none,
}

/// Action response from AI
class AIActionResponse {
  final String message;
  final AIAction? action;
  final Map<String, dynamic>? params;
  final List<CITKNotice>? relatedNotices;

  AIActionResponse({
    required this.message,
    this.action,
    this.params,
    this.relatedNotices,
  });
}

/// Main CITK AI Agent
class CITKAIAgent {
  final String apiKey;
  final FirebaseFirestore firestore;

  GenerativeModel? _model;
  ChatSession? _chat;
  CITKKnowledge? _knowledge;
  bool _isInitialized = false;

  CITKAIAgent({
    required this.apiKey,
    required this.firestore,
  });

  /// Expose knowledge for UI consumption
  CITKKnowledge? get knowledge => _knowledge;

  /// Initialize agent and load Firebase data
  Future<void> initialize() async {
    if (_isInitialized) return;

    debugPrint('🤖 Initializing CITK AI Agent...');

    try {
      // CRITICAL: Validate API key before proceeding
      if (apiKey.isEmpty) {
        throw Exception('GEMINI_API_KEY is not configured. '
            'Run: flutter run --dart-define=GEMINI_API_KEY=your_key_here');
      }

      // Load knowledge base from Firebase
      await _loadKnowledgeBase();

      // Initialize Gemini model
      _model = GenerativeModel(
        model: 'gemini-2.0-flash-exp',
        apiKey: apiKey,
        tools: [Tool(functionDeclarations: getFunctionDeclarations())],
        systemInstruction: Content.system(getSystemPrompt()),
      );

      _chat = _model!.startChat();
      _isInitialized = true;

      debugPrint('✅ AI Agent initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize AI Agent: $e');
      rethrow;
    }
  }

  /// Load knowledge base from Firebase
  Future<void> _loadKnowledgeBase() async {
    try {
      final doc =
          await firestore.collection('knowledge_base').doc('campus_info').get();

      if (doc.exists) {
        _knowledge = CITKKnowledge.fromFirestore(doc.data()!);
        debugPrint('✅ Knowledge base loaded');
      } else {
        debugPrint('⚠️  Knowledge base not found in Firebase');
        _knowledge = _getDefaultKnowledge();
      }
    } catch (e) {
      debugPrint('❌ Failed to load knowledge: $e');
      _knowledge = _getDefaultKnowledge();
    }
  }

  /// Get default knowledge if Firebase fails
  CITKKnowledge _getDefaultKnowledge() {
    return CITKKnowledge(
      library: getLibraryData(),
      hostels: getHostelsData(),
      buses: getBusesData(),
      busSchedule: getBusScheduleData(),
      timetable: getTimetableData(),
      departments: {},
      facilities: {},
      contacts: {},
    );
  }

  /// Search notices in Firebase based on query
  Future<List<CITKNotice>> searchNotices(String query) async {
    try {
      // Simple keyword search (you can enhance this with vector search)
      final snapshot = await firestore
          .collection('notices')
          .orderBy('meta.date', descending: true)
          .limit(10)
          .get();

      final notices = snapshot.docs
          .map((doc) => CITKNotice.fromFirestore(doc))
          .where((notice) =>
              notice.title.toLowerCase().contains(query.toLowerCase()) ||
              notice.summary.toLowerCase().contains(query.toLowerCase()) ||
              notice.category.toLowerCase().contains(query.toLowerCase()))
          .toList();

      return notices;
    } catch (e) {
      debugPrint('❌ Notice search failed: $e');
      return [];
    }
  }

  /// Get recent important notices
  Future<List<CITKNotice>> getImportantNotices({int limit = 5}) async {
    try {
      final snapshot = await firestore
          .collection('notices')
          .where('ai_analysis.is_important', isEqualTo: true)
          .orderBy('meta.date', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => CITKNotice.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('❌ Failed to get important notices: $e');
      return [];
    }
  }

  /// Send message to AI agent
  Future<AIActionResponse> sendMessage(String userMessage) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Step 1: Search for relevant notices
      final relevantNotices = await searchNotices(userMessage);

      // Step 2: Build context with knowledge + notices
      final context = _buildContext(userMessage, relevantNotices);

      // Step 3: Send to Gemini
      var response = await _chat!.sendMessage(Content.text(context));

      // Step 4: Handle function calls
      final functionCalls = response.functionCalls.toList();

      if (functionCalls.isNotEmpty) {
        final call = functionCalls.first;
        final action = _mapFunctionToAction(call.name);

        // Execute logic for specific tools that return data to the LLM
        Map<String, dynamic> executionResult = {
          'status': 'executed',
          'message': 'Action initiated'
        };
        if (call.name == 'find_next_class') {
          executionResult = _executeFindNextClass(call.args);
        }

        // Send function response back
        final functionResponse = FunctionResponse(
          call.name,
          executionResult,
        );

        response = await _chat!.sendMessage(
          Content.functionResponses([functionResponse]),
        );

        return AIActionResponse(
          message: response.text ?? 'Action initiated',
          action: action,
          params: call.args,
          relatedNotices: relevantNotices,
        );
      }

      // Step 5: Regular response
      return AIActionResponse(
        message: response.text ?? 'I didn\'t understand that.',
        relatedNotices: relevantNotices.isNotEmpty ? relevantNotices : null,
      );
    } catch (e) {
      debugPrint('❌ AI Agent error: $e');
      return AIActionResponse(
        message: 'Sorry, I encountered an error. Please try again.',
      );
    }
  }

  /// Build context for AI with knowledge and notices
  String _buildContext(String query, List<CITKNotice> notices) {
    final buffer = StringBuffer();

    buffer.writeln('User Query: $query\n');

    // Add campus knowledge
    if (_knowledge != null) {
      buffer.writeln('Campus Information:');
      buffer.writeln(_knowledge!.toContextString());
      buffer.writeln();
    }

    // Add relevant notices
    if (notices.isNotEmpty) {
      buffer.writeln('Relevant Recent Notices:');
      for (final notice in notices.take(3)) {
        buffer.writeln('- ${notice.title}');
        buffer.writeln('  Date: ${notice.date}');
        buffer.writeln('  Category: ${notice.category}');
        buffer.writeln('  Summary: ${notice.summary}');
        buffer.writeln();
      }
    }

    buffer.writeln(
        'Respond naturally. If user wants to perform an action, call the appropriate function.');

    return buffer.toString();
  }



  /// Map function name to action enum
  AIAction _mapFunctionToAction(String functionName) {
    switch (functionName) {
      case 'open_bus_tracker':
        return AIAction.openBusTracker;
      case 'open_map':
        return AIAction.openMap;
      case 'open_notices':
        return AIAction.openNotices;
      case 'show_notice_detail':
        return AIAction.showNoticeDetail;
      case 'open_hostels':
        return AIAction.openHostels;
      case 'open_library':
        return AIAction.openLibrary;
      case 'register_complaint':
        return AIAction.openComplaints;
      case 'find_next_class':
        return AIAction.findNextClass;
      default:
        return AIAction.none;
    }
  }

  /// Logic to find the next class from the timetable
  Map<String, dynamic> _executeFindNextClass(Map<String, dynamic> args) {
    try {
      final semGroup = args['semester_group'] as String?;
      final branch = args['branch'] as String?;

      if (semGroup == null || branch == null || _knowledge == null) {
        return {'error': 'Missing information or knowledge base not loaded'};
      }

      final now = DateTime.now();
      final dayName = DateFormat('EEEE').format(now).toUpperCase();

      // Access the schedule
      final schedule =
          _knowledge!.timetable['schedule'] as Map<String, dynamic>?;
      if (schedule == null) return {'error': 'No schedule data found'};

      final daySchedule = schedule[dayName] as Map<String, dynamic>?;
      if (daySchedule == null)
        return {'result': 'No classes scheduled for $dayName.'};

      final groupSchedule = daySchedule[semGroup] as Map<String, dynamic>?;
      if (groupSchedule == null)
        return {'error': 'Semester group $semGroup not found'};

      // Handle branch variations (e.g., CSE_A, CSE_B in JSON vs just CSE)
      // Simple fuzzy match for demo
      final branchKey = groupSchedule.keys.firstWhere(
        (k) => k.toUpperCase().contains(branch.toUpperCase()),
        orElse: () => '',
      );

      if (branchKey.isEmpty)
        return {'error': 'Branch $branch not found in $semGroup'};

      final classInfo = groupSchedule[branchKey] as Map<String, dynamic>;
      final slots = List<String>.from(classInfo['slots'] ?? []);
      final room = classInfo['room'] ?? 'Unknown Room';

      // Determine current slot based on time (Assuming 9 AM start, 1 hour slots)
      // 0: 09-10, 1: 10-11, 2: 11-12, 3: 12-01, 4: Lunch, 5: 02-03, 6: 03-04, 7: 04-05
      int currentHour = now.hour;
      int slotIndex = currentHour - 9;

      if (slotIndex < 0)
        return {
          'result':
              'Classes haven\'t started yet. First class is ${slots.firstWhere((s) => s.isNotEmpty, orElse: () => "Free")} at 9:00 AM.'
        };
      if (slotIndex >= slots.length)
        return {'result': 'Classes are over for today.'};

      // Find next non-empty slot
      for (int i = slotIndex; i < slots.length; i++) {
        if (slots[i].isNotEmpty && slots[i] != "Lunch Break") {
          return {
            'result': 'Next class: ${slots[i]} in Room $room at ${9 + i}:00.'
          };
        }
      }

      return {'result': 'No more classes for today.'};
    } catch (e) {
      return {'error': 'Failed to calculate next class: $e'};
    }
  }



  /// Reset conversation
  void reset() {
    if (_model != null) {
      _chat = _model!.startChat();
    }
  }

  /// Dispose
  void dispose() {
    _model = null;
    _chat = null;
    _isInitialized = false;
  }
}

String getSystemPrompt() {
  return '''
You are the CITK Digital Senior, a helpful AI assistant for the Central Institute of Technology Kokrajhar (CITK).
Your goal is to assist students with information about the campus, bus schedules, hostels, library, and academic timetable.
Use the provided context to answer questions accurately.
''';
}
