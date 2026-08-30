import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/design_system/fhc_tokens.dart';
import '../../core/l10n/locale_scope.dart';
import '../../features/foundation/presentation/fhc_nav.dart';

class FhcDevicePage extends StatelessWidget {
  const FhcDevicePage({
    super.key,
    required this.child,
    this.backgroundColor = FhcColors.white,
    this.darkStatusBar = false,
    this.statusBarColor,
  });

  final Widget child;
  final Color backgroundColor;
  final bool darkStatusBar;
  final Color? statusBarColor;

  @override
  Widget build(BuildContext context) {
    final overlayStyle = (darkStatusBar
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark)
        .copyWith(
          statusBarColor: statusBarColor ?? backgroundColor,
          systemNavigationBarColor: statusBarColor ?? backgroundColor,
          systemNavigationBarIconBrightness:
              darkStatusBar ? Brightness.light : Brightness.dark,
        );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        backgroundColor: statusBarColor ?? backgroundColor,
        body: SafeArea(
          child: ColoredBox(
            color: backgroundColor,
            child: MediaQuery.withClampedTextScaling(
              minScaleFactor: 1,
              maxScaleFactor: 1.15,
              child: SizedBox.expand(child: child),
            ),
          ),
        ),
      ),
    );
  }
}

class FhcTopBar extends StatelessWidget {
  const FhcTopBar({
    super.key,
    required this.title,
    this.onBack,
    this.trailing,
    this.backIcon = Icons.chevron_left,
    this.backTooltip,
    this.trailingWidth = 112,
  });

  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;
  final IconData backIcon;
  final String? backTooltip;
  final double trailingWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: FhcSizes.topBarHeight,
      child: Row(
        children: [
          SizedBox(
            width: FhcSizes.minTap,
            child:
                onBack == null
                    ? null
                    : IconButton(
                      onPressed: onBack,
                      padding: EdgeInsets.zero,
                      icon: Icon(backIcon, size: 28),
                      color: FhcColors.ink,
                      tooltip: backTooltip ??
                          fhcT(context, 'common.back', fallback: 'Back'),
                    ),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: FhcTypography.titleSmall,
            ),
          ),
          SizedBox(
            width: trailing == null ? FhcSizes.minTap : trailingWidth,
            child: Align(alignment: Alignment.centerRight, child: trailing),
          ),
        ],
      ),
    );
  }
}

class FhcPrimaryButton extends StatelessWidget {
  const FhcPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = FhcColors.green,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: FhcSizes.buttonHeight,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: FhcColors.white,
          disabledBackgroundColor: color.withValues(alpha: 0.45),
          disabledForegroundColor: FhcColors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(double.infinity, FhcSizes.buttonHeight),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(FhcRadius.button),
          ),
        ),
        child: Text(label, style: FhcTypography.button),
      ),
    );
  }
}

class FhcField extends StatefulWidget {
  const FhcField({
    super.key,
    required this.label,
    required this.hint,
    this.suffixIcon,
    this.prefixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.controller,
    this.onChanged,
    this.textInputAction,
    this.autofillHints,
  });

  final String label;
  final String hint;
  final IconData? suffixIcon;
  final IconData? prefixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;

  @override
  State<FhcField> createState() => _FhcFieldState();
}

class _FhcFieldState extends State<FhcField> {
  late bool _obscured = widget.obscureText;

  @override
  void didUpdateWidget(covariant FhcField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.obscureText != widget.obscureText) {
      _obscured = widget.obscureText;
    }
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(FhcRadius.field);
    final showToggle = widget.obscureText;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: FhcTypography.label),
        const SizedBox(height: 7),
        TextField(
          controller: widget.controller,
          obscureText: _obscured,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          autofillHints: widget.autofillHints,
          onChanged: widget.onChanged,
          style: FhcTypography.body,
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: FhcTypography.hint,
            prefixIcon:
                widget.prefixIcon == null
                    ? null
                    : Icon(widget.prefixIcon, size: 18, color: FhcColors.muted),
            suffixIcon:
                showToggle
                    ? IconButton(
                      tooltip: _obscured ? 'Show password' : 'Hide password',
                      onPressed: () => setState(() => _obscured = !_obscured),
                      icon: Icon(
                        _obscured
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 18,
                        color: FhcColors.muted,
                      ),
                    )
                    : widget.suffixIcon == null
                    ? null
                    : Icon(widget.suffixIcon, size: 18, color: FhcColors.muted),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderSide: const BorderSide(color: FhcColors.border),
              borderRadius: radius,
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: FhcColors.border),
              borderRadius: radius,
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: FhcColors.green, width: 1.5),
              borderRadius: radius,
            ),
          ),
        ),
      ],
    );
  }
}

class FhcBottomNavigation extends StatelessWidget {
  const FhcBottomNavigation({
    super.key,
    required this.selected,
    this.onSelected,
    this.messageBadgeCount,
  });

  final int selected;
  final ValueChanged<int>? onSelected;
  final int? messageBadgeCount;

