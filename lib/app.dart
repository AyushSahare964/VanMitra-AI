import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'providers/locale_provider.dart';
import 'services/localization_service.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/onboarding/language_selection_screen.dart';
import 'screens/onboarding/registration_screen.dart';
import 'screens/home/villager_home_screen.dart';
import 'screens/home/admin_home_screen.dart';
import 'screens/home/boundary_map_screen.dart';
import 'screens/gram_sabha/gram_sabha_dashboard.dart';
import 'screens/gram_sabha/create_meeting_screen.dart';
import 'screens/gram_sabha/meeting_detail_screen.dart';
import 'screens/gram_sabha/gram_sabha_log_screen.dart';
import 'screens/gram_sabha/resolution_ledger_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'core/routes/app_router.dart';
import 'screens/claims/claim_type_selection_screen.dart';
import 'screens/claims/claim_form_screen.dart';
import 'screens/claims/evidence_checklist_screen.dart';
import 'screens/claims/draft_preview_screen.dart';
import 'screens/claims/my_claims_screen.dart';
import 'screens/claims/rejection_analysis_screen.dart';
import 'screens/claims/appeal_draft_screen.dart';
import 'screens/claims/rule_13_info_screen.dart';
// Module C — Gram Sabha advanced screens
import 'screens/gram_sabha/member_enrolment_screen.dart';
import 'screens/gram_sabha/resolution_recording_screen.dart';
import 'screens/gram_sabha/mom_viewer_screen.dart';

/// Root MaterialApp for VanMitra-AI
class VanMitraApp extends ConsumerWidget {
  const VanMitraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      title: 'VanMitra-AI | वनमित्र',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: locale,
      supportedLocales: LocaleNotifier.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Use English fallback for locales without Material translations
      localeResolutionCallback: (locale, supportedLocales) {
        for (final supported in supportedLocales) {
          if (supported.languageCode == locale?.languageCode) {
            return supported;
          }
        }
        // Fallback to English if exact match not found
        return const Locale('en');
      },
      initialRoute: AppRouter.splash,
      builder: (context, child) {
        // Enforce mobile-sized viewport on Web/Desktop
        return Container(
          color: Colors.black, // Dark background outside the mobile frame
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: ClipRect(
                child: child ?? const SizedBox(),
              ),
            ),
          ),
        );
      },
      routes: {
        AppRouter.splash: (_) => const SplashScreen(),
        AppRouter.languageSelection: (_) => const LanguageSelectionScreen(),
        AppRouter.registration: (_) => const RegistrationScreen(),
        AppRouter.villagerHome: (_) => const VillagerHomeScreen(),
        AppRouter.adminHome: (_) => const AdminHomeScreen(),
        AppRouter.gramSabhaDashboard: (_) => const GramSabhaDashboard(),
        AppRouter.createMeeting: (_) => const CreateMeetingScreen(),
        AppRouter.meetingDetail: (_) => const MeetingDetailScreen(),
        AppRouter.resolutionLedger: (_) => const ResolutionLedgerScreen(),
        // Module A — Claims (Phase 6)
        AppRouter.claimType: (_) => const ClaimTypeSelectionScreen(),
        AppRouter.claimForm: (_) => const ClaimFormScreen(),
        AppRouter.evidenceChecklist: (_) => const EvidenceChecklistScreen(),
        AppRouter.claimDraft: (_) => const DraftPreviewScreen(),
        AppRouter.myClaims: (_) => const MyClaimsScreen(),
        AppRouter.rejectionCheck: (_) => const RejectionAnalysisScreen(),
        AppRouter.appealDraft: (_) => const AppealDraftScreen(),
        AppRouter.rule13Evidence: (_) => const Rule13InfoScreen(),
        // Module B — CFR Boundary Map
        AppRouter.boundaryMap: (_) => const BoundaryMapScreen(),
        // Module C — Gram Sabha advanced screens
        AppRouter.memberEnrolment: (_) => const MemberEnrolmentScreen(),
        // Profile & Settings
        AppRouter.profile: (_) => const ProfileScreen(),
      },
      onGenerateRoute: (settings) {
        // Routes that require runtime arguments go here
        if (settings.name == AppRouter.attendanceManagement) {
          final args = settings.arguments as Map<String, dynamic>? ?? {};
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => GramSabhaLogScreen(
              meetingId: args['meetingId'] as String? ?? '',
              villageId: args['villageId'] as String? ?? '',
              registeredCount: args['registeredCount'] as int? ?? 100,
            ),
          );
        }
        if (settings.name == AppRouter.resolutionRecording) {
          final args = settings.arguments as Map<String, dynamic>? ?? {};
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => ResolutionRecordingScreen(
              meetingId: args['meetingId'] as String? ?? '',
              villageId: args['villageId'] as String? ?? '',
              language: args['language'] as String? ?? 'mr',
            ),
          );
        }
        if (settings.name == AppRouter.momViewer) {
          final args = settings.arguments as Map<String, dynamic>? ?? {};
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => MomViewerScreen(
              villageId: args['villageId'] as String? ?? '',
            ),
          );
        }
        return null; // Fall through to static routes
      },
    );
  }
}
