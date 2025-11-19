// lib/core/services/document_analysis_service.dart

import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:docx_to_text/docx_to_text.dart';

class DocumentAnalysisService {
  static const int MAX_TOKENS = 3000;
  static const int MAX_CHARACTERS = 12000;

  /// Extract text from PDF using Syncfusion
  Future<String?> extractTextFromPdf(String filePath) async {
    try {
      print('📄 Extracting text from PDF: $filePath');

      final fileBytes = await File(filePath).readAsBytes();
      final PdfDocument document = PdfDocument(inputBytes: fileBytes);
      final String text = PdfTextExtractor(document).extractText();
      document.dispose();

      print('✅ Extracted ${text.length} characters from PDF');
      return text;
    } catch (e) {
      print('❌ Error extracting PDF text: $e');
      throw Exception('Failed to read PDF: ${e.toString()}');
    }
  }

  /// Extract text from Word document (.docx)
  Future<String?> extractTextFromWord(String filePath) async {
    try {
      print('📄 Extracting text from Word: $filePath');

      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final String text = docxToText(bytes);

      print('✅ Extracted ${text.length} characters from Word');
      return text;
    } catch (e) {
      print('❌ Error extracting Word text: $e');
      throw Exception('Failed to read Word document: ${e.toString()}');
    }
  }

  /// Simple document explanation only
  Future<String> analyzeDocument(String documentText, String documentType) async {
    try {
      print('🔍 Generating document explanation...');

      // Get compression info
      final compressionInfo = getCompressionInfo(documentText);
      print('📊 Compression Info: $compressionInfo');

      // If still too large after compression, use chunking strategy
      if (compressionInfo['needs_compression'] as bool) {
        final compressedText = compressDocumentText(documentText, maxLength: MAX_CHARACTERS);

        if (estimateTokenCount(compressedText) > MAX_TOKENS) {
          print('⚠️ Document still too large, using chunked explanation');
          return await _explainLargeDocument(documentText, documentType);
        }

        return compressedText;
      }

      return documentText;
    } catch (e) {
      print('❌ Error in document analysis: $e');
      rethrow;
    }
  }

  /// Explain very large documents by focusing on key sections
  Future<String> _explainLargeDocument(String documentText, String documentType) async {
    print('📑 Explaining large document using key sections...');

    // Extract key sections only for very large documents
    final keySections = _extractKeyLegalSections(documentText);

    if (keySections.isNotEmpty) {
      print('✅ Extracted ${keySections.length} key sections for explanation');
      return keySections;
    }

    // Fallback: use first part and summary approach
    return _createSimpleExplanation(documentText, documentType);
  }

  /// Create a simple explanation for extremely large documents
  String _createSimpleExplanation(String text, String documentType) {
    // Take first part and last part of document (often contains key info)
    final firstPart = text.length > 2000 ? text.substring(0, 2000) : text;
    final lastPart = text.length > 2000 ? text.substring(text.length - 1500) : '';

    return '''
$firstPart${lastPart.isNotEmpty ? '\n\n[...document truncated...]\n\n$lastPart' : ''}

*Note: This is a partial view of a very large document. Key sections have been extracted for explanation.*
''';
  }

  /// Extract only the most important legal sections
  String _extractKeyLegalSections(String text) {
    final sections = <String>[];

    // Define priority legal sections to look for
    final prioritySections = [
      'PARTIES', 'EFFECTIVE DATE', 'TERM', 'TERMINATION',
      'PAYMENT', 'COMPENSATION', 'FEES', 'PRICE',
      'CONFIDENTIALITY', 'NON-DISCLOSURE',
      'INTELLECTUAL PROPERTY', 'IP', 'OWNERSHIP',
      'INDEMNIFICATION', 'LIABILITY', 'LIMITATION OF LIABILITY',
      'WARRANTY', 'REPRESENTATIONS', 'COVENANTS',
      'GOVERNING LAW', 'JURISDICTION', 'DISPUTE RESOLUTION', 'ARBITRATION',
      'SIGNATURE', 'SIGNATURES'
    ];

    for (var section in prioritySections) {
      final pattern = RegExp('$section[^a-zA-Z]*(.*?)(?=${prioritySections.join('|')}|\$)',
          caseSensitive: false, dotAll: true);
      final matches = pattern.allMatches(text);

      for (var match in matches) {
        final content = match.group(1)?.trim();
        if (content != null && content.length > 10) {
          final sectionContent = '**${section.toUpperCase()}**: $content\n\n';
          if (_estimateTokenCount(sections.join() + sectionContent) < MAX_TOKENS) {
            sections.add(sectionContent);
          }
        }
      }
    }

    if (sections.isNotEmpty) {
      return 'KEY SECTIONS FOR EXPLANATION:\n\n${sections.join()}\n\n*Note: Large document explained using key sections only.*';
    }

    return '';
  }

