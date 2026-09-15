import 'dart:async';

/// A lifecycle outcome, not a user-facing network failure.
class RequestCancelled implements Exception {
  const RequestCancelled();
}

/// Scoped to one owner; only read transports consume this context.
/// Zones carry it through repositories without changing their public contracts.
class ReadCancellation {
  static final Object _zoneKey = Object();
  static ReadCancellation? get current =>
      Zone.current[_zoneKey] as ReadCancellation?;
  final _signal = Completer<void>();
  bool get isCancelled => _signal.isCompleted;
  Future<void> get whenCancelled => _signal.future;

  void cancel() {
    if (!isCancelled) _signal.complete();
  }

  void throwIfCancelled() {
    if (isCancelled) throw const RequestCancelled();
  }

  Future<T> run<T>(Future<T> Function() action) =>
      runZoned(action, zoneValues: {_zoneKey: this});

  // Interrupts a local wait (backoff/shared refresh), not a transport. HTTP
  // cancellation itself must use AbortableRequest and await its termination.
  Future<T> wait<T>(Future<T> operation) async {
    throwIfCancelled();
    return Future.any([
      operation,
      whenCancelled.then<T>((_) => throw const RequestCancelled()),
    ]);
  }
}
