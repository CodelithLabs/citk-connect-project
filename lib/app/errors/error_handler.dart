import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'error_handler.g.dart';

class ErrorHandler {
  void handleException(Object error) {
    // Handle the error, e.g., log it or show a user-friendly message.
  }
}

@riverpod
ErrorHandler errorHandler(Ref ref) {
  return ErrorHandler();
}
