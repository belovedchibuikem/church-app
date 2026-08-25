import 'package:flutter/material.dart';

import '../../../../core/design_system/fhc_tokens.dart';
import '../../../../shared/widgets/fhc_components.dart';
import '../fhc_nav.dart';

class VerifyPhoneScreen extends StatelessWidget {
  const VerifyPhoneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FhcDevicePage(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final h = constraints.maxHeight;
          final compact = h < 760;
          final artMax = compact ? 188.0 : 250.0;

          return Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => fhcGo(context, '/sign-in'),
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.chevron_left, size: 28),
                  color: FhcColors.ink,
                  tooltip: 'Back',
                ),
              ),
              const Text(
                'Verify Your Phone',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  color: FhcColors.ink,
                ),
              ),
              SizedBox(height: compact ? 8 : 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 28),
                child: Text(
                  'Enter the 6-digit code we sent to',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: FhcColors.muted,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '+234 802 123 4567',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: FhcColors.ink,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 36,
                    vertical: compact ? 8 : 16,
                  ),
                  child: Align(
                    alignment: const Alignment(0, 0.45),
                    child: SizedBox(
                      height: artMax,
                      width: 260,
                      child: const ExcludeSemantics(child: _OtpIllustration()),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Semantics(
                  button: true,
                  label: 'Continue with code 123456',
                  child: InkWell(
                    onTap: () => fhcGo(context, '/2fa'),
                    borderRadius: BorderRadius.circular(FhcRadius.sm),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: _OtpRow(),
                    ),
                  ),
                ),
              ),
              SizedBox(height: compact ? 14 : 20),
              const Text(
                "Didn't receive code? Resend in 00:45",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: FhcColors.muted,
                ),
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: FhcColors.green,
                  minimumSize: const Size(88, 40),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Change Phone Number',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
              SizedBox(height: compact ? 10 : 18),
            ],
          );
        },
      ),
    );
  }
}

class _OtpIllustration extends StatelessWidget {
  const _OtpIllustration();

  static const _asset = 'assets/images/otp_security.png';

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      _asset,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => const _OtpArtFallback(),
    );
  }
}

class _OtpArtFallback extends StatelessWidget {
  const _OtpArtFallback();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 118,
            height: 188,
            decoration: BoxDecoration(
              color: FhcColors.mint,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: FhcColors.green, width: 7),
            ),
            child: const Center(
              child: Icon(Icons.shield, size: 78, color: FhcColors.green),
            ),
          ),
          const Positioned(
            right: 18,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(16)),
                boxShadow: FhcElevation.card,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Text(
                  '******',
                  style: TextStyle(
                    fontSize: 13,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w700,
                    color: FhcColors.ink,
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

class _OtpRow extends StatelessWidget {
  const _OtpRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        _OtpBox('1'),
        SizedBox(width: 8),
        _OtpBox('2'),
        SizedBox(width: 8),
        _OtpBox('3'),
        SizedBox(width: 8),
        _OtpBox('4'),
        SizedBox(width: 8),
        _OtpBox('5'),
        SizedBox(width: 8),
        _OtpBox('6'),
      ],
    );
  }
}

class _OtpBox extends StatelessWidget {
  const _OtpBox(this.digit);

  final String digit;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AspectRatio(
        aspectRatio: 0.92,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: FhcColors.white,
            borderRadius: BorderRadius.circular(FhcRadius.sm),
            border: Border.all(color: FhcColors.border),
          ),
          child: Center(
            child: Text(
              digit,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                height: 1,
                color: FhcColors.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