  static const _items = <(IconData, IconData, String, String)>[
    (Icons.home_outlined, Icons.home, 'nav.home', 'Home'),
    (Icons.grid_view_outlined, Icons.grid_view, 'nav.modules', 'Modules'),
    (Icons.favorite_border, Icons.favorite, 'nav.give', 'Give'),
    (Icons.event_outlined, Icons.event, 'nav.events', 'Events'),
    (Icons.person_outline, Icons.person, 'common.profile', 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final labels = [
      for (final item in _items)
        fhcT(context, item.$3, fallback: item.$4),
    ];
    return Container(
      height: FhcSizes.bottomNavHeight,
      decoration: const BoxDecoration(
        color: FhcColors.white,
        border: Border(top: BorderSide(color: FhcColors.border)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < _items.length; i++)
            Expanded(
              child: Semantics(
                button: true,
                selected: i == selected,
                label: labels[i],
                excludeSemantics: true,
                child: InkWell(
                  onTap: () {
                    if (onSelected != null) {
                      onSelected!(i);
                    } else {
                      fhcTab(context, i);
                    }
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            i == selected ? _items[i].$2 : _items[i].$1,
                            size: FhcSizes.navIcon,
                            color:
                                i == selected
                                    ? FhcColors.green
                                    : FhcColors.muted,
                          ),
                          if (i == 3 && messageBadgeCount != null)
                            Positioned(
                              right: -6,
                              top: -4,
                              child: _MessageBadge(count: messageBadgeCount!),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      ExcludeSemantics(
                        child: Text(
                          labels[i],
                          style: FhcTypography.nav.copyWith(
                            color:
                                i == selected
                                    ? FhcColors.green
                                    : FhcColors.muted,
                            fontWeight:
                                i == selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MessageBadge extends StatelessWidget {
  const _MessageBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: 14,
        height: 14,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: FhcColors.red,
          shape: BoxShape.circle,
        ),
        child: Text(
          '$count',
          style: const TextStyle(
            fontSize: 8,
            height: 1,
            fontWeight: FontWeight.w700,
            color: FhcColors.white,
          ),
        ),
      ),
    );
  }
}

class FhcSurfaceCard extends StatelessWidget {
  const FhcSurfaceCard({
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
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(FhcRadius.card),
        border: Border.all(color: FhcColors.border),
        boxShadow: FhcElevation.card,
      ),
      child: child,
    );
  }
}

class FhcCircleIcon extends StatelessWidget {
  const FhcCircleIcon({
    super.key,
    required this.icon,
    this.color = FhcColors.green,
    this.size = 36,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: size * .52, color: color),
    );
  }
}

class FhcSectionLabel extends StatelessWidget {
  const FhcSectionLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          color: FhcColors.muted,
        ),
      ),
    );
  }
}

class FhcNotificationBell extends StatelessWidget {
  const FhcNotificationBell({
    super.key,
    required this.onTap,
    this.count = 0,
  });

  final VoidCallback onTap;
  final int count;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(
        minWidth: FhcSizes.minTap,
        minHeight: FhcSizes.minTap,
      ),
      tooltip: 'Notifications',
      icon: SizedBox(
        width: 28,
        height: 28,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            const Icon(
              Icons.notifications_none,
              size: 22,
              color: FhcColors.ink,
            ),
            if (count > 0)
              Positioned(
                right: -2,
                top: 0,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: FhcColors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    count > 9 ? '9+' : '$count',
                    style: const TextStyle(
                      color: FhcColors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class FhcMenuTile extends StatelessWidget {
  const FhcMenuTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.accent = FhcColors.green,
    this.showDivider = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color accent;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          button: true,
          label: '$title. $subtitle',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: FhcSizes.minTap),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      FhcCircleIcon(icon: icon, color: accent, size: 40),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                                color: FhcColors.ink,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                height: 1.25,
                                color: FhcColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: FhcColors.hint,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            thickness: 1,
            indent: 66,
            color: FhcColors.border,
          ),
      ],
    );
  }
}

class FhcMenuGroup extends StatelessWidget {
  const FhcMenuGroup({
    super.key,
    required this.children,
    this.title,
  });

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) FhcSectionLabel(title!),
        FhcSurfaceCard(
          padding: EdgeInsets.zero,
          child: Column(children: children),
        ),
      ],
    );
  }
}

class FhcMetricCard extends StatelessWidget {
  const FhcMetricCard({
    super.key,
    required this.label,
    required this.value,
    this.note,
    this.noteColor = FhcColors.muted,
  });

  final String label;
  final String value;
  final String? note;
  final Color noteColor;

  @override
  Widget build(BuildContext context) {
    return FhcSurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 9,
              color: FhcColors.muted,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: FhcColors.ink,
                height: 1.1,
              ),
            ),
          ),
          if (note != null) ...[
            const SizedBox(height: 5),
            Text(
              note!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 8,
                color: noteColor,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class FhcEmptyState extends StatelessWidget {
  const FhcEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FhcCircleIcon(icon: icon, size: 56),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: FhcTypography.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: FhcTypography.caption.copyWith(fontSize: 13, height: 1.4),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              SizedBox(
                width: 180,
                child: FhcPrimaryButton(label: actionLabel!, onPressed: onAction),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class FhcErrorState extends StatelessWidget {
  const FhcErrorState({
    super.key,
    required this.title,
    required this.message,
    this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return FhcEmptyState(
      icon: Icons.error_outline,
      title: title,
      message: message,
      actionLabel: onRetry == null
          ? null
          : fhcT(context, 'common.retry', fallback: 'Try Again'),
      onAction: onRetry,
    );
  }
}

class FhcStatusBadge extends StatelessWidget {
  const FhcStatusBadge(
    this.label, {
    super.key,
    this.color = FhcColors.green,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          height: 1.1,
        ),
      ),
    );
  }
}
