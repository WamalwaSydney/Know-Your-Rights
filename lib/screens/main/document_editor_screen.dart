import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:legal_ai/core/models/document.dart';
import 'package:legal_ai/core/services/document_service.dart';
import 'package:legal_ai/core/constants.dart';

class DocumentEditorScreen extends StatefulWidget {
  final Document? document;

  const DocumentEditorScreen({Key? key, this.document}) : super(key: key);

  @override
  State<DocumentEditorScreen> createState() => _DocumentEditorScreenState();
}

class _DocumentEditorScreenState extends State<DocumentEditorScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final DocumentService _documentService = DocumentService();
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? 'mock_user';

  @override
  void initState() {
    super.initState();
    if (widget.document != null) {
      _titleController.text = widget.document!.title;
      _contentController.text = widget.document!.content;
    }
  }

  Future<void> _saveDocument() async {
    final now = DateTime.now();
    final documentToSave = Document(
      id: widget.document?.id ?? '',
      userId: _userId,
      title: _titleController.text.trim().isEmpty ? 'Untitled Document' : _titleController.text.trim(),
      content: _contentController.text,
      createdAt: widget.document?.createdAt ?? now,
      updatedAt: now,
    );

    try {
      await _documentService.saveDocument(documentToSave);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${documentToSave.title} saved successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving document: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.document == null ? 'New Document' : 'Edit Document'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveDocument,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Document Title',
                labelStyle: TextStyle(color: kLightTextColor.withOpacity(0.7)),
              ),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: _contentController,
                keyboardType: TextInputType.multiline,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: const TextStyle(color: kLightTextColor),
                decoration: InputDecoration(
                  labelText: 'Document Content',
                  hintText: 'Start drafting your legal document here...',
                  labelStyle: TextStyle(color: kLightTextColor.withOpacity(0.7)),
                  hintStyle: TextStyle(color: kLightTextColor.withOpacity(0.5)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
