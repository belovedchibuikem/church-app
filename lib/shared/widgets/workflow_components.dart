import 'package:flutter/material.dart';

import '../../core/design_system/fhc_tokens.dart';
import '../../core/l10n/locale_scope.dart';
import '../../features/foundation/presentation/fhc_nav.dart';
import 'fhc_components.dart';

enum WorkflowDomain {
  church,
  mission,
  kca,
  press,
  journey,
  community,
  more,
  utility,
}

class WorkflowPage extends StatelessWidget {
  const WorkflowPage({
    super.key,
    required this.title,
    required this.children,
    required this.domain,
    this.actionLabel,
    this.onAction,
    this.trailing,
    this.showBack = true,
    this.backIcon = Icons.chevron_left,
    this.backTooltip,
    this.trailingWidth = 112,
    this.backgroundColor = FhcColors.white,
  });

  final String title;
  final List<Widget> children;
  final WorkflowDomain domain;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? trailing;
  final bool showBack;
  final IconData backIcon;
  final String? backTooltip;
  final double trailingWidth;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    void back() {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        fhcGo(context, FhcRoutes.hub);
      }
    }

    void acknowledgeAction() {
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              fhcT(
                context,
                'errors.actionRequiresLaravel',
                args: {'action': actionLabel ?? ''},
                fallback:
                    '$actionLabel requires the platform integration and is not available in this build.',
              ),
            ),
          ),
        );
    }

    return FhcDevicePage(
      backgroundColor: backgroundColor,
      child: Column(
        children: [
          FhcTopBar(
            title: title,
            onBack: showBack ? back : null,
            trailing: trailing,
            backIcon: backIcon,
            backTooltip: backTooltip,
            trailingWidth: trailingWidth,
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                FhcSpacing.md,
                FhcSpacing.xs,
                FhcSpacing.md,
                actionLabel == null ? FhcSpacing.md : FhcSpacing.xs,
              ),
              children: children,
            ),
          ),
          if (actionLabel != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: FhcPrimaryButton(
                label: actionLabel!,
                onPressed: onAction ?? acknowledgeAction,
              ),
            ),
          WorkflowBottomNav(domain: domain),
        ],
      ),
    );
  }
}

class WorkflowBottomNav extends StatelessWidget {
  const WorkflowBottomNav({super.key, required this.domain});

  final WorkflowDomain domain;

  List<(IconData, String, String)> _items(BuildContext context) {
    String t(String key, String fallback) =>
        fhcT(context, key, fallback: fallback);
    return switch (domain) {
      WorkflowDomain.church => [
        (Icons.home_outlined, t('nav.home', 'Home'), FhcRoutes.hub),
        (Icons.church_outlined, t('nav.church', 'Church'), FhcRoutes.churchHome),
        (Icons.public_outlined, t('nav.mission', 'Mission'), FhcRoutes.mission),
        (
          Icons.volunteer_activism_outlined,
          t('nav.give', 'Give'),
          FhcRoutes.give,
        ),
        (Icons.more_horiz, t('common.more', 'More'), FhcRoutes.profile),
      ],
      WorkflowDomain.mission => [
        (Icons.home_outlined, t('nav.home', 'Home'), FhcRoutes.hub),
        (Icons.church_outlined, t('nav.church', 'Church'), FhcRoutes.churchHome),
        (Icons.public_outlined, t('nav.mission', 'Mission'), FhcRoutes.mission),
        (Icons.school_outlined, t('nav.kca', 'KCA'), FhcRoutes.kca),
        (Icons.more_horiz, t('common.more', 'More'), FhcRoutes.profile),
      ],
      WorkflowDomain.kca => [
        (Icons.home_outlined, t('nav.home', 'Home'), FhcRoutes.hub),
        (Icons.school_outlined, t('nav.kca', 'KCA'), FhcRoutes.kca),
        (Icons.menu_book_outlined, t('nav.learn', 'Learn'), FhcRoutes.kcaModules),
        (Icons.hub_outlined, t('nav.network', 'Network'), FhcRoutes.kcaMentor),
        (Icons.more_horiz, t('common.more', 'More'), FhcRoutes.profile),
      ],
      WorkflowDomain.press => [
        (Icons.home_outlined, t('nav.home', 'Home'), FhcRoutes.hub),
        (Icons.newspaper_outlined, t('nav.press', 'Press'), FhcRoutes.press),
        (
          Icons.local_library_outlined,
          t('nav.library', 'Library'),
          FhcRoutes.pressCategories,
        ),
        (
          Icons.storefront_outlined,
          t('nav.store', 'Store'),
          FhcRoutes.pressBook,
        ),
        (Icons.more_horiz, t('common.more', 'More'), FhcRoutes.profile),
      ],
      WorkflowDomain.journey => [
        (Icons.home_outlined, t('nav.home', 'Home'), FhcRoutes.hub),
        (Icons.route_outlined, t('nav.journey', 'Journey'), '/journey'),
        (
          Icons.groups_outlined,
          t('nav.community', 'Community'),
          FhcRoutes.groups,
        ),
        (
          Icons.menu_book_outlined,
          t('nav.resources', 'Resources'),
          FhcRoutes.press,
        ),
        (
          Icons.person_outline,
          t('common.profile', 'Profile'),
          FhcRoutes.profile,
        ),
      ],
      WorkflowDomain.community => [
        (Icons.home_outlined, t('nav.home', 'Home'), FhcRoutes.hub),
        (
          Icons.grid_view_outlined,
          t('nav.modules', 'Modules'),
          FhcRoutes.modules,
        ),
        (
          Icons.explore_outlined,
          t('nav.discover', 'Discover'),
          FhcRoutes.discover,
        ),
        (
          Icons.chat_bubble_outline,
          t('common.messages', 'Messages'),
          FhcRoutes.messages,
        ),
        (
          Icons.person_outline,
          t('common.profile', 'Profile'),
          FhcRoutes.profile,
        ),
      ],
      WorkflowDomain.more => [
        (Icons.home_outlined, t('nav.home', 'Home'), FhcRoutes.hub),
        (Icons.church_outlined, t('nav.church', 'Church'), FhcRoutes.churchHome),
        (Icons.public_outlined, t('nav.mission', 'Mission'), FhcRoutes.mission),
        (
          Icons.volunteer_activism_outlined,
          t('nav.give', 'Give'),
          FhcRoutes.give,
        ),
        (Icons.more_horiz, t('common.more', 'More'), FhcRoutes.profile),
      ],
      WorkflowDomain.utility => [
        (Icons.home_outlined, t('nav.home', 'Home'), FhcRoutes.hub),
        (Icons.church_outlined, t('nav.church', 'Church'), FhcRoutes.churchHome),
        (Icons.public_outlined, t('nav.mission', 'Mission'), FhcRoutes.mission),
        (Icons.school_outlined, t('nav.kca', 'KCA'), FhcRoutes.kca),
        (Icons.newspaper_outlined, t('nav.press', 'Press'), FhcRoutes.press),
        (Icons.more_horiz, t('common.more', 'More'), FhcRoutes.profile),
      ],
    };
  }

