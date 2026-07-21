import 'package:flutter/material.dart';

/// Displays the trilingual EN / हिंदी / मराठी summary of a Gram Sabha resolution.
///
/// In EDIT mode (review screen): each tab is a [TextFormField] with amber AI banner.
/// In VIEW mode (MoM viewer): each tab shows read-only [SelectableText].
///
/// The ⚠️ AI-Generated banner is shown per-tab and cannot be hidden —
/// it drives the mandatory Secretary review requirement (§5.2).
class TrilingualSummaryTabs extends StatefulWidget {
  final String textEn;
  final String textHi;
  final String textMr;
  final bool isEditable;

  /// Callbacks for edit mode (null in view mode)
  final ValueChanged<String>? onEnChanged;
  final ValueChanged<String>? onHiChanged;
  final ValueChanged<String>? onMrChanged;

  /// Whether translations are ready (false = models still downloading)
  final bool isTranslationReady;

  const TrilingualSummaryTabs({
    super.key,
    required this.textEn,
    required this.textHi,
    required this.textMr,
    this.isEditable = false,
    this.onEnChanged,
    this.onHiChanged,
    this.onMrChanged,
    this.isTranslationReady = true,
  });

  @override
  State<TrilingualSummaryTabs> createState() => _TrilingualSummaryTabsState();
}

class _TrilingualSummaryTabsState extends State<TrilingualSummaryTabs>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tab bar
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: Colors.white,
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            tabs: const [
              Tab(text: 'English'),
              Tab(text: 'हिंदी'),
              Tab(text: 'मराठी'),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Tab views
        SizedBox(
          height: widget.isEditable ? 200 : 140,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildTabContent(
                text: widget.textEn,
                hint: 'English summary will appear here after translation…',
                onChanged: widget.onEnChanged,
              ),
              _buildTabContent(
                text: widget.textHi,
                hint: 'हिंदी सारांश अनुवाद के बाद यहाँ दिखाई देगा…',
                onChanged: widget.onHiChanged,
                fontFamily: 'NotoSansDevanagari',
              ),
              _buildTabContent(
                text: widget.textMr,
                hint: 'मराठी सारांश भाषांतरानंतर येथे दिसेल…',
                onChanged: widget.onMrChanged,
                fontFamily: 'NotoSansDevanagari',
              ),
            ],
          ),
        ),

        // AI-generated review banner — always shown in edit mode
        if (widget.isEditable) ...[
          const SizedBox(height: 8),
          _AiReviewBanner(isReady: widget.isTranslationReady),
        ],
      ],
    );
  }

  Widget _buildTabContent({
    required String text,
    required String hint,
    ValueChanged<String>? onChanged,
    String? fontFamily,
  }) {
    final textStyle = fontFamily != null
        ? TextStyle(fontFamily: fontFamily, fontSize: 14, height: 1.6)
        : const TextStyle(fontSize: 14, height: 1.6);

    if (widget.isEditable && onChanged != null) {
      return TextFormField(
        initialValue: text,
        onChanged: onChanged,
        maxLines: null,
        expands: true,
        style: textStyle,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
            ),
          ),
          contentPadding: const EdgeInsets.all(12),
        ),
        textAlignVertical: TextAlignVertical.top,
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        child: SelectableText(
          text.isEmpty ? '—' : text,
          style: textStyle,
        ),
      ),
    );
  }
}

class _AiReviewBanner extends StatelessWidget {
  final bool isReady;

  const _AiReviewBanner({required this.isReady});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF57F17).withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, size: 16, color: Color(0xFFF57F17)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isReady
                  ? '⚠️ AI-Generated — Please review each tab before confirming'
                  : '⏳ Translation in progress — models downloading on first run',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFF57F17),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
