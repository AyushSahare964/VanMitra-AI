import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'module_a_service.dart';
import '../models/claim.dart';

/// Network-backed implementation of [ModuleAService].
///
/// Makes real HTTP calls to the VanMitra FastAPI backend (built from
/// vanmitra_model_a_bundle/fastapi_reference/model_a_fastapi_reference.py
/// with app/agents.py providing the agent implementations from the Colab notebook).
///
/// Never used directly — the [moduleAProvider] selects between this and
/// [DefaultModuleAService] based on connectivity and backend health.
///
/// All personal data is sent over HTTPS. Do NOT instantiate with an http:// URL
/// in production (Android enforces cleartext restrictions anyway).
class AIModuleAService implements ModuleAService {
  final String baseUrl;
  final Duration timeout;
  final http.Client _client;

  AIModuleAService({
    required this.baseUrl,
    this.timeout = const Duration(seconds: 20),
    http.Client? client,
  }) : _client = client ?? http.Client();

  // ─── Health ────────────────────────────────────────────────────────────────

  /// Lightweight health check — polled by [moduleAProvider] before every AI
  /// call so a dead server does not cause a 20-second timeout on every claim.
  @override
  Future<bool> checkHealth() async {
    try {
      final res = await _client
          .get(Uri.parse('$baseUrl/api/v1/health'))
          .timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ─── Draft generation ─────────────────────────────────────────────────────

  @override
  Future<ClaimDraftResult> generateDraft({
    required ClaimType claimType,
    required String claimantName,
    required String fatherHusbandName,
    required String address,
    required String surveyNumber,
    required double areaSqMeters,
    required String natureOfRight,
    required int occupationYears,
    Map<String, bool> evidence = const {},
  }) async {
    final payload = {
      'form_type': claimType == ClaimType.formA ? 'A' : 'B',
      'claimant_name': claimantName,
      'father_husband_name': fatherHusbandName,
      'survey_number': surveyNumber,
      'area_sq_meters': areaSqMeters,
      'nature_of_right': natureOfRight,
      'occupation_years': occupationYears,
      'language': 'mr',
    };

    final res = await _client
        .post(
          Uri.parse('$baseUrl/api/v1/generate-draft'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        )
        .timeout(timeout);

    if (res.statusCode != 200) {
      throw ModuleAServiceException(
        'generate-draft failed: HTTP ${res.statusCode} — ${res.body}',
      );
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return ClaimDraftResult(
      draftText: body['draft_text'] as String,
      formType: body['form_type'] as String? ?? payload['form_type'] as String,
      isAIGenerated: body['is_ai_generated'] as bool? ?? true,
      disclaimer: body['disclaimer'] as String? ??
          'AI-generated draft — please review before submission.',
    );
  }

  // ─── Document verification ────────────────────────────────────────────────

  @override
  Future<DocumentVerifyResult> verifyDocument(
    Uint8List imageData,
    String expectedCategory,
  ) async {
    final req = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/v1/verify-document'),
    )
      ..fields['expected_category'] = expectedCategory
      ..files.add(http.MultipartFile.fromBytes(
        'image',
        imageData,
        filename: 'document.jpg',
      ));

    final streamed = await req.send().timeout(timeout);
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode != 200) {
      throw ModuleAServiceException(
        'verify-document failed: HTTP ${res.statusCode} — ${res.body}',
      );
    }

    return DocumentVerifyResult.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }

  // ─── Voice transcription ──────────────────────────────────────────────────

  @override
  Future<String> transcribeVoice(Uint8List audioData, String language) async {
    final req = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/v1/transcribe'),
    )
      ..fields['language'] = language
      ..files.add(http.MultipartFile.fromBytes(
        'audio',
        audioData,
        filename: 'clip.wav',
      ));

    final streamed = await req.send().timeout(timeout);
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode != 200) {
      throw ModuleAServiceException(
        'transcribe failed: HTTP ${res.statusCode} — ${res.body}',
      );
    }

    return (jsonDecode(res.body) as Map<String, dynamic>)['text'] as String;
  }

  // ─── Rejection analysis ───────────────────────────────────────────────────

  @override
  Future<RejectionAnalysis> analyzeRejection(Uint8List imageData) async {
    final req = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/v1/analyze-rejection'),
    )
      ..files.add(http.MultipartFile.fromBytes(
        'image',
        imageData,
        filename: 'order.jpg',
      ));

    final streamed = await req.send().timeout(timeout);
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode != 200) {
      throw ModuleAServiceException(
        'analyze-rejection failed: HTTP ${res.statusCode} — ${res.body}',
      );
    }

    return RejectionAnalysis.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }

  // ─── Appeal generation ────────────────────────────────────────────────────

  @override
  Future<AppealDraftResult> generateAppeal({
    required RejectionAnalysis rejection,
    required Claim originalClaim,
  }) async {
    final payload = {
      'rejection_analysis': rejection.toJson(),
      'original_claim': {
        'form_type': originalClaim.type == ClaimType.formA ? 'A' : 'B',
        'claimant_name': originalClaim.claimantName,
        'father_husband_name': originalClaim.fatherHusbandName ?? '',
        'survey_number': originalClaim.surveyNumber,
        'area_sq_meters': originalClaim.areaSqMeters ?? 0.0,
        'nature_of_right': originalClaim.nature.name,
        'occupation_years': originalClaim.occupationYears ?? 0,
        'language': 'mr',
      },
    };

    final res = await _client
        .post(
          Uri.parse('$baseUrl/api/v1/generate-appeal'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        )
        .timeout(timeout);

    if (res.statusCode != 200) {
      throw ModuleAServiceException(
        'generate-appeal failed: HTTP ${res.statusCode} — ${res.body}',
      );
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return AppealDraftResult(
      appealText: body['appeal_text'] as String,
      appealDeadline: body['appeal_deadline'] != null
          ? DateTime.parse(body['appeal_deadline'] as String)
          : null,
      isAIGenerated: body['is_ai_generated'] as bool? ?? true,
    );
  }

  void dispose() => _client.close();
}
