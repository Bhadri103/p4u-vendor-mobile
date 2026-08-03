import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Prefer cached data over a full-screen spinner when providers reload.
extension AsyncValueUiX<T> on AsyncValue<T> {
  R whenUi<R>({
    required R Function(T data) data,
    required R Function(Object error, StackTrace stackTrace) error,
    required R Function() loading,
  }) {
    return when(
      skipLoadingOnReload: true,
      skipLoadingOnRefresh: true,
      data: data,
      error: error,
      loading: loading,
    );
  }
}