  int get selected => switch (domain) {
    WorkflowDomain.church => 1,
    WorkflowDomain.mission => 2,
    WorkflowDomain.kca => 1,
    WorkflowDomain.press => 1,
    WorkflowDomain.journey => 1,
    WorkflowDomain.community || WorkflowDomain.more => 4,
    WorkflowDomain.utility => 5,
  };

  @override
  Widget build(BuildContext context) {
    final items = _items(context);
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: FhcColors.white,
        border: Border(top: BorderSide(color: FhcColors.border)),
      ),
      child: Row(
        children: [
          for (var index = 0; index < items.length; index++)
            Expanded(
              child: InkWell(
                onTap: () => fhcGo(context, items[index].$3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      items[index].$1,
                      size: 21,
                      color:
                          selected == index ? FhcColors.green : FhcColors.muted,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      items[index].$2,
                      style: TextStyle(
                        fontFamily: 'FhcRoboto',
                        fontSize: 9,
                        fontWeight:
                            selected == index
                                ? FontWeight.w700
                                : FontWeight.w500,
                        color:
                            selected == index
                                ? FhcColors.green
                                : FhcColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class WorkflowSectionTitle extends StatelessWidget {
  const WorkflowSectionTitle(this.title, {super.key, this.action});

  final String title;
  final String? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 9),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
          if (action != null)
            Text(
              action!,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: FhcColors.green,
              ),
            ),
        ],
      ),
    );
  }
}

class WorkflowSummary extends StatelessWidget {
  const WorkflowSummary({
    super.key,
    required this.title,
    required this.metrics,
    this.subtitle,
    this.color = FhcColors.greenDark,
    this.imageAsset,
  });

