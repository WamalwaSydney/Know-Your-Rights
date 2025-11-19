import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:legal_ai/core/models/document.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DocumentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? 'mock_user';

  // Get all documents for the current user
  Stream<List<Document>> getDocuments() {
    return _db
        .collection('users')
        .doc(_userId)
        .collection('documents')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Document.fromFirestore(doc)).toList());
  }

  // Save a new or existing document
  Future<void> saveDocument(Document document) async {
    final data = document.toFirestore();
    if (document.id.isEmpty) {
      // New document
      await _db
          .collection('users')
          .doc(_userId)
          .collection('documents')
          .add(data);
    } else {
      // Existing document
      await _db
          .collection('users')
          .doc(_userId)
          .collection('documents')
          .doc(document.id)
          .update(data);
    }
  }

  // Delete a document
  Future<void> deleteDocument(String documentId) async {
    await _db
        .collection('users')
        .doc(_userId)
        .collection('documents')
        .doc(documentId)
        .delete();
  }

  // Download a document as a text file
  Future<String> downloadDocument(Document document) async {
    // Get the directory for saving files (e.g., Downloads on Android/iOS)
    final directory = await getApplicationDocumentsDirectory();
    final fileName = '${document.title.replaceAll(RegExp(r'[^\w\s]+'), '')}_${document.id.substring(0, 4)}.txt';
    final filePath = '${directory.path}/$fileName';

    final file = File(filePath);
    final content = 'Title: ${document.title}\n\n'
        'Last Updated: ${document.updatedAt.toIso8601String()}\n\n'
        '---\n\n'
        '${document.content}';

    await file.writeAsString(content);
    return filePath;
  }
}
