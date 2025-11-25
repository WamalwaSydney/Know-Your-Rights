import 'dart:io';
import 'package:flutter/material.dart';
import 'package:legal_ai/core/constants.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:legal_ai/core/models/contract.dart';
import 'package:legal_ai/core/services/contract_service.dart';
import 'package:legal_ai/core/services/storage_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ContractReviewScreen extends StatefulWidget {
  const ContractReviewScreen({Key? key}) : super(key: key);

  @override
  State<ContractReviewScreen> createState() => _ContractReviewScreenState();
}

class _ContractReviewScreenState extends State<ContractReviewScreen> {
  final ContractService _contractService = ContractService();
  final StorageService _storageService = StorageService();
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? 'mock_user';
  bool _isUploading = false;
  String _uploadStatus = '';

  Future<void> _pickAndUploadFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'jpg', 'jpeg', 'png'],
    );

    if (result != null) {
      PlatformFile file = result.files.first;
      if (file.path == null) return;

      setState(() {
        _isUploading = true;
        _uploadStatus = 'Uploading ${file.name}...';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Uploading ${file.name} for analysis...'),
          duration: const Duration(seconds: 2),
        ),
      );

      try {
        // 1. Save file to local storage
        setState(() => _uploadStatus = 'Saving file locally...');
        final localPath = await _storageService.uploadFile(file.path!, file.name);

        // 2. AI analysis using Gemini (this may take 10-30 seconds)
        setState(() => _uploadStatus = 'Analyzing contract with AI...');
        final analysisResult = await _contractService.analyzeContract(localPath);

        // 3. Save contract record to Firestore
        setState(() => _uploadStatus = 'Saving analysis...');
        final newContract = Contract(
          id: '', // Firestore will assign an ID
          userId: _userId,
          fileName: file.name,
          fileUrl: localPath, // Now storing local path
          analysisResult: analysisResult,
          uploadedAt: DateTime.now(),
        );
        await _contractService.addContract(newContract);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Contract analysis complete!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } finally {
        setState(() {
          _isUploading = false;
          _uploadStatus = '';
        });
      }
    }
  }

  void _showAnalysisDialog(Contract contract) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: kDarkCardColor,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: kPrimaryColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.gavel, color: kDarkTextColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            contract.fileName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: kDarkTextColor,
                            ),
                          ),
                          Text(
                            'Analyzed: ${DateFormat.yMMMd().add_jm().format(contract.uploadedAt)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: kDarkTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: kDarkTextColor),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // Analysis Content with Markdown support
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: MarkdownBody(
                    data: contract.analysisResult,
                    styleSheet: MarkdownStyleSheet(
                      h1: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: kPrimaryColor,
                      ),
                      h2: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: kPrimaryColor,
                      ),
                      h3: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      p: const TextStyle(fontSize: 14, height: 1.5),
                      strong: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: kPrimaryColor,
                      ),
                      listBullet: const TextStyle(color: kPrimaryColor),
                    ),
                  ),
                ),
              ),

              // Footer Actions
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.folder_open),
                      label: const Text('Open File'),
                      onPressed: () {
                        Navigator.pop(context);
                        _openLocalFile(contract.fileUrl);
                      },
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.check),
                      label: const Text('Close'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        foregroundColor: kDarkTextColor,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openLocalFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        // For Android/iOS, you might need to use open_file package
        // For now, show a message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File location: $filePath')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File not found')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening file: $e')),
      );
    }
  }

  Widget _buildRiskBadge(String analysis) {
    // Try to extract risk level from analysis
    final analysisLower = analysis.toLowerCase();
    Color color;
    String riskLevel;

    if (analysisLower.contains('risk analysis: critical') ||
        analysisLower.contains('risk level**: critical')) {
      color = Colors.red;
      riskLevel = 'CRITICAL';
    } else if (analysisLower.contains('risk analysis: high') ||
        analysisLower.contains('risk level**: high')) {
      color = Colors.orange;
      riskLevel = 'HIGH';
    } else if (analysisLower.contains('risk analysis: medium') ||
        analysisLower.contains('risk level**: medium')) {
      color = Colors.yellow;
      riskLevel = 'MEDIUM';
    } else if (analysisLower.contains('risk analysis: low') ||
        analysisLower.contains('risk level**: low')) {
      color = Colors.green;
      riskLevel = 'LOW';
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        riskLevel,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Upload Button
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              ElevatedButton.icon(
                icon: _isUploading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(kDarkTextColor),
                  ),
                )
                    : const Icon(Icons.upload_file),
                label: Text(_isUploading ? _uploadStatus : 'Upload Contract for AI Review'),
                onPressed: _isUploading ? null : _pickAndUploadFile,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: kPrimaryColor,
                  foregroundColor: kDarkTextColor,
                ),
              ),
              if (_isUploading)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'This may take 10-30 seconds...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[400],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        ),

        const Divider(),

        // Review History Header
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Icon(Icons.history, size: 20),
              SizedBox(width: 8),
              Text(
                'Review History',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),

        // Contract List
        Expanded(
          child: StreamBuilder<List<Contract>>(
            stream: _contractService.getContracts(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: ${snapshot.error}'),
                    ],
                  ),
                );
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.description_outlined,
                          size: 64,
                          color: Colors.grey[600]),
                      const SizedBox(height: 16),
                      Text(
                        'No contracts reviewed yet.',
                        style: TextStyle(fontSize: 16, color: Colors.grey[400]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Upload a contract to get started!',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                );
              }

              final contracts = snapshot.data!;
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: contracts.length,
                itemBuilder: (context, index) {
                  final contract = contracts[index];
                  return Card(
                    color: kDarkCardColor,
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: kPrimaryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.description, color: kPrimaryColor),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              contract.fileName,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildRiskBadge(contract.analysisResult),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.access_time, size: 12, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              Text(
                                DateFormat.yMMMd().add_jm().format(contract.uploadedAt),
                                style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            contract.analysisResult.length > 100
                                ? '${contract.analysisResult.substring(0, 100)}...'
                                : contract.analysisResult,
                            style: const TextStyle(fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      isThreeLine: true,
                      onTap: () => _showAnalysisDialog(contract),
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}