  /// Compress document text aggressively
  String compressDocumentText(String text, {int maxLength = 12000}) {
    print('📦 Compressing document text...');
    print('📊 Original length: ${text.length} characters');

    if (text.length <= maxLength) {
      return text;
    }

    // Step 1: Remove all extra whitespace aggressively
    String compressed = text
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'\n\s*\n'), '\n')
        .trim();

    // Step 2: Remove common legal boilerplate
    compressed = _removeLegalBoilerplate(compressed);

    // Step 3: Remove repetitive clauses
    compressed = _removeRepetitiveContent(compressed);

    // Step 4: If still too long, use strategic truncation
    if (compressed.length > maxLength) {
      compressed = _aggressiveTruncate(compressed, maxLength);
    }

    print('📊 Compressed length: ${compressed.length} characters');
    print('📈 Compression ratio: ${((1 - compressed.length / text.length) * 100).toStringAsFixed(1)}%');

    return compressed;
  }

  /// Remove common legal boilerplate text aggressively
  String _removeLegalBoilerplate(String text) {
    final boilerplatePatterns = [
      RegExp(r'Page\s+\d+\s+of\s+\d+', caseSensitive: false),
      RegExp(r'CONFIDENTIAL', caseSensitive: false),
      RegExp(r'DRAFT', caseSensitive: false),
      RegExp(r'FOR REVIEW', caseSensitive: false),
      RegExp(r'This document is provided for informational purposes only[^.]*?governing law\.', caseSensitive: false, dotAll: true),
      RegExp(r'The information contained herein[^.]*?professional advice\.', caseSensitive: false, dotAll: true),
      RegExp(r'This agreement is made and entered into[^.]*?witness whereof', caseSensitive: false, dotAll: true),
      RegExp(r'IN WITNESS WHEREOF.*?SIGNATURE:\s*\n\s*\n.*?SIGNATURE:\s*\n', caseSensitive: false, dotAll: true),
      RegExp(r'TABLE OF CONTENTS.*?(?=SECTION|ARTICLE)', caseSensitive: false, dotAll: true),
      RegExp(r'\n{3,}', dotAll: true),
    ];

    String result = text;
    for (var pattern in boilerplatePatterns) {
      result = result.replaceAll(pattern, '');
    }

    return result;
  }

  /// Remove repetitive content
  String _removeRepetitiveContent(String text) {
    final headerPattern = RegExp(r'(SECTION|ARTICLE|CLAUSE)\s+[IVXLC\d]+', caseSensitive: false);
    final headers = headerPattern.allMatches(text).map((m) => m.group(0)).toList();

    if (headers.length > 10) {
      final uniqueSections = headers.toSet().toList();
      if (uniqueSections.length < headers.length / 2) {
        return _extractUniqueSections(text);
      }
    }

    return text;
  }

  /// Extract only unique sections from highly repetitive documents
  String _extractUniqueSections(String text) {
    final sections = <String, String>{};
    final sectionPattern = RegExp(r'(SECTION|ARTICLE|CLAUSE)\s+([IVXLC\d]+)[^a-zA-Z]*(.*?)(?=(SECTION|ARTICLE|CLAUSE)\s+[IVXLC\d]+|\$)',
        caseSensitive: false, dotAll: true);

    final matches = sectionPattern.allMatches(text);
    for (var match in matches) {
      final header = match.group(1);
      final number = match.group(2);
      final content = match.group(3)?.trim();

      if (header != null && number != null && content != null) {
        final key = '$header $number';
        if (!sections.containsKey(key) || content.length > (sections[key]?.length ?? 0)) {
          sections[key] = content;
        }
      }
    }

    if (sections.isNotEmpty) {
      final result = sections.entries.map((e) => '${e.key}: ${e.value}').join('\n\n');
      return 'UNIQUE SECTIONS FOR EXPLANATION:\n\n$result\n\n*Note: Repetitive document explained using unique sections only.*';
    }

    return text;
  }

  /// Aggressive truncation for very large documents
  String _aggressiveTruncate(String text, int maxLength) {
    print('⚠️ Applying aggressive truncation...');

    final firstPart = text.substring(0, (maxLength * 0.6).floor());
    final lastPart = text.substring(text.length - (maxLength * 0.3).floor());

    return '$firstPart\n\n[...document truncated...]\n\n$lastPart\n\n*Note: Very large document truncated for explanation.*';
  }

  /// Estimate token count (conservative)
  int estimateTokenCount(String text) {
    return (text.length / 3.5).ceil();
  }

  int _estimateTokenCount(String text) {
    return estimateTokenCount(text);
  }

  /// Check if document needs compression
  bool needsCompression(String text) {
    return estimateTokenCount(text) > MAX_TOKENS;
  }

  /// Get compression recommendations
  Map<String, dynamic> getCompressionInfo(String originalText) {
    final compressed = compressDocumentText(originalText);
    final originalTokens = estimateTokenCount(originalText);
    final compressedTokens = estimateTokenCount(compressed);
    final needsComp = originalTokens > MAX_TOKENS;

    return {
      'original_length': originalText.length,
      'compressed_length': compressed.length,
      'original_tokens': originalTokens,
      'compressed_tokens': compressedTokens,
      'compression_ratio': ((1 - compressed.length / originalText.length) * 100).toStringAsFixed(1),
      'token_savings': originalTokens - compressedTokens,
      'needs_compression': needsComp,
      'max_tokens': MAX_TOKENS,
      'within_limits': compressedTokens <= MAX_TOKENS,
    };
  }

  /// File size in readable format
  String getFileSize(File file) {
    final int bytes = file.lengthSync();
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
  }

  /// Validate file extension
  bool isValidDocumentFile(String? path, String? extension) {
    if (path == null || extension == null) return false;

    final validExtensions = ['pdf', 'doc', 'docx'];
    return validExtensions.contains(extension.toLowerCase());
  }

  /// Human-readable document type name
  String getDocumentTypeDescription(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return 'PDF Document';
      case 'doc':
        return 'Word Document (.doc)';
      case 'docx':
        return 'Word Document (.docx)';
      default:
        return 'Unknown Document';
    }
  }
}