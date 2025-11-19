import 'package:flutter/material.dart';
import 'package:legal_ai/core/models/document.dart';
import 'package:legal_ai/core/services/document_service.dart';
import 'package:legal_ai/screens/main/document_editor_screen.dart';
import 'package:intl/intl.dart';
import 'package:legal_ai/core/constants.dart';

class DocumentListScreen extends StatelessWidget {
  void _downloadDocument(BuildContext context, Document doc, DocumentService service) async {
    try {
      final filePath = await service.downloadDocument(doc);
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Downloaded "${doc.title}" to $filePath')),
      );
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to download document: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final DocumentService documentService = DocumentService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Documents'),
      ),
      body: StreamBuilder<List<Document>>(
        stream: documentService.getDocuments(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No documents drafted yet.'));
          }

          final documents = snapshot.data!;
          return ListView.builder(
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final doc = documents[index];
              return Card(
                color: kDarkCardColor,
                margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: ListTile(
                  leading: const Icon(Icons.description, color: kPrimaryColor),
                  title: Text(doc.title),
                subtitle: Text('Last updated: ${DateFormat.yMMMd().add_jm().format(doc.updatedAt)}'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DocumentEditorScreen(document: doc),
                    ),
                  );
                },
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.download, color: Colors.green),
                      onPressed: () => _downloadDocument(context, doc, documentService),
                    ),
                    IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _confirmDelete(context, doc, documentService),
                    ),
                  ],
                ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: kPrimaryColor,
        foregroundColor: kDarkTextColor,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const DocumentEditorScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Document doc, DocumentService service) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to delete "${doc.title}"?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                await service.deleteDocument(doc.id);
                // ignore: use_build_context_synchronously
                Navigator.of(context).pop();
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${doc.title} deleted.')),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
