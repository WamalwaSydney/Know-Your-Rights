// lib/screens/legal/template_editor_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:legal_ai/core/constants.dart';
import 'package:legal_ai/core/services/chat_service.dart';
import 'package:legal_ai/core/services/pdf_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';

class TemplateEditorScreen extends StatefulWidget {
  final String templateKey;
  final String title;
  final String description;
  final String templateContent;
  final ChatService chatService;

  const TemplateEditorScreen({
    Key? key,
    required this.templateKey,
    required this.title,
    required this.description,
    required this.templateContent,
    required this.chatService,
  }) : super(key: key);

  @override
  State<TemplateEditorScreen> createState() => _TemplateEditorScreenState();
}

class _TemplateEditorScreenState extends State<TemplateEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _requestController = TextEditingController();
  bool _isGenerating = false;
  String? _generatedContent;
  File? _generatedPdf;
  String _currentStep = '';
  String? _saveLocation;

  @override
  void initState() {
    super.initState();
    _loadSaveLocation();
  }

  @override
  void dispose() {
    _requestController.dispose();
    super.dispose();
  }

  Future<void> _loadSaveLocation() async {
    final location = await PdfService.getStorageDirectoryPath();
    setState(() => _saveLocation = location);
  }

  List<String> _extractPlaceholders() {
    final regex = RegExp(r'\[([^\]]+)\]');
    final matches = regex.allMatches(widget.templateContent);
    final placeholders = matches.map((m) => m.group(1)!).toSet().toList();
    return placeholders;
  }

  Future<void> _generateDocument() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isGenerating = true;
      _generatedContent = null;
      _generatedPdf = null;
      _currentStep = 'Preparing your request...';
    });

    try {
      setState(() => _currentStep = 'Analyzing template requirements...');
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() => _currentStep = 'Generating document with AI...');

      final content = await widget.chatService.generateDocumentFromTemplate(
        templateKey: widget.templateKey,
        userRequest: _requestController.text,
      );

      if (content.startsWith('Error:')) {
        throw Exception(content);
      }

      setState(() {
        _generatedContent = content;
        _currentStep = 'Document generated successfully!';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Document generated successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      setState(() {
        _isGenerating = false;
        _currentStep = '';
      });
    }
  }

  Future<void> _generatePdf() async {
    if (_generatedContent == null) return;

    setState(() {
      _isGenerating = true;
      _currentStep = 'Creating PDF document...';
    });

    try {
      final pdf = await widget.chatService.generateDocumentPdf(
        documentTitle: widget.title,
        documentContent: _generatedContent!,
        subtitle: 'Generated on ${DateTime.now().toString().split(' ')[0]}',
      );

      setState(() {
        _generatedPdf = pdf;
        _currentStep = 'PDF created successfully!';
      });

      if (mounted) {
        _showPdfSavedDialog(pdf);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error generating PDF: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      setState(() {
        _isGenerating = false;
        _currentStep = '';
      });
    }
  }

  void _showPdfSavedDialog(File pdf) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Text('PDF Saved Successfully!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your document has been saved to:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.folder, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      pdf.path,
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: pdf.path));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Path copied to clipboard'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    tooltip: 'Copy path',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'File name: ${pdf.path.split('/').last}',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            FutureBuilder<FileStat>(
              future: pdf.stat(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final sizeKB = snapshot.data!.size / 1024;
                  return Text(
                    'Size: ${sizeKB.toStringAsFixed(2)} KB',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _openPdf(pdf);
            },
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _sharePdf();
            },
            icon: const Icon(Icons.share),
            label: const Text('Share'),
          ),
        ],
      ),
    );
  }

  Future<void> _openPdf(File pdf) async {
    try {
      final result = await OpenFile.open(pdf.path);

      if (result.type != ResultType.done) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open PDF: ${result.message}'),
              action: SnackBarAction(
                label: 'Share',
                onPressed: _sharePdf,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening PDF: $e'),
            action: SnackBarAction(
              label: 'Share',
              onPressed: _sharePdf,
            ),
          ),
        );
      }
    }
  }

  Future<void> _sharePdf() async {
    if (_generatedPdf == null) return;

    try {
      await Share.shareXFiles(
        [XFile(_generatedPdf!.path)],
        subject: widget.title,
        text: 'Legal document generated by Know Your Rights',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing PDF: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _copyToClipboard() {
    if (_generatedContent == null) return;

    Clipboard.setData(ClipboardData(text: _generatedContent!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Content copied to clipboard'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final placeholders = _extractPlaceholders();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: kPrimaryColor,
        actions: [
          if (_generatedContent != null && !_isGenerating) ...[
            IconButton(
              icon: const Icon(Icons.content_copy),
              tooltip: 'Copy to clipboard',
              onPressed: _copyToClipboard,
            ),
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              tooltip: 'Generate PDF',
              onPressed: _generatePdf,
            ),
          ],
          if (_generatedPdf != null) ...[
            IconButton(
              icon: const Icon(Icons.open_in_new),
              tooltip: 'Open PDF',
              onPressed: () => _openPdf(_generatedPdf!),
            ),
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: 'Share PDF',
              onPressed: _sharePdf,
            ),
          ],
        ],
      ),
      body: _isGenerating
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              _currentStep,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'This may take a few moments. Please don\'t close this screen.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Save location box
              if (_saveLocation != null)
                Card(
                  color: Colors.blue[50],
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(Icons.folder_outlined,
                            color: Colors.blue[700]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PDFs will be saved to:',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue[900],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _saveLocation!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.blue[800],
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.copy,
                              size: 18, color: Colors.blue[700]),
                          onPressed: () {
                            Clipboard.setData(
                                ClipboardData(text: _saveLocation!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Path copied to clipboard'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          tooltip: 'Copy path',
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              // Description card
              Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          Text(
                            'About This Template',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.description,
                        style: const TextStyle(fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Placeholders section
              if (placeholders.isNotEmpty) ...[
                Card(
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.edit_note,
                                color: Colors.orange[700]),
                            const SizedBox(width: 8),
                            Text(
                              'Information Needed',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Please provide the following information in your description:',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: placeholders.map((placeholder) {
                            return Chip(
                              avatar: CircleAvatar(
                                backgroundColor: Colors.blue[700],
                                child: const Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                              label: Text(
                                placeholder,
                                style: const TextStyle(fontSize: 13),
                              ),
                              backgroundColor:
                              Colors.blue.withOpacity(0.1),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Request Input Section
              Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.description,
                              color: Colors.green[700]),
                          const SizedBox(width: 8),
                          Text(
                            'Describe Your Requirements',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Provide detailed information about your document. The more details you provide, the better the AI can fill in the template.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 12),

                      /// ************************************
                      /// USER INPUT TEXT -> BLACK COLOR
                      /// ************************************
                      TextFormField(
                        controller: _requestController,
                        maxLines: 8,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: _getHintForTemplate(),
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.grey[50],
                          helperText:
                          'Include all relevant details such as names, dates, amounts, and specific terms',
                          helperMaxLines: 2,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please describe your requirements';
                          }
                          if (value.trim().length < 20) {
                            return 'Please provide more details (at least 20 characters)';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              ElevatedButton.icon(
                onPressed: _isGenerating ? null : _generateDocument,
                icon: const Icon(Icons.auto_awesome, size: 24),
                label: const Text(
                  'Generate Document with AI',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              if (_generatedContent != null) ...[
                const SizedBox(height: 24),
                Card(
                  elevation: 4,
                  color: Colors.green[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green[700],
                              size: 28,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Generated Document',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border:
                            Border.all(color: Colors.green[200]!),
                          ),
                          constraints: const BoxConstraints(
                            maxHeight: 400,
                          ),
                          child: SingleChildScrollView(
                            child: SelectableText(
                              _generatedContent!,

                              /// ************************************
                              /// GENERATED DOCUMENT TEXT -> BLACK COLOR
                              /// ************************************
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 13,
                                height: 1.5,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _copyToClipboard,
                                icon: const Icon(Icons.content_copy),
                                label: const Text('Copy'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.all(12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isGenerating
                                    ? null
                                    : _generatePdf,
                                icon: const Icon(Icons.picture_as_pdf),
                                label: const Text('Save as PDF'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red[700],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.all(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),
              Card(
                color: Colors.orange.withOpacity(0.1),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange[700],
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Important Disclaimer',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[900],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'This is an AI-generated template for informational purposes only. '
                                  'Always consult with a licensed attorney before using any legal document. '
                                  'The generated document may not be suitable for your specific situation or jurisdiction.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[800],
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getHintForTemplate() {
    switch (widget.templateKey) {
      case 'nda':
        return 'Example: I need an NDA between myself (John Doe, ABC Corp, 123 Main St, City) and Jane Smith (XYZ Ltd, 456 Oak Ave, Town)...';
      case 'lease':
        return 'Example: I need a lease agreement for my property at 123 Main St...';
      case 'will':
        return 'Example: I, John Doe of 123 Main St, want to leave my estate as follows...';
      case 'employment':
        return 'Example: Employment contract for Software Developer position at Tech Corp...';
      case 'loan':
        return 'Example: Loan of \$10,000 from John Doe to Jane Smith...';
      case 'poa':
        return 'Example: I, John Doe, authorize Jane Doe to manage my legal and financial affairs...';
      default:
        return 'Describe what you need in this document. Include names, addresses, dates, amounts, and any specific terms or conditions.';
    }
  }
}
