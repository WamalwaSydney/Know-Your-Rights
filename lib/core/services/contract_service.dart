import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:legal_ai/core/models/contract.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdf/pdf.dart';

class ContractService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? 'mock_user';

  // HARD-CODED Groq API KEY
  static const String groqApiKey =
      "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";

  static const String groqUrl = "https://api.groq.com/openai/v1/chat/completions";
  static const String groqModel = "llama-3.1-8b-instant";

  /// Get all contracts
  Stream<List<Contract>> getContracts() {
    return _db
        .collection('users')
        .doc(_userId)
        .collection('contracts')
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Contract.fromFirestore(doc)).toList());
  }

  /// Save contract metadata
  Future<void> addContract(Contract contract) async {
    await _db
        .collection('users')
        .doc(_userId)
        .collection('contracts')
        .add(contract.toFirestore());
  }

  /// MAIN PDF ANALYSIS FUNCTION
  ///
  /// Uses Syncfusion to extract text → compress → send to Groq
  Future<String> analyzeContract(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception("File not found: $filePath");
      }

      // 1️⃣ Read PDF
      final bytes = await file.readAsBytes();

      // 2️⃣ Load PDF using Syncfusion (mobile-safe)
      final PdfDocument pdf = PdfDocument(inputBytes: bytes);

      // 3️⃣ Extract full text from all pages
      String extractedText = PdfTextExtractor(pdf).extractText();

      pdf.dispose();

      if (extractedText.trim().isEmpty) {
        throw Exception("PDF contains no readable text.");
      }

      // 4️⃣ Compress text to avoid Groq limits
      String compressed = _compressText(extractedText);

      // 5️⃣ Build prompt
      final String prompt = """
You are an expert contract lawyer. Analyze the following contract text:

$compressed

Provide detailed structured analysis with:
1. DOCUMENT TYPE & OVERVIEW  
2. RISK ASSESSMENT  
3. KEY CLAUSES  
4. RED FLAGS  
5. FAIRNESS  
6. RECOMMENDATIONS  
7. ACTION ITEMS  

Include an AI legal disclaimer.
""";

      // 6️⃣ Call Groq API
      final response = await http.post(
        Uri.parse(groqUrl),
        headers: {
          "Authorization": "Bearer $groqApiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "model": groqModel,
          "temperature": 0.7,
          "max_tokens": 2500,
          "messages": [
            {"role": "user", "content": prompt}
          ]
        }),
      );

      if (response.statusCode != 200) {
        throw Exception("Groq API error: ${response.body}");
      }

      final jsonResponse = jsonDecode(response.body);
      final result = jsonResponse["choices"][0]["message"]["content"];

      return result ?? "No response from Groq";

    } catch (e) {
      print("❌ Error analyzing contract: $e");

      return """
**Analysis Error**
AI could not analyze the document:
$e

Try:
- Ensure PDF has selectable text (not scanned images)
- Avoid protected or corrupted PDFs

For urgent issues, consult a licensed attorney.
""";
    }
  }

  /// Compress text to stay under TPM/token limits
  String _compressText(String text) {
    const int limit = 9000;

    if (text.length <= limit) return text;

    final head = text.substring(0, 4500);
    final tail = text.substring(text.length - 4500);

    return """
[NOTE: PDF compressed due to size]

--- BEGINNING ---
$head

--- SKIPPED FOR LENGTH ---

--- END ---
$tail
""";
  }

  /// Update analysis in Firestore
  Future<void> updateContractAnalysis(String id, String analysis) async {
    await _db
        .collection('users')
        .doc(_userId)
        .collection('contracts')
        .doc(id)
        .update({
      'analysis': analysis,
      'analyzedAt': FieldValue.serverTimestamp(),
    });
  }
}
