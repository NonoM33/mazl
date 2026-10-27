import '../../../../core/services/couple_api_service.dart';

/// Where one section of « Nous deux » stands. Each section loads on its own:
/// one that fails never wipes the others.
sealed class UsLoad<T> {
  const UsLoad();

  /// The value, when there is one.
  T? get valueOrNull => switch (this) {
    UsReady<T>(:final value) => value,
    _ => null,
  };
}

class UsLoading<T> extends UsLoad<T> {
  const UsLoading();
}

class UsReady<T> extends UsLoad<T> {
  const UsReady(this.value);
  final T value;
}

class UsFailed<T> extends UsLoad<T> {
  const UsFailed(this.failure);
  final CoupleFailure failure;
}
