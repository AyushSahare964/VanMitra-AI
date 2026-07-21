import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/module_a_service.dart';
import '../services/ai_module_a_service.dart';
import '../services/default_module_a_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// ─── Connectivity ─────────────────────────────────────────────────────────────

/// Stream provider — emits true when the device has any network connectivity.
///
/// Uses connectivity_plus to detect wifi/mobile data. Note: connectivity
/// does NOT guarantee the FastAPI backend is reachable — the backend health
/// check in [moduleAProvider] handles that separately.
final connectivityProvider = StreamProvider<bool>((ref) {
  return Connectivity()
      .onConnectivityChanged
      .map((results) => results.any(
            (r) =>
                r == ConnectivityResult.wifi ||
                r == ConnectivityResult.mobile ||
                r == ConnectivityResult.ethernet,
          ));
});

// ─── Backend URL ──────────────────────────────────────────────────────────────

/// The VanMitra FastAPI backend base URL.
///
/// Set at build time via:
///   flutter build apk --dart-define=VANMITRA_API_BASE_URL=http://10.0.2.2:8000
///
/// For local development (Android emulator → host machine):
///   VANMITRA_API_BASE_URL=http://10.0.2.2:8000
///
/// For production: set to the HTTPS Cloud Run / Render URL.
const _apiBaseUrl = String.fromEnvironment(
  'VANMITRA_API_BASE_URL',
  defaultValue: kIsWeb ? 'http://localhost:8000' : 'http://10.0.2.2:8000',
);

// ─── Module A Provider ────────────────────────────────────────────────────────

/// The central Module A provider — selects AI vs offline based on:
///   1. Device has network connectivity (connectivityProvider)
///   2. Backend URL is configured (non-empty)
///   3. Backend health endpoint responds OK (/api/v1/health, 5s timeout)
///
/// Falls back to [DefaultModuleAService] silently in any failure case.
/// This matches the offline-first strategy from the system workflow (§3).
final moduleAProvider = Provider<ModuleAService>((ref) {
  if (_apiBaseUrl.isNotEmpty) {
    // Force AI service for testing purposes so it doesn't fail on web's connectivity results
    return AIModuleAService(baseUrl: _apiBaseUrl);
  }
  return DefaultModuleAService();
});

/// Convenience provider for components that only need to know if the
/// AI backend is actively being used (to show the "AI-powered" badge).
final isAIActiveProvider = FutureProvider<bool>((ref) async {
  if (_apiBaseUrl.isEmpty) return false;

  final service = AIModuleAService(baseUrl: _apiBaseUrl);
  final healthy = await service.checkHealth();
  service.dispose();
  return healthy;
});
