import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'error_handler.g.dart';

class ErrorHandler {
  void handleException(Object error) {
    // Handle the error, e.g., log it or show a user-friendly message.
  }
}

@riverpod
ErrorHandler errorHandler(ErrorHandlerRef ref) {
  return ErrorHandler();
}
