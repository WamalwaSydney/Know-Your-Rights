// lib/screens/legal/saved_documents_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:legal_ai/core/constants.dart';
import 'package:legal_ai/core/services/pdf_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';

class SavedDocumentsScreen extends StatefulWidget {
  const SavedDocumentsScreen({Key? key}) : super(key: key);

  @override
  State<SavedDocumentsScreen> createState() => _SavedDocumentsScreenState();
}

class _SavedDocumentsScreenState extends State<SavedDocumentsScreen> {
  List<File> _documents = [];
  bool _isLoading = true;
  String? _saveLocation;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
    _loadSaveLocation();
  }

  Future<void> _loadSaveLocation() async {
    final location = await PdfService.getStorageDirectoryPath();
    setState(() => _saveLocation = location);
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoading = true);

    try {
      final docs = await PdfService.getSavedPdfs();
      setState(() {
        _documents = docs;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading documents: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading documents: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openDocument(File file) async {
    try {
      final result = await OpenFile.open(file.path);

      if (result.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open PDF: ${result.message}'),
            action: SnackBarAction(
              label: 'Share',
              onPressed: () => _shareDocument(file),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening PDF: $e'),
          ),
        );
      }
    }
  }

  Future<void> _shareDocument(File file) async {
    try {
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: file.path.split('/').last,
        text: 'Legal document from Know Your Rights',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteDocument(File file) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document?'),
        content: Text(
          'Are you sure you want to delete "${file.path.split('/').last}"?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await PdfService.deletePdf(file);
      if (success) {
        await _loadDocuments();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Document deleted'),
                ],
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    }
  }

  void _showDocumentDetails(File file) async {
    final stat = await file.stat();
    final sizeKB = stat.size / 1024;
    final sizeMB = sizeKB / 1024;
    final sizeStr = sizeMB > 1
        ? '${sizeMB.toStringAsFixed(2)} MB'
        : '${sizeKB.toStringAsFixed(2)} KB';

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Document Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('File name:', file.path.split('/').last),
              const SizedBox(height: 12),
              _buildDetailRow('Size:', sizeStr),
              const SizedBox(height: 12),
              _buildDetailRow(
                'Created:',
                _formatDate(stat.changed),
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                'Modified:',
                _formatDate(stat.modified),
              ),
              const SizedBox(height: 16),
              const Text(
                'Full path:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        file.path,
                        style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 18),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: file.path));
                        Navigator.pop(context);
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
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Documents'),
        backgroundColor: kPrimaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDocuments,
            tooltip: 'Refresh',
          ),
          if (_saveLocation != null)
            IconButton(
              icon: const Icon(Icons.folder_open),
              onPressed: () => _showSaveLocationDialog(),
              tooltip: 'Save location',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _documents.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
        onRefresh: _loadDocuments,
        child: ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: _documents.length,
          itemBuilder: (context, index) {
            final doc = _documents[index];
            return _buildDocumentCard(doc);
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'No Saved Documents',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Documents you generate will appear here',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.add),
              label: const Text('Create Document'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentCard(File doc) {
    final fileName = doc.path.split('/').last;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.red[100],
          child: Icon(Icons.picture_as_pdf, color: Colors.red[700]),
        ),
        title: Text(
          fileName,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: FutureBuilder<FileStat>(
          future: doc.stat(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final sizeKB = snapshot.data!.size / 1024;
              final date = _formatDate(snapshot.data!.modified);
              return Text(
                '${sizeKB.toStringAsFixed(2)} KB • $date',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              );
            }
            return const Text('Loading...');
          },
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'open':
                _openDocument(doc);
                break;
              case 'share':
                _shareDocument(doc);
                break;
              case 'details':
                _showDocumentDetails(doc);
                break;
              case 'delete':
                _deleteDocument(doc);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'open',
              child: Row(
                children: [
                  Icon(Icons.open_in_new, size: 20),
                  SizedBox(width: 12),
                  Text('Open'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  Icon(Icons.share, size: 20),
                  SizedBox(width: 12),
                  Text('Share'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'details',
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20),
                  SizedBox(width: 12),
                  Text('Details'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _openDocument(doc),
      ),
    );
  }

  void _showSaveLocationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.folder, color: Colors.blue),
            SizedBox(width: 12),
            Text('Save Location'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'All PDFs are saved to:',
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
                  Expanded(
                    child: Text(
                      _saveLocation ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    onPressed: () {
                      if (_saveLocation != null) {
                        Clipboard.setData(ClipboardData(text: _saveLocation!));
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Path copied to clipboard'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    tooltip: 'Copy path',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              Platform.isAndroid
                  ? 'On Android, you can access these files using any file manager app. Look for the "Documents/KnowYourRights" folder.'
                  : 'On iOS, you can access these files through the Files app under "On My iPhone/iPad".',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}