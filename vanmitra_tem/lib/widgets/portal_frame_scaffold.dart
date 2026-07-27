import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../providers/locale_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/notices_provider.dart';
import '../core/routes/app_router.dart';
import '../services/localization_service.dart';
import 'notice_board_widget.dart';

/// MAHA-DBT Portal Frame — used as the root scaffold for every screen.
///
/// Mirrors the Maharashtra DBT portal structure:
///   ┌─────────────────────────────────────────────────────────┐
///   │ [Emblem] VanMitra-AI    ओझर ग्रा.पं.   [भाषा] [👤]    │  ← Header 64px
///   ├─────────────────────────────────────────────────────────┤
///   │ 📢 सूचना ticker (severity-colored, dismissible)          │  ← Notice ticker
///   ├─────────────────────────────────────────────────────────┤
///   │ मुख्यपृष्ठ › माझे दावे › नवीन दावा                     │  ← Breadcrumb
///   ├─────────────────────────────────────────────────────────┤
///   │                   [ body ]                              │
///   ├─────────────────────────────────────────────────────────┤
///   │ Helpline: 1800-XXX-XXXX | वन हक्क कायदा 2006 | Privacy  │  ← Footer
///   └─────────────────────────────────────────────────────────┘
class PortalFrameScaffold extends ConsumerWidget {
  final Widget body;

  /// DBT-style breadcrumb trail. e.g. ['Dashboard', 'My Claims', 'New Claim']
  /// The last element is the current page (non-tappable). Earlier elements navigate back.
  final List<String> breadcrumbs;

  /// Set to false to hide the notice ticker on this screen (rare).
  final bool showNoticeTicker;

  /// Show a back arrow in the header (auto-set if Navigator can pop)
  final bool? showBackButton;

  /// Floating action button, if any
  final Widget? floatingActionButton;

  /// Additional actions in the header (right side, after the profile icon)
  final List<Widget>? actions;

  /// Optional bottom navigation bar (e.g. for Home Screens)
  final Widget? bottomNavigationBar;

  const PortalFrameScaffold({
    super.key,
    required this.body,
    this.breadcrumbs = const [],
    this.showNoticeTicker = true,
    this.showBackButton,
    this.floatingActionButton,
    this.actions,
    this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final lang = locale.languageCode;
    final auth = ref.watch(authProvider);
    final notices = ref.watch(noticesProvider);
    final canPop = Navigator.of(context).canPop();
    final showBack = showBackButton ?? canPop;

    final List<String> effectiveBreadcrumbs = breadcrumbs.isEmpty 
        ? <String>[context.tr('tab_dashboard')]
        : breadcrumbs;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: Column(
        children: [
          // ── Header Bar ─────────────────────────────────────────────────────
          _PortalHeader(
            lang: lang,
            showBack: showBack,
            actions: actions,
            userName: auth.currentUser?.name,
          ),

          // ── Notice Ticker ──────────────────────────────────────────────────
          if (showNoticeTicker && notices.activeNotices.isNotEmpty)
            NoticeBoardWidget(
              notices: notices.activeNotices,
              mode: NoticeBoardMode.ticker,
              lang: lang,
              onDismiss: (id) =>
                  ref.read(noticesProvider.notifier).dismissNotice(id),
            ),

          // ── Breadcrumb ─────────────────────────────────────────────────────
          if (effectiveBreadcrumbs.isNotEmpty)
            _BreadcrumbBar(breadcrumbs: effectiveBreadcrumbs),

          // ── Body ───────────────────────────────────────────────────────────
          Expanded(child: body),

          // ── Footer ─────────────────────────────────────────────────────────
          const _PortalFooter(),
        ],
      ),
    );
  }
}

// ─── Header Bar ───────────────────────────────────────────────────────────────

class _PortalHeader extends ConsumerWidget {
  final String lang;
  final bool showBack;
  final List<Widget>? actions;
  final String? userName;

