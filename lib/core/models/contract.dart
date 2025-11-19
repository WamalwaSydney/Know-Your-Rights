import 'package:cloud_firestore/cloud_firestore.dart';

class Contract {
  final String id;
  final String userId;
  final String fileName;
  final String fileUrl;
  final String analysisResult;
  final DateTime uploadedAt;

  Contract({
    required this.id,
    required this.userId,
    required this.fileName,
    required this.fileUrl,
    required this.analysisResult,
    required this.uploadedAt,
  });

  factory Contract.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Contract(
      id: doc.id,
      userId: data['userId'] ?? '',
      fileName: data['fileName'] ?? 'Unknown Contract',
      fileUrl: data['fileUrl'] ?? '',
      analysisResult: data['analysisResult'] ?? 'Analysis Pending',
      uploadedAt: (data['uploadedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'fileName': fileName,
      'fileUrl': fileUrl,
      'analysisResult': analysisResult,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
    };
  }
}
