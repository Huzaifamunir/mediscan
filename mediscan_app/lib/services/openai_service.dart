import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/analysis_result.dart';
import 'package:uuid/uuid.dart';

class OpenAIService {
  // Base URLs and model names are configurable via .env so you can point
  // to a proxy or switch models without rebuilding the app.
  static String get _baseUrl {
    final v = dotenv.env['OPENAI_BASE_URL']?.trim();
    return (v != null && v.isNotEmpty) ? v : 'https://api.openai.com/v1';
  }

  static String get _chatModel {
    final v = dotenv.env['OPENAI_CHAT_MODEL']?.trim();
    return (v != null && v.isNotEmpty) ? v : 'gpt-4o';
  }

  static String get _transcriptionModel {
    final v = dotenv.env['OPENAI_TRANSCRIPTION_MODEL']?.trim();
    return (v != null && v.isNotEmpty) ? v : 'whisper-1';
  }

  static String get _ttsModel {
    final v = dotenv.env['OPENAI_TTS_MODEL']?.trim();
    return (v != null && v.isNotEmpty) ? v : 'tts-1';
  }

  static String get _ttsVoice {
    final v = dotenv.env['OPENAI_TTS_VOICE']?.trim();
    return (v != null && v.isNotEmpty) ? v : 'nova';
  }

  final String apiKey;
  late final Dio _dio;

