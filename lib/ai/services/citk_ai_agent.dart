// Purpose: Main AI Agent that connects to Firebase and Gemini
// ===========================================================================

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

/// CITK Knowledge retrieved from Firebase
class CITKKnowledge {
  final Map<String, dynamic> library;
  final Map<String, dynamic> hostels;
  final List<dynamic> buses;
  final Map<String, dynamic> departments;
  final Map<String, dynamic> facilities;
  final Map<String, dynamic> contacts;

  CITKKnowledge({
    required this.library,
    required this.hostels,
    required this.buses,
    required this.departments,
    required this.facilities,
    required this.contacts,
  });

  factory CITKKnowledge.fromFirestore(Map<String, dynamic> data) {
    return CITKKnowledge(
      library: data['library'] ?? {},
      hostels: data['hostels'] ?? {},
      buses: data['buses'] ?? [],
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

  /// Initialize agent and load Firebase data
  Future<void> initialize() async {
    if (_isInitialized) return;

    debugPrint('🤖 Initializing CITK AI Agent...');

    // Load knowledge base from Firebase
    await _loadKnowledgeBase();

    // Initialize Gemini model
    _model = GenerativeModel(
      model: 'gemini-2.0-flash-exp',
      apiKey: apiKey,
      tools: [Tool(functionDeclarations: _getFunctionDeclarations())],
      systemInstruction: Content.system(_getSystemPrompt()),
    );

    _chat = _model!.startChat();
    _isInitialized = true;

    debugPrint('✅ AI Agent initialized');
  }

  /// Load knowledge base from Firebase
  Future<void> _loadKnowledgeBase() async {
    try {
      final doc = await firestore
          .collection('knowledge_base')
          .doc('campus_info')
          .get();

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
      library: {
        'timings': '9:00 AM - 8:00 PM',
        'location': 'Academic Block',
        'contact': 'library@cit.ac.in'
      },
      hostels: {
        'boys': [
          {'name': 'Dwimalu', 'capacity': 200},
          {'name': 'Jwhwlao', 'capacity': 180}
        ],
        'girls': [
          {'name': 'Gwzwon', 'capacity': 150},
          {'name': 'Nivedita', 'capacity': 120}
        ]
      },
      buses: [
        {
          'route': 'Kokrajhar Railgate → Campus',
          'timings': ['8:30 AM', '9:30 AM']
        }
      ],
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

        // Send function response back
        final functionResponse = FunctionResponse(
          call.name,
          {'status': 'executed', 'message': 'Action initiated'},
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

    buffer.writeln('Respond naturally. If user wants to perform an action, call the appropriate function.');

    return buffer.toString();
  }

  /// Get function declarations for Gemini
  List<FunctionDeclaration> _getFunctionDeclarations() {
    return [
      FunctionDeclaration(
        'open_bus_tracker',
        'Opens live bus tracking screen',
        Schema(SchemaType.object, properties: {}),
      ),
      FunctionDeclaration(
        'open_map',
        'Opens campus map for navigation',
        Schema(SchemaType.object, properties: {}),
      ),
      FunctionDeclaration(
        'open_notices',
        'Shows latest campus notices and announcements',
        Schema(SchemaType.object, properties: {}),
      ),
      FunctionDeclaration(
        'show_notice_detail',
        'Shows detailed information about a specific notice',
        Schema(SchemaType.object, properties: {
          'notice_id': Schema(SchemaType.string, description: 'Notice ID'),
        }),
      ),
      FunctionDeclaration(
        'open_hostels',
        'Shows hostel information and facilities',
        Schema(SchemaType.object, properties: {}),
      ),
      FunctionDeclaration(
        'open_library',
        'Opens library section with timings and info',
        Schema(SchemaType.object, properties: {}),
      ),
      FunctionDeclaration(
        'register_complaint',
        'Opens complaint registration form',
        Schema(SchemaType.object, properties: {}),
      ),
    ];
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
      default:
        return AIAction.none;
    }
  }

  /// Get system prompt
  String _getSystemPrompt() {
    return '''
You are CITK Connect AI, an intelligent assistant for Central Institute of Technology Kokrajhar.

Your capabilities:
1. Answer questions about CITK using provided campus information
2. Search and reference recent notices (scholarships, events, exams, etc.)
3. Help with navigation by calling app functions
4. Provide accurate, helpful information to students

Guidelines:
- Use the provided campus information and notices to answer accurately
- When users want to DO something (track bus, see notices, register complaint), call the appropriate function
- Reference specific notices when relevant
- Be concise, friendly, and student-focused
- If you don't know something, say so honestly
- For emergencies, prioritize safety

Important: You have access to real-time notice data. When answering about recent events, scholarships, or updates, reference the provided notices.
''';
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