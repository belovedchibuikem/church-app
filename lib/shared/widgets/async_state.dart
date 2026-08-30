import 'package:flutter/material.dart';

import '../../core/api/app_failure.dart';
import '../../core/design_system/fhc_tokens.dart';
import '../../core/l10n/locale_scope.dart';
import 'fhc_components.dart';

/// Lightweight async snapshot used by feature screens before a full state
/// management library is approved.
sealed class FhcAsyncValue<T> {
  const FhcAsyncValue();

  const factory FhcAsyncValue.loading() = FhcAsyncLoading<T>;
  const factory FhcAsyncValue.data(T value) = FhcAsyncData<T>;
  const factory FhcAsyncValue.error(AppFailure failure) = FhcAsyncError<T>;
  const factory FhcAsyncValue.empty({String? message}) = FhcAsyncEmpty<T>;
  const factory FhcAsyncValue.unavailable({String? message}) =
      FhcAsyncUnavailable<T>;
}

final class FhcAsyncLoading<T> extends FhcAsyncValue<T> {
  const FhcAsyncLoading();
}

final class FhcAsyncData<T> extends FhcAsyncValue<T> {
  const FhcAsyncData(this.value);
  final T value;
}

final class FhcAsyncError<T> extends FhcAsyncValue<T> {
  const FhcAsyncError(this.failure);
  final AppFailure failure;
}

final class FhcAsyncEmpty<T> extends FhcAsyncValue<T> {
  const FhcAsyncEmpty({this.message});
  final String? message;
}

final class FhcAsyncUnavailable<T> extends FhcAsyncValue<T> {
  const FhcAsyncUnavailable({this.message});
  final String? message;
}

/// Renders loading / error / empty / unavailable / data for [FhcAsyncValue].
class FhcAsyncBody<T> extends StatelessWidget {
  const FhcAsyncBody({
    super.key,
    required this.value,
    required this.builder,
    this.onRetry,
    this.emptyTitle,
    this.emptyMessage,
    this.unavailableTitle,
    this.unavailableMessage,
  });

  final FhcAsyncValue<T> value;
  final Widget Function(BuildContext context, T data) builder;
  final VoidCallback? onRetry;
  final String? emptyTitle;
  final String? emptyMessage;
  final String? unavailableTitle;
  final String? unavailableMessage;

  @override
  Widget build(BuildContext context) {
    return switch (value) {
      FhcAsyncLoading<T>() => const FhcLoadingState(),
      FhcAsyncData<T>(:final value) => builder(context, value),
      FhcAsyncEmpty<T>(:final message) => FhcEmptyState(
        title:
            emptyTitle ??
            fhcT(
              context,
              'errors.nothingHereYet',
              fallback: 'Nothing here yet',
            ),
        message:
            message ??
            emptyMessage ??
            fhcT(
              context,
              'errors.checkBackSoon',
              fallback: 'Check back soon.',
            ),
      ),
      FhcAsyncUnavailable<T>(:final message) => FhcUnavailableState(
        title:
            unavailableTitle ??
            fhcT(
              context,
              'errors.notAvailableYet',
              fallback: 'Not available yet',
            ),
        message:
            message ??
            unavailableMessage ??
            fhcT(
              context,
              'errors.featureWaitingOnApi',
              fallback:
                  'This feature is waiting on its Laravel API contract. '
                  'No live data is shown.',
            ),
      ),
      FhcAsyncError<T>(:final failure) => FhcErrorState(
        title: fhcT(
          context,
          'errors.somethingWentWrong',
          fallback: 'Something went wrong',
        ),
        message: failure.message,
        onRetry: onRetry,
      ),
    };
  }
}

class FhcLoadingState extends StatelessWidget {
  const FhcLoadingState({super.key, this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    final resolved =
        label ?? fhcT(context, 'common.loading', fallback: 'Loading…');
    return Center(
      child: Semantics(
        liveRegion: true,
        label: resolved,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator.adaptive(),
            const SizedBox(height: 14),
            Text(resolved, style: FhcTypography.caption),
          ],
        ),
      ),
    );
  }
}

class FhcUnavailableState extends StatelessWidget {
  const FhcUnavailableState({
    super.key,
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return FhcEmptyState(
      icon: Icons.cloud_off_outlined,
      title: title,
      message: message,
    );
  }
}

/// Full-page honest unavailable surface for unbound payment / prayer /
/// messaging (and similar) domains.
class FhcFeatureUnavailablePage extends StatelessWidget {
  const FhcFeatureUnavailablePage({
    super.key,
    required this.feature,
    this.detail,
    this.onBack,
  });

  final String feature;
  final String? detail;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return FhcDevicePage(
      backgroundColor: FhcColors.white,
      child: Column(
        children: [
          FhcTopBar(
            title: feature,
            onBack:
                onBack ??
                () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                },
          ),
          Expanded(
            child: FhcUnavailableState(
              title: fhcT(
                context,
                'errors.featureNotConnected',
                args: {'feature': feature},
                fallback: '$feature is not connected',
              ),
              message:
                  detail ??
                  fhcT(
                    context,
                    'errors.featureNotBound',
                    args: {'feature': feature},
                    fallback:
                        'Family House Connect has not bound a live Laravel API for '
                        '$feature in this build. Fixture success states are '
                        'disabled so the app does not pretend a backend exists.',
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