  final String title;
  final String? subtitle;
  final List<(String, String)> metrics;
  final Color color;
  final String? imageAsset;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(FhcRadius.card),
        image:
            imageAsset == null
                ? null
                : DecorationImage(
                  image: AssetImage(imageAsset!),
                  fit: BoxFit.cover,
                  colorFilter: const ColorFilter.mode(
                    Color(0x66000000),
                    BlendMode.darken,
                  ),
                ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              height: 1.2,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 5),
            Text(
              subtitle!,
              style: const TextStyle(fontSize: 11, color: Colors.white),
            ),
          ],
          if (metrics.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                for (var index = 0; index < metrics.length; index++) ...[
                  if (index > 0)
                    const SizedBox(
                      height: 38,
                      child: VerticalDivider(color: Color(0x66FFFFFF)),
                    ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          metrics[index].$1,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          metrics[index].$2,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 9,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class WorkflowCard extends StatelessWidget {
  const WorkflowCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.color = Colors.white,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(FhcRadius.card),
        border: Border.all(color: FhcColors.border),
      ),
      child: child,
    );
  }
}

class WorkflowRow extends StatelessWidget {
  const WorkflowRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading = Icons.check_circle_outline,
    this.trailing,
    this.onTap,
    this.accent = FhcColors.green,
  });

  final String title;
  final String? subtitle;
  final IconData leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: .10),
                  shape: BoxShape.circle,
                ),
                child: Icon(leading, size: 18, color: accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: FhcTypography.caption,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailing ??
                  const Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: FhcColors.hint,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class WorkflowPill extends StatelessWidget {
  const WorkflowPill(this.label, {super.key, this.color = FhcColors.green});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class WorkflowSegments extends StatefulWidget {
  const WorkflowSegments({
    super.key,
    required this.labels,
    this.selected = 0,
    this.onSelected,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int>? onSelected;

  @override
  State<WorkflowSegments> createState() => _WorkflowSegmentsState();
}

class _WorkflowSegmentsState extends State<WorkflowSegments> {
  late int selected = widget.selected;

  @override
  void didUpdateWidget(covariant WorkflowSegments oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected) selected = widget.selected;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: FhcColors.canvas,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          for (var index = 0; index < widget.labels.length; index++)
            Expanded(
              child: Semantics(
                button: true,
                selected: selected == index,
                child: InkWell(
                  onTap: () {
                    setState(() => selected = index);
                    widget.onSelected?.call(index);
                  },
                  borderRadius: BorderRadius.circular(7),
                  child: Container(
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color:
                          selected == index
                              ? FhcColors.green
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      widget.labels[index],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: selected == index ? Colors.white : FhcColors.ink,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class WorkflowField extends StatelessWidget {
  const WorkflowField({
    super.key,
    required this.label,
    required this.value,
    this.lines = 1,
    this.required = false,
    this.icon,
  });

  final String label;
  final String value;
  final int lines;
  final bool required;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              text: label,
              style: FhcTypography.label,
              children: [
                if (required)
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(color: FhcColors.red),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Container(
            constraints: BoxConstraints(minHeight: lines == 1 ? 44 : 84),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: FhcColors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    value,
                    maxLines: lines,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          value.startsWith('Select') || value.startsWith('Tell')
                              ? FhcColors.hint
                              : FhcColors.ink,
                    ),
                  ),
                ),
                if (icon != null) Icon(icon, size: 17, color: FhcColors.muted),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Editable counterpart to [WorkflowField] for live enrolment / forms.
class WorkflowTextField extends StatelessWidget {
  const WorkflowTextField({
    super.key,
    required this.label,
    required this.controller,
    this.lines = 1,
    this.required = false,
    this.icon,
    this.hint,
    this.keyboardType,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final int lines;
  final bool required;
  final IconData? icon;
  final String? hint;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              text: label,
              style: FhcTypography.label,
              children: [
                if (required)
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(color: FhcColors.red),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            maxLines: lines,
            minLines: lines > 1 ? lines : 1,
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 12, color: FhcColors.ink),
            validator: validator ??
                (required
                    ? (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        return null;
                      }
                    : null),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(fontSize: 12, color: FhcColors.hint),
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              suffixIcon: icon == null
                  ? null
                  : Icon(icon, size: 17, color: FhcColors.muted),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 11,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: FhcColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: FhcColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: FhcColors.green, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: FhcColors.red),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WorkflowUploadBox extends StatelessWidget {
  const WorkflowUploadBox({super.key, this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: FhcColors.canvas,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: FhcColors.muted, style: BorderStyle.solid),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.cloud_upload_outlined,
            size: 42,
            color: FhcColors.green,
          ),
          const SizedBox(height: 9),
          Text(
            label ??
                fhcT(
                  context,
                  'common.uploadHint',
                  fallback: 'Tap to upload or drag files here',
                ),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 5),
          Text(
            fhcT(
              context,
              'common.uploadTypes',
              fallback: 'Photos, videos or documents (Max 10MB each)',
            ),
            style: FhcTypography.caption,
          ),
        ],
      ),
    );
  }
}

class WorkflowProgress extends StatelessWidget {
  const WorkflowProgress({
    super.key,
    required this.label,
    required this.value,
    this.trailing,
  });

  final String label;
  final double value;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                trailing ?? '${(value * 100).round()}%',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 6,
              backgroundColor: FhcColors.border,
              valueColor: const AlwaysStoppedAnimation(FhcColors.green),
            ),
          ),
        ],
      ),
    );
  }
}