  OpenAIService({String? apiKeyOverride})
      : apiKey = apiKeyOverride ??
            (dotenv.env['OPENAI_API_KEY'] ?? '') {
    // Debug log to confirm which key is actually used at runtime (prefix only).
    if (kDebugMode) {
      final prefix = apiKey.length >= 12 ? apiKey.substring(0, 12) : apiKey;
      debugPrint('OpenAIService using API key prefix: $prefix...');
    }
    if (apiKey.isEmpty) {
      throw Exception(
          'OPENAI_API_KEY is not set. Add it to a .env file in the app root.');
    }

    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      headers: {
        // Use the resolved instance field, not the nullable constructor arg
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 120),
    ));
  }

  // ─── Check if file is a medical report ──────────────────────────────────────
  Future<bool> checkIsMedicalReport(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);
    final extension = imageFile.path.split('.').last.toLowerCase();
    final mimeType = extension == 'png' ? 'image/png' : 'image/jpeg';

    final response = await _dio.post(
      '/chat/completions',
      data: {
        'model': _chatModel,
        'max_tokens': 10,
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'image_url',
                'image_url': {
                  'url': 'data:$mimeType;base64,$base64Image',
                  'detail': 'low',
                },
              },
              {
                'type': 'text',
                'text':
                    'Is this a medical report, lab result, X-ray, MRI scan, ECG, prescription, or any medical document? Reply with only "yes" or "no".',
              },
            ],
          },
        ],
      },
    );

    final content =
        (response.data['choices'][0]['message']['content'] as String)
            .toLowerCase()
            .trim();
    return content.contains('yes');
  }

  // ─── Analyze Image Report ────────────────────────────────────────────────────
  Future<AnalysisResult> analyzeImageReport(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);
    final extension = imageFile.path.split('.').last.toLowerCase();
    final mimeType = extension == 'png' ? 'image/png' : 'image/jpeg';

    final response = await _dio.post(
      '/chat/completions',
      data: {
        'model': _chatModel,
        'max_tokens': 4096,
        'messages': [
          {
            'role': 'system',
            'content': _systemPrompt,
          },
          {
            'role': 'user',
            'content': [
              {
                'type': 'image_url',
                'image_url': {
                  'url': 'data:$mimeType;base64,$base64Image',
                  'detail': 'high',
                },
              },
              {
                'type': 'text',
                'text':
                    'Please analyze this medical report image and provide a comprehensive analysis in the JSON format specified.',
              },
            ],
          },
        ],
      },
    );

    final content = response.data['choices'][0]['message']['content'] as String;
    return _parseResponse(content, imagePath: imageFile.path);
  }

  // ─── Analyze Text Report (from PDF extraction) ───────────────────────────────
  Future<AnalysisResult> analyzeTextReport(String text, {String? pdfPath}) async {
    final response = await _dio.post(
      '/chat/completions',
      data: {
        'model': _chatModel,
        'max_tokens': 4096,
        'messages': [
          {
            'role': 'system',
            'content': _systemPrompt,
          },
          {
            'role': 'user',
            'content':
                'Please analyze this medical report and provide a comprehensive analysis in the JSON format specified.\n\nReport Content:\n$text',
          },
        ],
      },
    );

    final content = response.data['choices'][0]['message']['content'] as String;
    return _parseResponse(content, pdfPath: pdfPath);
  }

  // ─── Parse Response ──────────────────────────────────────────────────────────
  AnalysisResult _parseResponse(String content, {String? imagePath, String? pdfPath}) {
    try {
      // Extract JSON from markdown code blocks if present
      String jsonStr = content;
      final jsonMatch = RegExp(r'```json\s*([\s\S]*?)\s*```').firstMatch(content);
      if (jsonMatch != null) {
        jsonStr = jsonMatch.group(1)!;
      } else {
        // Try to find raw JSON object
        final objMatch = RegExp(r'\{[\s\S]*\}').firstMatch(content);
        if (objMatch != null) {
          jsonStr = objMatch.group(0)!;
        }
      }

      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      final findings = <Finding>[];
      if (data['findings'] != null) {
        for (final f in data['findings'] as List) {
          findings.add(Finding(
            parameter: f['parameter'] ?? '',
            value: f['value'] ?? '',
            normalRange: f['normalRange'] ?? 'N/A',
            status: _parseStatus(f['status']),
            interpretation: f['interpretation'],
          ));
        }
      }

      return AnalysisResult(
        id: const Uuid().v4(),
        title: data['title'] ?? 'Medical Report Analysis',
        analyzedAt: DateTime.now(),
        reportType: data['reportType'] ?? 'General Report',
        summary: data['summary'] ?? content,
        summaryUrdu: data['summaryUrdu'],
        findings: findings,
        recommendations: data['recommendations'] != null
            ? List<String>.from(data['recommendations'])
            : [],
        recommendationsUrdu: data['recommendationsUrdu'] != null
            ? List<String>.from(data['recommendationsUrdu'])
            : null,
        riskLevel: _parseRisk(data['riskLevel']),
        rawResponse: content,
        imagePath: imagePath,
        pdfPath: pdfPath,
      );
    } catch (e) {
      // Fallback if JSON parsing fails
      return AnalysisResult(
        id: const Uuid().v4(),
        title: 'Medical Report Analysis',
        analyzedAt: DateTime.now(),
        reportType: 'General Report',
        summary: content,
        findings: [],
        recommendations: [],
        riskLevel: RiskLevel.low,
        rawResponse: content,
        imagePath: imagePath,
        pdfPath: pdfPath,
      );
    }
  }

  FindingStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'normal':
        return FindingStatus.normal;
      case 'low':
        return FindingStatus.low;
      case 'high':
        return FindingStatus.high;
      case 'critical':
        return FindingStatus.critical;
      default:
        return FindingStatus.unknown;
    }
  }

  RiskLevel _parseRisk(String? risk) {
    switch (risk?.toLowerCase()) {
      case 'low':
        return RiskLevel.low;
      case 'moderate':
        return RiskLevel.moderate;
      case 'high':
        return RiskLevel.high;
      case 'critical':
        return RiskLevel.critical;
      default:
        return RiskLevel.low;
    }
  }

  static const String _systemPrompt = '''
You are an expert medical report analyst AI. Your role is to analyze medical reports, lab results, blood tests, X-rays, MRIs, and other diagnostic documents.

When analyzing a report, provide a comprehensive, clear, and structured response in the following JSON format:

{
  "title": "Brief descriptive title of the report type",
  "reportType": "e.g., Complete Blood Count, Lipid Panel, X-Ray, MRI, etc.",
  "riskLevel": "low|moderate|high|critical",
  "summary": "Clear, patient-friendly summary of the report (2-4 sentences) in English",
  "summaryUrdu": "Clear, patient-friendly summary of the report (2-4 sentences) translated into Urdu using Arabic script",
  "findings": [
    {
      "parameter": "Parameter name (e.g., Hemoglobin, LDL Cholesterol)",
      "value": "Patient's value with unit (e.g., 11.2 g/dL)",
      "normalRange": "Normal reference range (e.g., 12.0-16.0 g/dL)",
      "status": "normal|low|high|critical",
      "interpretation": "Brief explanation of what this finding means"
    }
  ],
  "recommendations": [
    "Actionable recommendation 1 in English",
    "Actionable recommendation 2 in English"
  ],
  "recommendationsUrdu": [
    "Translation of recommendation 1 in Urdu",
    "Translation of recommendation 2 in Urdu"
  ]
}

Important guidelines:
- Use simple, patient-friendly language that non-medical professionals can understand
- All Urdu text must be written in clear Urdu using Arabic script (not transliteration)
- Be accurate and factual based on the report content
- Do NOT diagnose diseases definitively — use phrases like "may indicate", "suggests", "consistent with"
- Always recommend consulting a healthcare professional for medical decisions
- Highlight abnormal values clearly
- If the image is not a medical report, indicate that in the title and summary
- Return ONLY the JSON object, no other text
''';
}
