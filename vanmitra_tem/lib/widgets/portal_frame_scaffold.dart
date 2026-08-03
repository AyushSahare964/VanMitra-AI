import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../providers/locale_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/notices_provider.dart';
import '../services/localization_service.dart';
import 'notice_board_widget.dart';
import 'common/app_header.dart';

/// MAHA-DBT / Forest Canopy Portal Frame — used as root scaffold for core screens.
class PortalFrameScaffold extends ConsumerWidget {
  final Widget body;
  final List<String> breadcrumbs;
  final bool showNoticeTicker;
  final bool? showBackButton;
  final Widget? floatingActionButton;
  final List<Widget>? actions;
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
      backgroundColor: AppColors.surfaceBase,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: Column(
        children: [
          // ── Universal AppHeader (Forest Canopy Theme) ──────────────────────
          AppHeader(
            showBack: showBack,
            actions: actions,
            title: context.tr('app_title'),
            subtitle: auth.currentUser?.villageId ?? context.tr('default_village_name'),
          ),

          // ── Notice Ticker ──────────────────────────────────────────────────
          if (showNoticeTicker && notices.activeNotices.isNotEmpty)
            NoticeBoardWidget(
              notices: notices.activeNotices,
              mode: NoticeBoardMode.ticker,
              lang: lang,
              onDismiss: (id) => ref.read(noticesProvider.notifier).dismissNotice(id),
            ),

          // ── Breadcrumbs ────────────────────────────────────────────────────
          if (effectiveBreadcrumbs.isNotEmpty)
            _BreadcrumbBar(breadcrumbs: effectiveBreadcrumbs),

          // ── Main Content Body ──────────────────────────────────────────────
          Expanded(child: body),

          // ── Footer ─────────────────────────────────────────────────────────
          const _PortalFooter(),
        ],
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
      color: AppColors.surfaceSunken,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          for (int i = 0; i < breadcrumbs.length; i++) ...[
            if (i > 0)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text('›', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ),
            GestureDetector(
              onTap: i < breadcrumbs.length - 1
                  ? () {
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
                  fontSize: 12,
                  color: i == breadcrumbs.length - 1 ? AppColors.forestCanopy : AppColors.textSecondary,
                  fontWeight: i == breadcrumbs.length - 1 ? FontWeight.w700 : FontWeight.w500,
                  decoration: i < breadcrumbs.length - 1 ? TextDecoration.underline : TextDecoration.none,
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
      color: AppColors.forestCanopy,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Text(
        context.tr('footer_text'),
        style: const TextStyle(
          fontFamily: 'NotoSansDevanagari',
          color: Color(0xDDFFFFFF),
          fontSize: 10,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
