import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/design_system/fhc_tokens.dart';
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
  const FhcTopBar({super.key, required this.title, this.onBack, this.trailing});

  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;

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
                      icon: const Icon(Icons.chevron_left, size: 28),
                      color: FhcColors.ink,
                      tooltip: 'Back',
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
            width: trailing == null ? FhcSizes.minTap : 112,
            child: Align(
              alignment: Alignment.centerRight,
              child: trailing,
            ),
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

class FhcField extends StatelessWidget {
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
  });

  final String label;
  final String hint;
  final IconData? suffixIcon;
  final IconData? prefixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(FhcRadius.field);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: FhcTypography.label),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: FhcTypography.body,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: FhcTypography.hint,
            prefixIcon:
                prefixIcon == null
                    ? null
                    : Icon(prefixIcon, size: 18, color: FhcColors.muted),
            suffixIcon:
                suffixIcon == null
                    ? null
                    : Icon(suffixIcon, size: 18, color: FhcColors.muted),
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
  });

  final int selected;
  final ValueChanged<int>? onSelected;

  static const _items = <(IconData, IconData, String)>[
    (Icons.home_outlined, Icons.home, 'Home'),
    (Icons.grid_view_outlined, Icons.grid_view, 'Modules'),
    (Icons.explore_outlined, Icons.explore, 'Discover'),
    (Icons.chat_bubble_outline, Icons.chat_bubble, 'Messages'),
    (Icons.person_outline, Icons.person, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
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
                label: _items[i].$3,
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
                          if (i == 3)
                            const Positioned(
                              right: -6,
                              top: -4,
                              child: _MessageBadge(),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      ExcludeSemantics(
                        child: Text(
                          _items[i].$3,
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
  const _MessageBadge();

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
        child: const Text(
          '3',
          style: TextStyle(
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
