// lib/core/services/chat_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:legal_ai/core/models/chat_message.dart';
import 'package:legal_ai/core/services/pdf_service.dart';
import 'package:legal_ai/core/services/legal_library_service.dart';
import 'package:legal_ai/core/services/document_analysis_service.dart';
import 'package:legal_ai/core/config/api_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final LegalLibraryService _legalLibrary = LegalLibraryService();
  final DocumentAnalysisService _documentService = DocumentAnalysisService();

  List<Map<String, dynamic>> _conversationHistory = [];
  bool _isInitialized = false;
  String? _lastError;
  int _requestCount = 0;
  DateTime _lastRequestTime = DateTime.now();

  ChatService() {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      print('🔄 Initializing Groq API...');

      // Check configuration
      if (!ApiConfig.isConfigured()) {
        _lastError = ApiConfig.getConfigurationError();
        print('❌ $_lastError');
        _isInitialized = false;
        return;
      }

      // Test API connection
      final response = await http.get(
        Uri.parse('${ApiConfig.groqBaseUrl}/models'),
        headers: {
          'Authorization': 'Bearer ${ApiConfig.groqApiKey}',
          'Content-Type': 'application/json',
        },
      ).timeout(
        Duration(seconds: ApiConfig.requestTimeout),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Groq API connected successfully!');
        print('📦 Available models: ${data['data']?.length ?? 0}');
        _isInitialized = true;
        _lastError = null;

        // Initialize conversation with system prompt
        _conversationHistory = [
          {
            'role': 'system',
            'content': _getSystemPrompt(),
          }
        ];
      } else if (response.statusCode == 401) {
        _lastError = 'Invalid API key';
        print('❌ $_lastError');
        _isInitialized = false;
      } else {
        _lastError = 'API returned status ${response.statusCode}';
        print('❌ $_lastError');
        _isInitialized = false;
      }
    } catch (e) {
      _lastError = e.toString();
      print('❌ Error initializing Groq API: $e');
      _isInitialized = false;
    }
  }

  String _getSystemPrompt() {
    return '''You are a professional AI legal assistant for the "Know Your Rights" app.

Your role is to help users with:
1. Legal document drafting (NDAs, leases, employment contracts, wills, power of attorney, etc.)
2. Contract review and comprehensive risk analysis
3. Explaining legal terms, concepts, and procedures in plain language
4. General legal information and guidance
5. Document analysis and recommendations

CRITICAL GUIDELINES:
- Always clarify that you provide general legal information, NOT legal advice
- STRONGLY recommend consulting a licensed attorney for specific legal matters
- Be professional, accurate, helpful, and empathetic
- When discussing legal documents, highlight key clauses, risks, and considerations
- Keep responses concise but informative (aim for 2-4 paragraphs for general questions)
- Use bullet points for lists of requirements, steps, or options
- If asked about jurisdiction-specific laws, ask for the user's location
- Never provide advice that could be construed as practicing law
- Focus on education and document preparation assistance
- When drafting documents, provide complete, professional templates with proper formatting
- For complex legal matters, emphasize the importance of professional legal counsel
- If you're unsure about something, admit it and recommend professional consultation
- Format documents clearly with sections, headings, and proper structure
- Always include appropriate disclaimers in generated documents

RESPONSE STYLE:
- Use clear, accessible language while maintaining legal accuracy
- Break down complex concepts into understandable parts
- Provide examples when helpful
- Offer actionable next steps
- Be supportive and non-judgmental
- Use markdown formatting for better readability''';
  }

  String get _userId {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return user.uid;
  }

  // Rate limiting check
  bool _checkRateLimit() {
    final now = DateTime.now();
    final timeDiff = now.difference(_lastRequestTime);

    if (timeDiff.inMinutes >= 1) {
      _requestCount = 0;
      _lastRequestTime = now;
    }

    if (_requestCount >= ApiConfig.requestsPerMinute) {
      return false;
    }

    _requestCount++;
    return true;
  }

  // Stream to get all chat messages
  Stream<List<ChatMessage>> getMessages() {
    try {
      return _db
          .collection('users')
          .doc(_userId)
          .collection('chat_history')
          .orderBy('timestamp', descending: true)
          .limit(100)
          .snapshots()
          .handleError((error) {
        print('Error fetching messages: $error');
      }).map((snapshot) {
        try {
          return snapshot.docs
              .map((doc) => ChatMessage.fromFirestore(doc))
              .toList();
        } catch (e) {
          print('Error parsing messages: $e');
          return <ChatMessage>[];
        }
      });
    } catch (e) {
      print('Error in getMessages: $e');
      return Stream.value(<ChatMessage>[]);
    }
  }

  // Add message to Firestore
  Future<void> addMessage(ChatMessage message) async {
    try {
      await _db
          .collection('users')
          .doc(_userId)
          .collection('chat_history')
          .add(message.toFirestore());
    } catch (e) {
      print('Error adding message: $e');
      rethrow;
    }
  }

  // Clear chat history
  Future<void> clearHistory() async {
    try {
      final batch = _db.batch();
      final snapshot = await _db
          .collection('users')
          .doc(_userId)
          .collection('chat_history')
          .get();

      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      // Reset conversation history
      _conversationHistory = [
        {
          'role': 'system',
          'content': _getSystemPrompt(),
        }
      ];

      print('✅ Chat history cleared');
    } catch (e) {
      print('Error clearing history: $e');
      rethrow;
    }
  }

  // Get AI response from Groq
  Future<String> getAIResponse(String userMessage) async {
    print('📤 Sending message to Groq API...');
    print('🔌 API initialized: $_isInitialized');

    // Check initialization
    if (!_isInitialized) {
      print('⚠️ API not initialized, attempting reconnection...');
      await _initialize();

      if (!_isInitialized) {
        return _getFallbackResponse(userMessage);
      }
    }

    // Check rate limit
    if (!_checkRateLimit()) {
      return 'Rate limit reached. Please wait a moment before sending another message. (Limit: ${ApiConfig.requestsPerMinute} requests per minute)';
    }

    try {
      // Add user message to history
      _conversationHistory.add({
        'role': 'user',
        'content': userMessage,
      });

      // Prepare request for Groq
      final requestBody = {
        'model': ApiConfig.groqModel,
        'messages': _conversationHistory,
        'temperature': ApiConfig.temperature,
        'max_tokens': ApiConfig.maxTokens,
        'top_p': 0.95,
        'stream': false,
      };

      print('📨 Sending request to Groq...');
      final startTime = DateTime.now();

      // Send request
      final response = await http.post(
        Uri.parse('${ApiConfig.groqBaseUrl}/chat/completions'),
        headers: {
          'Authorization': 'Bearer ${ApiConfig.groqApiKey}',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      ).timeout(
        Duration(seconds: ApiConfig.requestTimeout),
        onTimeout: () {
          throw Exception('Request timed out after ${ApiConfig.requestTimeout} seconds');
        },
      );

      final duration = DateTime.now().difference(startTime);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final aiResponse = data['choices']?[0]?['message']?['content'] as String?;

        if (aiResponse == null || aiResponse.isEmpty) {
          print('⚠️ Empty response from Groq');
          _conversationHistory.removeLast();
          return _getFallbackResponse(userMessage);
        }

        // Add assistant response to history
        _conversationHistory.add({
          'role': 'assistant',
          'content': aiResponse,
        });

        // Keep conversation history manageable (last 20 messages + system prompt)
        if (_conversationHistory.length > 21) {
          _conversationHistory = [
            _conversationHistory[0], // Keep system prompt
            ..._conversationHistory.sublist(_conversationHistory.length - 20)
          ];
        }

        print('✅ Received response (${aiResponse.length} chars)');
        print('⚡ Response time: ${duration.inMilliseconds}ms');
        print('📊 Tokens used: ${data['usage']?['total_tokens'] ?? 'unknown'}');

        return aiResponse;
      } else if (response.statusCode == 401) {
        _conversationHistory.removeLast();
        _lastError = 'Invalid API key';
        print('❌ $_lastError');
        return 'Error: Invalid API key. Please check your Groq API configuration in api_config.dart';
      } else if (response.statusCode == 429) {
        _conversationHistory.removeLast();
        _lastError = 'Rate limit exceeded';
        print('❌ $_lastError');
        return 'You\'ve reached the rate limit. Please wait a moment and try again.\n\nGroq Free Tier Limits:\n• 30 requests per minute\n• 14,400 requests per day';
      } else {
        print('❌ Groq API error: ${response.statusCode}');
        print('Response: ${response.body}');
        _conversationHistory.removeLast();
        return 'I apologize, but I encountered an error (${response.statusCode}). Please try again in a moment.';
      }
    } catch (e) {
      print('❌ Error getting AI response: $e');
      if (_conversationHistory.isNotEmpty &&
          _conversationHistory.last['role'] == 'user') {
        _conversationHistory.removeLast();
      }
      return _getFallbackResponse(userMessage);
    }
  }

  /// Generate a legal document from a template with AI assistance
  /// This method asks the AI to fill in the template with user-provided information
  Future<String> generateDocumentFromTemplate({
    required String templateKey,
    required String userRequest,
    Map<String, String>? providedData,
  }) async {
    print('📝 Generating document from template: $templateKey');

    // Get the base template
    final template = _legalLibrary.getTemplateByKey(templateKey);
    if (template == null) {
      return 'Error: Template "$templateKey" not found.';
    }

    if (!_isInitialized) {
      await _initialize();
      if (!_isInitialized) {
        return 'Error: Unable to connect to AI service. Please check your configuration.';
      }
    }

    if (!_checkRateLimit()) {
      return 'Rate limit reached. Please wait before generating another document.';
    }

    try {
      // Create a detailed prompt for the AI
      final documentPrompt = _buildDocumentGenerationPrompt(
        templateKey: templateKey,
        template: template,
        userRequest: userRequest,
        providedData: providedData,
      );

      final requestBody = {
        'model': ApiConfig.groqModel,
        'messages': [
          {
            'role': 'system',
            'content': '''You are an expert legal document generator. Your task is to:
1. Take a legal document template with placeholders like [Date], [Party Name], etc.
2. Fill in the placeholders based on user requirements
3. Ensure all legal language remains intact and professional
4. Use realistic, appropriate values for any missing information
5. Add appropriate dates, addresses, and details
6. Return ONLY the completed document without any preamble or explanation
7. Maintain all markdown formatting and structure
8. Use today's date (${DateTime.now().toString().split(' ')[0]}) where appropriate unless specified otherwise

IMPORTANT: Return ONLY the filled document content, no additional commentary.''',
          },
          {
            'role': 'user',
            'content': documentPrompt,
          }
        ],
        'temperature': 0.4, // Lower temperature for consistent document generation
        'max_tokens': 4000,
        'top_p': 0.9,
        'stream': false,
      };

      print('📨 Sending request to AI for document generation...');
      final response = await http.post(
        Uri.parse('${ApiConfig.groqBaseUrl}/chat/completions'),
        headers: {
          'Authorization': 'Bearer ${ApiConfig.groqApiKey}',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      ).timeout(
        Duration(seconds: 60),
        onTimeout: () => throw Exception('Document generation timed out'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final generatedDoc = data['choices']?[0]?['message']?['content'] as String?;

        if (generatedDoc == null || generatedDoc.isEmpty) {
          return 'Error: Failed to generate document content.';
        }

        print('✅ Document generated successfully');
        return generatedDoc;
      } else {
        print('❌ Document generation error: ${response.statusCode}');
        return 'Error: Unable to generate document (${response.statusCode})';
      }
    } catch (e) {
      print('❌ Error generating document: $e');
      return 'Error: Failed to generate document. ${e.toString()}';
    }
  }

  /// Build a detailed prompt for document generation
  String _buildDocumentGenerationPrompt({
    required String templateKey,
    required String template,
    required String userRequest,
    Map<String, String>? providedData,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('USER REQUEST:');
    buffer.writeln(userRequest);
    buffer.writeln();

    if (providedData != null && providedData.isNotEmpty) {
      buffer.writeln('PROVIDED INFORMATION:');
      providedData.forEach((key, value) {
        buffer.writeln('- $key: $value');
      });
      buffer.writeln();
    }

    buffer.writeln('TEMPLATE TO FILL:');
    buffer.writeln(template);
    buffer.writeln();
    buffer.writeln('Please fill in all placeholders (text in square brackets [like this]) with appropriate information based on the user request and provided data. If specific information is not provided, use realistic placeholder values that make sense for the document type.');

    return buffer.toString();
  }

  /// Generate PDF from a template with user data
  Future<File> generateTemplatePdf({
    required String templateKey,
    required String documentTitle,
    required Map<String, String> userData,
    String? subtitle,
  }) async {
    try {
      // Get and fill the template
      final filledContent = _legalLibrary.getFilledTemplate(templateKey, userData);

      if (filledContent.isEmpty) {
        throw Exception('Template "$templateKey" not found or is empty');
      }

      // Generate PDF
      return await PdfService.generatePdf(
        title: documentTitle,
        content: filledContent,
        subtitle: subtitle ?? 'Generated Legal Document',
      );
    } catch (e) {
      print('Error generating template PDF: $e');
      rethrow;
    }
  }

  /// Generate PDF with AI-filled template
  Future<File> generateAIDocumentPdf({
    required String templateKey,
    required String documentTitle,
    required String userRequest,
    Map<String, String>? providedData,
  }) async {
    try {
      print('🤖 Generating AI-filled document PDF...');

      // Generate the document content using AI
      final documentContent = await generateDocumentFromTemplate(
        templateKey: templateKey,
        userRequest: userRequest,
        providedData: providedData,
      );

      if (documentContent.startsWith('Error:')) {
        throw Exception(documentContent);
      }

      // Generate PDF from the AI-generated content
      return await PdfService.generatePdf(
        title: documentTitle,
        content: documentContent,
        subtitle: 'AI-Generated Legal Document',
      );
    } catch (e) {
      print('Error generating AI document PDF: $e');
      rethrow;
    }
  }

  /// Enhanced document generation that automatically selects template
  Future<String> generateLegalDocument(String userRequest) async {
    print('📄 Processing document generation request...');

    if (!_isInitialized) {
      await _initialize();
      if (!_isInitialized) {
        return 'Error: Unable to connect to AI service.';
      }
    }

    if (!_checkRateLimit()) {
      return 'Rate limit reached. Please wait before generating another document.';
    }

    try {
      // First, ask AI to identify what type of document is needed
      final identificationPrompt = '''Based on this user request, identify which legal document template would be most appropriate:

USER REQUEST: $userRequest

Available templates:
- nda: Non-Disclosure Agreement
- lease: Residential Lease Agreement
- will: Last Will & Testament
- employment: Employment Contract
- loan: Loan Agreement
- poa: Power of Attorney

Respond with ONLY the template key (nda, lease, will, employment, loan, or poa) and nothing else.
If none fit, respond with "custom".''';

      final identificationBody = {
        'model': ApiConfig.groqModel,
        'messages': [
          {
            'role': 'system',
            'content': 'You are a legal document classifier. Respond with only the template key or "custom".',
          },
          {
            'role': 'user',
            'content': identificationPrompt,
          }
        ],
        'temperature': 0.3,
        'max_tokens': 10,
      };

      final identificationResponse = await http.post(
        Uri.parse('${ApiConfig.groqBaseUrl}/chat/completions'),
        headers: {
          'Authorization': 'Bearer ${ApiConfig.groqApiKey}',
          'Content-Type': 'application/json',
        },
        body: json.encode(identificationBody),
      ).timeout(Duration(seconds: 10));

      if (identificationResponse.statusCode == 200) {
        final data = json.decode(identificationResponse.body);
        final templateKey = (data['choices']?[0]?['message']?['content'] as String?)
            ?.trim()
            .toLowerCase();

        print('🎯 Identified template: $templateKey');

        if (templateKey != null && templateKey != 'custom') {
          // Generate using identified template
          return await generateDocumentFromTemplate(
            templateKey: templateKey,
            userRequest: userRequest,
          );
        }
      }

      // Fall back to custom generation
      return await _generateCustomDocument(userRequest);
    } catch (e) {
      print('❌ Error in document generation: $e');
      return 'I apologize, but I encountered an error while generating your document. Please try again or rephrase your request.';
    }
  }

  /// Generate a custom document when no template matches
  Future<String> _generateCustomDocument(String userRequest) async {
    final customPrompt = '''Create a professional legal document based on this request:

$userRequest

Please create a complete, well-structured legal document with:
1. Appropriate title and header
2. Clear sections and numbering
3. Professional legal language
4. All necessary clauses
5. Signature lines
6. Proper formatting using markdown

Include a disclaimer at the end stating this is a template and should be reviewed by a licensed attorney.''';

    final requestBody = {
      'model': ApiConfig.groqModel,
      'messages': [
        {
          'role': 'system',
          'content': _getSystemPrompt(),
        },
        {
          'role': 'user',
          'content': customPrompt,
        }
      ],
      'temperature': 0.5,
      'max_tokens': 4000,
    };

    final response = await http.post(
      Uri.parse('${ApiConfig.groqBaseUrl}/chat/completions'),
      headers: {
        'Authorization': 'Bearer ${ApiConfig.groqApiKey}',
        'Content-Type': 'application/json',
      },
      body: json.encode(requestBody),
    ).timeout(Duration(seconds: 60));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['choices']?[0]?['message']?['content'] as String? ??
          'Error: Failed to generate custom document.';
    }

    return 'Error: Unable to generate custom document.';
  }

  /// Analyze document text with compression to avoid 413 errors
  Future<String> analyzeDocument(String documentText, String documentType) async {
    print('📄 Analyzing $documentType document...');

    if (!_isInitialized) {
      await _initialize();
      if (!_isInitialized) {
        return _getAnalysisErrorResponse();
      }
    }

    // Check rate limit
    if (!_checkRateLimit()) {
      return 'Rate limit reached. Please wait before analyzing another document.';
    }

    try {
      // Use DocumentAnalysisService to compress the document text
      final compressedText = await _documentService.analyzeDocument(documentText, documentType);

      // Get compression info for logging
      final compressionInfo = _documentService.getCompressionInfo(documentText);
      print('📊 Compression Info: $compressionInfo');

      final analysisPrompt = '''Analyze the following $documentType document and provide a comprehensive legal analysis.

DOCUMENT TYPE: $documentType
CONTENT LENGTH: ${compressedText.length} characters
${compressionInfo['needs_compression'] as bool ? 'NOTE: Document has been compressed for analysis. Key legal sections preserved.' : ''}

DOCUMENT CONTENT:
$compressedText

Please provide a structured analysis covering:

1. **DOCUMENT TYPE & OVERVIEW**
   - Identify the type of contract/document
   - Brief summary of the agreement's purpose

2. **KEY FINDINGS**
   - Most important terms and conditions identified
   - Critical clauses and provisions
   - Main obligations of each party

3. **RISK ASSESSMENT**
   - Overall risk level: Low / Medium / High / Critical
   - Specific risk factors identified
   - Areas requiring immediate attention

4. **RECOMMENDATIONS**
   - Key areas to review or negotiate
   - When legal counsel is strongly recommended
   - Actionable next steps

${compressionInfo['needs_compression'] as bool ? 'IMPORTANT: This analysis is based on compressed document content. For complete accuracy, full legal review of the original document is recommended.' : ''}

Use markdown formatting for better readability. Be specific and provide actionable advice. Use clear, accessible language while maintaining legal accuracy.

IMPORTANT: End with a clear disclaimer that this is AI-generated analysis for informational purposes only and does not constitute legal advice.''';

      final requestBody = {
        'model': ApiConfig.groqModel,
        'messages': [
          {
            'role': 'system',
            'content': 'You are an expert legal analyst specializing in contract review and risk assessment. Provide thorough, professional analysis. Be clear about limitations when analyzing compressed or partial documents.',
          },
          {
            'role': 'user',
            'content': analysisPrompt,
          }
        ],
        'temperature': 0.3,
        'max_tokens': 2000, // Reduced for compressed documents
        'top_p': 0.9,
        'stream': false,
      };

      print('📨 Sending compressed document to Groq for analysis...');
      print('📊 Compressed token estimate: ${_documentService.estimateTokenCount(compressedText)}');
      final startTime = DateTime.now();

      final response = await http.post(
        Uri.parse('${ApiConfig.groqBaseUrl}/chat/completions'),
        headers: {
          'Authorization': 'Bearer ${ApiConfig.groqApiKey}',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      ).timeout(
        Duration(seconds: 60),
        onTimeout: () {
          throw Exception('Analysis timed out');
        },
      );

      final duration = DateTime.now().difference(startTime);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final analysis = data['choices']?[0]?['message']?['content'] as String?;

        if (analysis == null || analysis.isEmpty) {
          return _getAnalysisErrorResponse();
        }

        print('✅ Analysis complete (${analysis.length} chars)');
        print('⚡ Analysis time: ${duration.inSeconds}s');
        print('📊 Tokens used: ${data['usage']?['total_tokens'] ?? 'unknown'}');

        // Add compression note if document was compressed
        final compressionNote = compressionInfo['needs_compression'] as bool
            ? '\n\n---\n\n*Note: Document analysis was performed on compressed content (${compressionInfo['compression_ratio']}% smaller, saved ${compressionInfo['token_savings']} tokens). Full legal review recommended for complete accuracy.*'
            : '';

        return analysis + compressionNote + '\n\n---\n\n**DISCLAIMER**: This is an AI-generated analysis for informational purposes only and does not constitute legal advice. For binding legal opinions, consult with a qualified attorney licensed in your jurisdiction.';
      } else if (response.statusCode == 413) {
        print('❌ Payload still too large after compression');
        return '''**Document Too Large**

Even after compression, this document is too large for analysis. 

**Please try:**
- A smaller document (under 10 pages)
- Splitting the document into sections
- Extracting only the key clauses you need reviewed
- Consulting with a legal professional for large/complex documents

*Document size: ${documentText.length} characters*
*Compression attempted: ${compressionInfo['compression_ratio']}% reduction*''';
      } else {
        print('❌ Analysis error: ${response.statusCode}');
        print('Response body: ${response.body}');
        return _getAnalysisErrorResponse();
      }
    } catch (e) {
      print('❌ Error analyzing document: $e');
      return _getAnalysisErrorResponse();
    }
  }

  /// Analyze document with detailed compression info for UI
  Future<Map<String, dynamic>> analyzeDocumentWithDetails(String documentText, String documentType) async {
    try {
      print('🔍 Analyzing document with detailed compression...');

      // Get compression info first
      final compressionInfo = _documentService.getCompressionInfo(documentText);
      final compressedText = await _documentService.analyzeDocument(documentText, documentType);

      // Perform the analysis
      final analysis = await analyzeDocument(documentText, documentType);

      return {
        'analysis': analysis,
        'compression_info': compressionInfo,
        'compressed_text': compressedText,
        'success': true,
      };
    } catch (e) {
      print('❌ Error in detailed document analysis: $e');
      return {
        'analysis': _getAnalysisErrorResponse(),
        'compression_info': {},
        'compressed_text': '',
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Generate PDF from document content
  Future<File> generateDocumentPdf({
    required String documentTitle,
    required String documentContent,
    String? subtitle,
  }) async {
    try {
      return await PdfService.generatePdf(
        title: documentTitle,
        content: documentContent,
        subtitle: subtitle,
      );
    } catch (e) {
      print('Error generating PDF: $e');
      rethrow;
    }
  }

  // Fallback response when API fails
  String _getFallbackResponse(String userMessage) {
    final lowerMessage = userMessage.toLowerCase();

    if (lowerMessage.contains('hello') || lowerMessage.contains('hi')) {
      return "Hello! I'm your AI legal assistant powered by Groq. I can help you with:\n\n"
          "• Drafting legal documents (NDAs, contracts, leases)\n"
          "• Reviewing contracts for risks\n"
          "• Explaining legal terms\n"
          "• Finding legal templates\n\n"
          "⚠️ Note: I'm currently experiencing connection issues. Please try again in a moment.\n\n"
          "How can I assist you today?";
    }

    return "I apologize, but I'm currently unable to process your request due to a connection issue. "
        "Please check your internet connection and try again.\n\n"
        "Error details: ${_lastError ?? 'Unknown error'}\n\n"
        "If the problem persists, please contact support.";
  }

  String _getAnalysisErrorResponse() {
    return '''**Analysis Error**

We encountered an issue while analyzing your document.

**Possible Causes:**
- Document is too large even after compression
- Rate limit reached (${ApiConfig.requestsPerMinute} requests per minute)
- Temporary API connectivity issue
- Document format not supported

**Solutions to Try:**
1. **Split Large Documents** - Try analyzing smaller sections
2. **Wait and Retry** - Rate limits reset every minute
3. **Check Document** - Ensure text is extractable and readable
4. **Try Shorter Document** - Start with documents under 10 pages

**For immediate assistance**, please consult with a qualified legal professional.

**Error Details:** ${_lastError ?? 'Unknown error'}
''';
  }

  // Check API connection status
  Future<bool> checkConnection() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.groqBaseUrl}/models'),
        headers: {
          'Authorization': 'Bearer ${ApiConfig.groqApiKey}',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Get API status
  Map<String, dynamic> getStatus() {
    return {
      'initialized': _isInitialized,
      'lastError': _lastError,
      'requestCount': _requestCount,
      'apiConfigured': ApiConfig.isConfigured(),
      'model': ApiConfig.groqModel,
      'rateLimit': '${_requestCount}/${ApiConfig.requestsPerMinute} per minute',
    };
  }

  // Get compression statistics
  Map<String, dynamic> getCompressionStats(String documentText) {
    return _documentService.getCompressionInfo(documentText);
  }
}