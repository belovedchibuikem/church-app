import 'package:flutter/material.dart';

import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../fhc_nav.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FhcDevicePage(
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: () => fhcGo(context, '/language'),
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.chevron_left, size: 28),
              color: FhcColors.ink,
              tooltip: 'Back',
            ),
          ),
          const Text(
            'Welcome Back! 👋',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              height: 1.2,
              color: FhcColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sign in to continue your journey.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.35,
              color: FhcColors.muted,
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 34,
                    ),
                    child: const _SignInBody(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SignInBody extends StatelessWidget {
  const _SignInBody();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _AuthTabs(),
        const SizedBox(height: 22),
        const FhcField(
          label: 'Email or Phone Number',
          hint: 'you@example.com',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        const FhcField(
          label: 'Password',
          hint: 'Enter your password',
          suffixIcon: Icons.visibility_outlined,
          obscureText: true,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              foregroundColor: FhcColors.green,
              padding: const EdgeInsets.symmetric(vertical: 4),
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Forgot Password?',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 6),
        FhcPrimaryButton(
          label: 'Sign In',
          onPressed: () => fhcGo(context, '/verify-phone'),
        ),
        const SizedBox(height: 20),
        const _OrContinueDivider(),
        const SizedBox(height: 14),
        const _SocialButton(
          label: 'Continue with Google',
          leading: _GoogleMark(),
        ),
        const SizedBox(height: 10),
        const _SocialButton(
          label: 'Continue with Apple',
          leading: _AppleMark(),
        ),
      ],
    );
  }
}

class _AuthTabs extends StatelessWidget {
  const _AuthTabs();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: FhcColors.border)),
      ),
      child: Row(
        children: [
          Expanded(child: _TabItem(label: 'Sign In', active: true)),
          Expanded(child: _TabItem(label: 'Create Account', active: false)),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: active ? FontWeight.w700 : FontWeight.w600,
              color: active ? FhcColors.green : FhcColors.muted,
            ),
          ),
        ),
        Container(
          height: 2,
          color: active ? FhcColors.green : Colors.transparent,
        ),
      ],
    );
  }
}

class _OrContinueDivider extends StatelessWidget {
  const _OrContinueDivider();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider(color: FhcColors.border, height: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            'or continue with',
            style: TextStyle(fontSize: 11, color: FhcColors.muted),
          ),
        ),
        Expanded(child: Divider(color: FhcColors.border, height: 1)),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({required this.label, required this.leading});

  final String label;
  final Widget leading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          foregroundColor: FhcColors.ink,
          side: const BorderSide(color: FhcColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(FhcRadius.sm),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            leading,
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                color: FhcColors.ink,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 18,
      child: Text(
        'G',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: FhcColors.red,
          fontSize: 18,
          height: 1,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AppleMark extends StatelessWidget {
  const _AppleMark();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 18,
      height: 18,
      child: CustomPaint(painter: _AppleMarkPainter()),
    );
  }
}

class _AppleMarkPainter extends CustomPainter {
  const _AppleMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = const Color(0xFF111111)
          ..style = PaintingStyle.fill;
    final w = size.width;
    final h = size.height;

    final leaf =
        Path()
          ..moveTo(w * 0.50, h * 0.22)
          ..cubicTo(w * 0.58, h * -0.02, w * 0.86, h * 0.04, w * 0.68, h * 0.28)
          ..cubicTo(w * 0.58, h * 0.32, w * 0.50, h * 0.28, w * 0.50, h * 0.22);
    canvas.drawPath(leaf, paint);

    final body =
        Path()
          ..moveTo(w * 0.50, h * 0.28)
          ..cubicTo(w * 0.36, h * 0.28, w * 0.08, h * 0.40, w * 0.10, h * 0.66)
          ..cubicTo(w * 0.12, h * 0.92, w * 0.34, h * 1.04, w * 0.50, h * 0.88)
          ..cubicTo(w * 0.66, h * 1.04, w * 0.88, h * 0.92, w * 0.90, h * 0.66)
          ..cubicTo(w * 0.92, h * 0.40, w * 0.64, h * 0.28, w * 0.50, h * 0.28)
          ..close();
    final bite =
        Path()..addOval(
          Rect.fromCircle(center: Offset(w * 0.94, h * 0.42), radius: w * 0.15),
        );
    canvas.drawPath(Path.combine(PathOperation.difference, body, bite), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