  const _PortalHeader({
    required this.lang,
    required this.showBack,
    this.actions,
    this.userName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 64 + MediaQuery.of(context).padding.top,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: const BoxDecoration(
        color: AppColors.govtBlue,
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back or Govt Emblem
          if (showBack)
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 18),
              onPressed: () => Navigator.of(context).pop(),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _GovtEmblem(),
            ),

          // App name + Village
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('app_title'),
                  style: const TextStyle(
                    fontFamily: 'NotoSansDevanagari',
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  context.tr('default_village_name'),
                  style: const TextStyle(
                    fontFamily: 'NotoSansDevanagari',
                    color: Color(0xBBFFFFFF),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // Language switcher
          _LangButton(currentLang: lang, ref: ref),

          // Profile icon
          GestureDetector(
            onTap: () =>
                Navigator.pushNamed(context, AppRouter.profile),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.15),
                border:
                    Border.all(color: Colors.white.withOpacity(0.4)),
              ),
              child: Center(
                child: Text(
                  userName?.isNotEmpty == true
                      ? userName![0].toUpperCase()
                      : '👤',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),

          // Extra actions
          if (actions != null) ...actions!,
        ],
      ),
    );
  }
}

class _GovtEmblem extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Ashoka Chakra placeholder — replace with actual emblem asset
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.15),
        border: Border.all(color: const Color(0xFFFF7A00), width: 2),
      ),
      child: const Center(
        child: Text('🌀', style: TextStyle(fontSize: 18)),
      ),
    );
  }
}

class _LangButton extends StatelessWidget {
  final String currentLang;
  final WidgetRef ref;
  const _LangButton({required this.currentLang, required this.ref});

  static const _langs = {
    'mr': 'मराठी',
    'en': 'EN',
    'hi': 'हिं',
    'kn': 'ಕ',
  };

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      initialValue: currentLang,
      onSelected: (lang) =>
          ref.read(localeProvider.notifier).setLocale(lang),
      itemBuilder: (ctx) => _langs.entries
          .map((e) => PopupMenuItem(value: e.key, child: Text(e.value)))
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white.withOpacity(0.4)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _langs[currentLang] ?? currentLang.toUpperCase(),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600),
            ),
            const Icon(Icons.arrow_drop_down,
                color: Colors.white, size: 14),
          ],
        ),
      ),
    );
  }
}

// ─── Breadcrumb Bar ───────────────────────────────────────────────────────────

class _BreadcrumbBar extends StatelessWidget {
  final List<String> breadcrumbs;
  const _BreadcrumbBar({required this.breadcrumbs});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFEBEFF5),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          for (int i = 0; i < breadcrumbs.length; i++) ...[
            if (i > 0)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text('›',
                    style: TextStyle(
                        color: Color(0xFF6B7280), fontSize: 12)),
              ),
            GestureDetector(
              onTap: i < breadcrumbs.length - 1
                  ? () {
                      // Pop back N times to reach this breadcrumb level
                      final popsNeeded = breadcrumbs.length - 1 - i;
                      for (var p = 0; p < popsNeeded; p++) {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        }
                      }
                    }
                  : null,
              child: Text(
                context.tr(breadcrumbs[i]),
                style: TextStyle(
                  fontFamily: 'NotoSansDevanagari',
                  fontSize: 11,
                  color: i == breadcrumbs.length - 1
                      ? AppColors.govtBlue
                      : const Color(0xFF6B7280),
                  fontWeight: i == breadcrumbs.length - 1
                      ? FontWeight.w600
                      : FontWeight.w400,
                  decoration: i < breadcrumbs.length - 1
                      ? TextDecoration.underline
                      : TextDecoration.none,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Footer ───────────────────────────────────────────────────────────────────

class _PortalFooter extends StatelessWidget {
  const _PortalFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.govtBlue,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Text(
        context.tr('footer_text'),
        style: const TextStyle(
          fontFamily: 'NotoSansDevanagari',
          color: Color(0xBBFFFFFF),
          fontSize: 9,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
