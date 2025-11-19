import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:legal_ai/core/models/chat_message.dart';
import 'package:legal_ai/core/services/chat_service.dart';
import 'package:legal_ai/core/services/pdf_service.dart';
import 'package:legal_ai/core/services/document_analysis_service.dart';
import 'package:legal_ai/widgets/chat_bubble.dart';
import 'package:uuid/uuid.dart';
import 'package:legal_ai/core/constants.dart';
import 'package:file_picker/file_picker.dart';

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({Key? key}) : super(key: key);

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final ChatService _chatService = ChatService();
  final DocumentAnalysisService _documentService = DocumentAnalysisService();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;
  bool _isAnalyzingDocument = false;
  bool _showCompressionInfo = false;
  Map<String, dynamic> _compressionInfo = {};

  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  void _sendMessage() async {
    if (_controller.text.trim().isEmpty || _isSending || _userId == null) return;

    final String userText = _controller.text.trim();
    _controller.clear();

    setState(() => _isSending = true);

    try {
      // 1. Save user message to Firestore
      final userMessage = ChatMessage(
        id: const Uuid().v4(),
        userId: _userId!,
        text: userText,
        isUser: true,
        timestamp: DateTime.now(),
      );
      await _chatService.addMessage(userMessage);

      // 2. Get AI response
      final aiResponseText = await _chatService.getAIResponse(userText);

      // 3. Save AI response to Firestore
      final aiMessage = ChatMessage(
        id: const Uuid().v4(),
        userId: _userId!,
        text: aiResponseText,
        isUser: false,
        timestamp: DateTime.now().add(const Duration(milliseconds: 50)),
      );
      await _chatService.addMessage(aiMessage);

      setState(() => _isSending = false);
      _scrollToBottom();
    } catch (e) {
      print('Error sending message: $e');
      setState(() => _isSending = false);

      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickAndAnalyzeDocument() async {
    if (_isAnalyzingDocument) return;

    try {
      // Pick document
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        // User cancelled
        return;
      }

      final file = result.files.first;
      final fileName = file.name;
      final fileExtension = file.extension?.toLowerCase();
      final fileSize = file.size;

      // Validate file type
      if (fileExtension != 'pdf' && fileExtension != 'doc' && fileExtension != 'docx') {
        _showErrorSnackBar('Please select a PDF or Word document');
        return;
      }

      setState(() {
        _isAnalyzingDocument = true;
        _showCompressionInfo = false;
        _compressionInfo = {};
      });

      // Show analyzing message with compression info
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Analyzing $fileName...'),
                    const SizedBox(height: 4),
                    Text(
                      'File size: ${_formatFileSize(fileSize)}',
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 60),
          backgroundColor: kPrimaryColor,
        ),
      );

      // Save user's attachment message
      final userMessage = ChatMessage(
        id: const Uuid().v4(),
        userId: _userId!,
        text: '📎 Attached document: $fileName\n\nPlease analyze this document and provide a summary of the document only.',
        isUser: true,
        timestamp: DateTime.now(),
      );
      await _chatService.addMessage(userMessage);

      // Extract text
      String? extractedText;

      if (fileExtension == 'pdf') {
        extractedText = await _documentService.extractTextFromPdf(file.path!);
      } else if (fileExtension == 'doc' || fileExtension == 'docx') {
        extractedText = await _documentService.extractTextFromWord(file.path!);
      }

      if (extractedText == null || extractedText.trim().isEmpty) {
        throw Exception('Could not extract text from document. The document may be empty or in an unsupported format.');
      }

      // Check compression info
      final compressionInfo = _documentService.getCompressionInfo(extractedText);
      print('📊 Compression Info: $compressionInfo');

      setState(() {
        _compressionInfo = compressionInfo;
        _showCompressionInfo = compressionInfo['needs_compression'] as bool;
      });

      // Show compression info snackbar if needed
      if (_showCompressionInfo && mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.compress, size: 20, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Large document detected'),
                      Text(
                        'Compressed by ${compressionInfo['compression_ratio']}% to save tokens',
                        style: const TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange[800],
            duration: const Duration(seconds: 4),
          ),
        );
      }

      // Get AI summary
      final summary = await _chatService.analyzeDocument(
        extractedText,
        'Document: $fileName',
      );

      // Save AI response with compression note if applicable
      final compressionNote = _showCompressionInfo
          ? '\n\n_📦 Document was compressed for analysis (${_compressionInfo['compression_ratio']}% smaller, saved ${_compressionInfo['token_savings']} tokens)_'
          : '';

      final aiMessage = ChatMessage(
        id: const Uuid().v4(),
        userId: _userId!,
        text: '📄 **Document Analysis: $fileName**$compressionNote\n\n$summary',
        isUser: false,
        timestamp: DateTime.now().add(const Duration(milliseconds: 50)),
      );
      await _chatService.addMessage(aiMessage);

      // Hide analyzing snackbar and show success
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text(_showCompressionInfo
                    ? 'Document analyzed (compressed)'
                    : 'Document analyzed successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      _scrollToBottom();
    } catch (e) {
      print('Error analyzing document: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        _showErrorSnackBar('Failed to analyze document: ${e.toString()}');
      }

      // Send error message to chat
      final errorMessage = ChatMessage(
        id: const Uuid().v4(),
        userId: _userId!,
        text: '❌ **Error**: Could not analyze the document. ${e.toString()}',
        isUser: false,
        timestamp: DateTime.now(),
      );
      await _chatService.addMessage(errorMessage);
    } finally {
      setState(() => _isAnalyzingDocument = false);
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.minScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showMessageOptions(ChatMessage message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: kDarkCardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Copy option
            ListTile(
              leading: const Icon(Icons.copy, color: kPrimaryColor),
              title: const Text('Copy Message', style: TextStyle(color: kLightTextColor)),
              onTap: () {
                Clipboard.setData(ClipboardData(text: message.text));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Message copied to clipboard')),
                );
              },
            ),

            // Export to PDF (only for AI messages)
            if (!message.isUser) ...[
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: kPrimaryColor),
                title: const Text('Export to PDF', style: TextStyle(color: kLightTextColor)),
                onTap: () {
                  Navigator.pop(context);
                  _showPdfOptions(message);
                },
              ),
            ],

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showPdfOptions(ChatMessage message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: kDarkCardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                'Export Document to PDF',
                style: TextStyle(
                  color: kLightTextColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const Divider(color: Colors.grey),

            // Preview PDF
            ListTile(
              leading: const Icon(Icons.visibility, color: kPrimaryColor),
              title: const Text('Preview PDF', style: TextStyle(color: kLightTextColor)),
              subtitle: const Text('View before saving', style: TextStyle(color: Colors.grey)),
              onTap: () async {
                Navigator.pop(context);
                await _previewPdf(message);
              },
            ),

            // Share PDF
            ListTile(
              leading: const Icon(Icons.share, color: kPrimaryColor),
              title: const Text('Share PDF', style: TextStyle(color: kLightTextColor)),
              subtitle: const Text('Share via other apps', style: TextStyle(color: Colors.grey)),
              onTap: () async {
                Navigator.pop(context);
                await _sharePdf(message);
              },
            ),

            // Save to Device
            ListTile(
              leading: const Icon(Icons.download, color: kPrimaryColor),
              title: const Text('Save to Device', style: TextStyle(color: kLightTextColor)),
              subtitle: const Text('Save to Documents folder', style: TextStyle(color: Colors.grey)),
              onTap: () async {
                Navigator.pop(context);
                await _savePdf(message);
              },
            ),

            // Print PDF
            ListTile(
              leading: const Icon(Icons.print, color: kPrimaryColor),
              title: const Text('Print PDF', style: TextStyle(color: kLightTextColor)),
              subtitle: const Text('Send to printer', style: TextStyle(color: Colors.grey)),
              onTap: () async {
                Navigator.pop(context);
                await _printPdf(message);
              },
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _previewPdf(ChatMessage message) async {
    try {
      _showLoadingDialog('Generating PDF preview...');

      await PdfService.previewPdf(
        title: 'Legal Document',
        content: message.text,
        subtitle: 'Generated on ${_formatDate(message.timestamp)}',
      );

      if (mounted) Navigator.pop(context); // Close loading dialog
    } catch (e) {
      if (mounted) Navigator.pop(context); // Close loading dialog
      _showErrorSnackBar('Failed to preview PDF: $e');
    }
  }

  Future<void> _sharePdf(ChatMessage message) async {
    try {
      _showLoadingDialog('Generating PDF...');

      final pdfFile = await PdfService.generatePdf(
        title: 'Legal Document',
        content: message.text,
        subtitle: 'Generated on ${_formatDate(message.timestamp)}',
      );

      if (mounted) Navigator.pop(context); // Close loading dialog

      await PdfService.sharePdf(pdfFile);
    } catch (e) {
      if (mounted) Navigator.pop(context); // Close loading dialog
      _showErrorSnackBar('Failed to share PDF: $e');
    }
  }

  Future<void> _savePdf(ChatMessage message) async {
    try {
      _showLoadingDialog('Saving PDF...');

      final path = await PdfService.savePdfToDownloads(
        title: 'Legal Document',
        content: message.text,
        subtitle: 'Generated on ${_formatDate(message.timestamp)}',
      );

      if (mounted) Navigator.pop(context); // Close loading dialog

      if (path != null) {
        _showSuccessSnackBar('PDF saved successfully!\n$path');
      } else {
        _showErrorSnackBar('Failed to save PDF');
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Close loading dialog
      _showErrorSnackBar('Failed to save PDF: $e');
    }
  }

  Future<void> _printPdf(ChatMessage message) async {
    try {
      _showLoadingDialog('Preparing document for printing...');

      await PdfService.printPdf(
        title: 'Legal Document',
        content: message.text,
        subtitle: 'Generated on ${_formatDate(message.timestamp)}',
      );

      if (mounted) Navigator.pop(context); // Close loading dialog
    } catch (e) {
      if (mounted) Navigator.pop(context); // Close loading dialog
      _showErrorSnackBar('Failed to print PDF: $e');
    }
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: kDarkCardColor,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: kPrimaryColor),
            const SizedBox(height: 16),
            Text(message, style: const TextStyle(color: kLightTextColor)),
          ],
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _clearChatHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kDarkCardColor,
        title: const Text('Clear Chat History', style: TextStyle(color: kLightTextColor)),
        content: const Text(
          'Are you sure you want to delete all messages? This action cannot be undone.',
          style: TextStyle(color: kLightTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _chatService.clearHistory();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Chat history cleared')),
          );
        }
      } catch (e) {
        if (mounted) {
          _showErrorSnackBar('Failed to clear history: $e');
        }
      }
    }
  }

  void _showCompressionDetails() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kDarkCardColor,
        title: const Text('Document Compression', style: TextStyle(color: kLightTextColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Large documents are automatically compressed to save tokens and avoid rate limits:',
              style: TextStyle(color: kLightTextColor),
            ),
            const SizedBox(height: 16),
            _buildCompressionDetail('Original Size', '${_compressionInfo['original_length']} characters'),
            _buildCompressionDetail('Compressed Size', '${_compressionInfo['compressed_length']} characters'),
            _buildCompressionDetail('Compression Ratio', '${_compressionInfo['compression_ratio']}%'),
            _buildCompressionDetail('Token Savings', '${_compressionInfo['token_savings']} tokens'),
            const SizedBox(height: 16),
            const Text(
              'Compression removes extra whitespace and common legal boilerplate while preserving key legal sections.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildCompressionDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(color: kLightTextColor, fontWeight: FontWeight.bold)),
          Text(value, style: const TextStyle(color: kLightTextColor)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text(
            'Error: User not authenticated. Please sign out and sign in again.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Legal Assistant'),
        backgroundColor: kDarkCardColor,
        actions: [
          // Compression info button (only show when we have compression data)
          if (_showCompressionInfo && _compressionInfo.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.compress),
              tooltip: 'Show Compression Details',
              onPressed: _showCompressionDetails,
            ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Clear Chat History',
            onPressed: _clearChatHistory,
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          // Compression info banner
          if (_showCompressionInfo && _compressionInfo.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.orange[800]?.withOpacity(0.2),
              child: Row(
                children: [
                  Icon(Icons.compress, size: 16, color: Colors.orange[300]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Document compressed to save ${_compressionInfo['token_savings']} tokens',
                      style: TextStyle(color: Colors.orange[300], fontSize: 12),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.info_outline, size: 16, color: Colors.orange[300]),
                    onPressed: _showCompressionDetails,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 24),
                  ),
                ],
              ),
            ),
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _chatService.getMessages(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(
                            'Error loading messages: ${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: kLightTextColor),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {}); // Trigger rebuild to retry
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryColor,
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.chat_bubble_outline, size: 64, color: kPrimaryColor),
                          SizedBox(height: 16),
                          Text(
                            'Start a conversation with your legal assistant.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: kLightTextColor),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Try asking "Hello" or "Help me draft an NDA"',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Or attach a document for analysis',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // The messages are ordered descending by timestamp from Firestore
                final messages = snapshot.data!;

                // Auto-scroll when new messages arrive
                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true, // Display latest message at the bottom
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  itemCount: messages.length + (_isSending || _isAnalyzingDocument ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Show typing indicator at the top (index 0) when sending or analyzing
                    if ((_isSending || _isAnalyzingDocument) && index == 0) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: kAIChatBubbleColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(kPrimaryColor),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _isAnalyzingDocument
                                      ? 'Analyzing document...'
                                      : 'AI is typing...',
                                  style: const TextStyle(color: kAIChatTextColor),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    final messageIndex = (_isSending || _isAnalyzingDocument) ? index - 1 : index;
                    final message = messages[messageIndex];

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: GestureDetector(
                        onLongPress: () => _showMessageOptions(message),
                        child: ChatBubble(
                          message: message.text,
                          isUser: message.isUser,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          _buildMessageComposer(),
        ],
      ),
    );
  }

  Widget _buildMessageComposer() {
    return Container(
      padding: const EdgeInsets.only(left: 16.0, right: 8.0, bottom: 8.0, top: 8.0),
      decoration: BoxDecoration(
        color: kDarkCardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: <Widget>[
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                decoration: BoxDecoration(
                  color: kDarkBackgroundColor,
                  borderRadius: BorderRadius.circular(kLargeBorderRadius),
                ),
                child: TextField(
                  controller: _controller,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(color: kLightTextColor),
                  decoration: InputDecoration(
                    hintText: 'Describe your legal document needs...',
                    hintStyle: TextStyle(color: kLightTextColor.withOpacity(0.6)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10.0),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  enabled: !_isSending && !_isAnalyzingDocument,
                ),
              ),
            ),
            // Attachment Button
            IconButton(
              icon: Icon(
                Icons.attach_file,
                color: _isAnalyzingDocument ? Colors.grey : kPrimaryColor,
              ),
              tooltip: 'Attach Document (PDF/Word)',
              onPressed: _isAnalyzingDocument ? null : _pickAndAnalyzeDocument,
            ),
            // Send Button
            IconButton(
              icon: Icon(
                Icons.send,
                color: (_isSending || _isAnalyzingDocument) ? Colors.grey : kPrimaryColor,
              ),
              tooltip: 'Send Message',
              onPressed: (_isSending || _isAnalyzingDocument) ? null : _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}