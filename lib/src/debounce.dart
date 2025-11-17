import 'dart:async';

/// A utility class for debouncing function calls.
///
/// This prevents rapid successive calls by ensuring that the function
/// is only executed after a specified duration has passed since the last call.
class Debouncer {
  /// The duration to wait before executing the debounced function.
  final Duration duration;

  Timer? _timer;

  /// Creates a [Debouncer] with the specified [duration].
  Debouncer({required this.duration});

  /// Executes the given [action] after the debounce duration.
  ///
  /// If called again before the duration expires, the previous call is cancelled
  /// and the timer is reset.
  void call(void Function() action) {
    _timer?.cancel();
    _timer = Timer(duration, action);
  }

  /// Cancels any pending debounced action.
  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
