import 'dart:async';
import 'package:flutter/material.dart';
import 'package:auto_refresh_on_reconnect/src/connectivity_service.dart';
import 'package:auto_refresh_on_reconnect/src/debounce.dart';

/// A widget that automatically refreshes when internet connection is restored.
///
/// This widget monitors network connectivity and triggers a refresh callback
/// when the device reconnects to the internet. It can optionally display
/// a custom offline UI when no internet connection is available.
///
/// Example:
/// ```dart
/// AutoRefreshOnReconnect(
///   onRefresh: () async {
///     await fetchData();
///   },
///   offlineBuilder: (context) => Center(
///     child: Text('No Internet Connection'),
///   ),
///   child: MyContentWidget(),
/// )
/// ```
class AutoRefreshOnReconnect extends StatefulWidget {
  /// The widget to display when online.
  final Widget child;

  /// Callback triggered when internet connection is restored.
  ///
  /// This is debounced to prevent rapid successive calls.
  final Future<void> Function()? onRefresh;

  /// Builder for the offline UI.
  ///
  /// If null, the [child] widget will continue to be displayed when offline.
  final WidgetBuilder? offlineBuilder;

  /// Duration to debounce reconnection events.
  ///
  /// Prevents rapid re-triggers when connection is unstable.
  /// Default is 2 seconds.
  final Duration debounceDuration;

  /// Custom connectivity service for testing or custom implementations.
  final ConnectivityService? connectivityService;

  /// Creates an [AutoRefreshOnReconnect] widget.
  const AutoRefreshOnReconnect({
    required this.child,
    super.key,
    this.onRefresh,
    this.offlineBuilder,
    this.debounceDuration = const Duration(seconds: 2),
    this.connectivityService,
  });

  @override
  State<AutoRefreshOnReconnect> createState() =>
      _AutoRefreshOnReconnectState();
}

class _AutoRefreshOnReconnectState extends State<AutoRefreshOnReconnect> {
  late final ConnectivityService _connectivityService;
  late final Debouncer _debouncer;
  StreamSubscription<bool>? _connectivitySubscription;

  bool _isOnline = true;
  bool _wasOffline = false;

  @override
  void initState() {
    super.initState();
    _connectivityService =
        widget.connectivityService ?? ConnectivityService();
    _debouncer = Debouncer(duration: widget.debounceDuration);

    _initializeConnectivity();
    _listenToConnectivity();
  }

  Future<void> _initializeConnectivity() async {
    final isConnected = await _connectivityService.isConnected;
    if (mounted) {
      setState(() {
        _isOnline = isConnected;
        _wasOffline = !isConnected;
      });
    }
  }

  void _listenToConnectivity() {
    _connectivitySubscription =
        _connectivityService.onConnectivityChanged.listen((isOnline) {
      if (mounted) {
        setState(() {
          _isOnline = isOnline;
        });

        // If we're back online after being offline, trigger refresh
        if (isOnline && _wasOffline) {
          _debouncer(() {
            if (mounted) {
              widget.onRefresh?.call();
            }
          });
        }

        _wasOffline = !isOnline;
      }
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _debouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isOnline && widget.offlineBuilder != null) {
      return widget.offlineBuilder!(context);
    }
    return widget.child;
  }
}

/// A builder-based variant that automatically fetches data when reconnected.
///
/// This widget combines data fetching with automatic refresh on reconnection.
/// It uses Flutter's [FutureBuilder] pattern for displaying loading, error,
/// and success states.
///
/// Example:
/// ```dart
/// AutoRefreshOnReconnect.builder<List<Product>>(
///   futureBuilder: () => fetchProducts(),
///   builder: (context, snapshot) {
///     if (snapshot.hasData) {
///       return ProductList(products: snapshot.data!);
///     }
///     return CircularProgressIndicator();
///   },
///   offlineBuilder: (context) => Text('Offline'),
/// )
/// ```
class AutoRefreshOnReconnectBuilder<T> extends StatefulWidget {
  /// Function that returns a Future to be executed.
  final Future<T> Function() futureBuilder;

  /// Builder that receives the AsyncSnapshot.
  final AsyncWidgetBuilder<T> builder;

  /// Builder for the offline UI.
  final WidgetBuilder? offlineBuilder;

  /// Duration to debounce reconnection events.
  final Duration debounceDuration;

  /// Custom connectivity service for testing.
  final ConnectivityService? connectivityService;

  /// Creates an [AutoRefreshOnReconnectBuilder] widget.
  const AutoRefreshOnReconnectBuilder({
    required this.futureBuilder,
    required this.builder,
    super.key,
    this.offlineBuilder,
    this.debounceDuration = const Duration(seconds: 2),
    this.connectivityService,
  });

  @override
  State<AutoRefreshOnReconnectBuilder<T>> createState() =>
      _AutoRefreshOnReconnectBuilderState<T>();
}

class _AutoRefreshOnReconnectBuilderState<T>
    extends State<AutoRefreshOnReconnectBuilder<T>> {
  late Future<T> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.futureBuilder();
  }

  void _refresh() {
    setState(() {
      _future = widget.futureBuilder();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AutoRefreshOnReconnect(
      onRefresh: () async {
        _refresh();
      },
      offlineBuilder: widget.offlineBuilder,
      debounceDuration: widget.debounceDuration,
      connectivityService: widget.connectivityService,
      child: FutureBuilder<T>(
        future: _future,
        builder: widget.builder,
      ),
    );
  }
}
