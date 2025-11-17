import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

/// A service that monitors internet connectivity and verifies actual internet access.
///
/// This service goes beyond simple network connectivity checks by performing
/// actual HTTP requests to verify internet availability.
class ConnectivityService {
  final Connectivity _connectivity;
  final String _checkUrl;
  final Duration _timeout;

  /// Creates a [ConnectivityService] with optional custom configuration.
  ///
  /// [connectivity] - Custom connectivity instance (useful for testing)
  /// [checkUrl] - URL to check for internet availability (default: https://www.google.com)
  /// [timeout] - Timeout duration for connectivity checks (default: 10 seconds)
  ConnectivityService({
    Connectivity? connectivity,
    String checkUrl = 'https://www.google.com',
    Duration timeout = const Duration(seconds: 10),
  })  : _connectivity = connectivity ?? Connectivity(),
        _checkUrl = checkUrl,
        _timeout = timeout;

  /// Stream of connectivity changes.
  ///
  /// Emits `true` when internet is available, `false` when offline.
  /// This stream verifies actual internet access, not just network connectivity.
  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.asyncMap((result) async {
      // If no connectivity at all, return false immediately
      if (result.contains(ConnectivityResult.none)) {
        return false;
      }

      // Verify actual internet access
      return await hasInternetAccess();
    }).distinct(); // Only emit when the value actually changes
  }

  /// Checks if the device has actual internet access.
  ///
  /// Returns `true` if internet is available, `false` otherwise.
  /// This performs an actual HTTP HEAD request to verify connectivity.
  Future<bool> hasInternetAccess() async {
    try {
      // First check basic connectivity
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        return false;
      }

      // On web, we need to be more lenient due to CORS restrictions
      // We'll trust the connectivity check more and use a lighter verification
      if (kIsWeb) {
        // For web, just check if we have connectivity
        // CORS prevents us from making HEAD requests to most domains
        return !connectivityResult.contains(ConnectivityResult.none);
      }

      // Verify actual internet access with HTTP HEAD request
      final response = await http
          .head(Uri.parse(_checkUrl))
          .timeout(_timeout);

      return response.statusCode == 200;
    } on SocketException catch (_) {
      return false;
    } on TimeoutException catch (_) {
      return false;
    } on HttpException catch (_) {
      return false;
    } catch (_) {
      // On web, if we get any error but have connectivity, assume we're online
      if (kIsWeb) {
        return true;
      }
      return false;
    }
  }

  /// Gets the current connectivity status.
  ///
  /// Returns `true` if internet is currently available, `false` otherwise.
  Future<bool> get isConnected => hasInternetAccess();
}
