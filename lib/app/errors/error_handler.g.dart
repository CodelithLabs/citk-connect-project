// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'error_handler.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(errorHandler)
const errorHandlerProvider = ErrorHandlerProvider._();

final class ErrorHandlerProvider
    extends $FunctionalProvider<ErrorHandler, ErrorHandler, ErrorHandler>
    with $Provider<ErrorHandler> {
  const ErrorHandlerProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'errorHandlerProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$errorHandlerHash();

  @$internal
  @override
  $ProviderElement<ErrorHandler> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ErrorHandler create(Ref ref) {
    return errorHandler(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ErrorHandler value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ErrorHandler>(value),
    );
  }
}

String _$errorHandlerHash() => r'4028babe128b1f027c3f48b6a6faa19a37a48418';
