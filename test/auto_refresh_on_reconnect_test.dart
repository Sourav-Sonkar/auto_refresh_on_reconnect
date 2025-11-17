import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:auto_refresh_on_reconnect/auto_refresh_on_reconnect.dart';

/// Mock connectivity service for testing
class MockConnectivityService extends ConnectivityService {
  final StreamController<bool> _controller = StreamController<bool>.broadcast();
  bool _isConnected = true;

  @override
  Stream<bool> get onConnectivityChanged => _controller.stream;

  @override
  Future<bool> get isConnected async => _isConnected;

  @override
  Future<bool> hasInternetAccess() async => _isConnected;

  void setConnected(bool connected) {
    _isConnected = connected;
    _controller.add(connected);
  }

  void dispose() {
    _controller.close();
  }
}

void main() {
  group('AutoRefreshOnReconnect', () {
    testWidgets('displays child widget when online', (tester) async {
      final mockService = MockConnectivityService();

      await tester.pumpWidget(
        MaterialApp(
          home: AutoRefreshOnReconnect(
            connectivityService: mockService,
            child: const Text('Online Content'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Online Content'), findsOneWidget);

      mockService.dispose();
    });

    testWidgets('displays offline builder when offline', (tester) async {
      final mockService = MockConnectivityService();
      mockService.setConnected(false);

      await tester.pumpWidget(
        MaterialApp(
          home: AutoRefreshOnReconnect(
            connectivityService: mockService,
            offlineBuilder: (context) => const Text('Offline'),
            child: const Text('Online Content'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Offline'), findsOneWidget);
      expect(find.text('Online Content'), findsNothing);

      mockService.dispose();
    });

    testWidgets('triggers onRefresh when reconnected', (tester) async {
      final mockService = MockConnectivityService();
      mockService.setConnected(false);

      int refreshCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: AutoRefreshOnReconnect(
            connectivityService: mockService,
            debounceDuration: const Duration(milliseconds: 100),
            onRefresh: () async {
              refreshCount++;
            },
            offlineBuilder: (context) => const Text('Offline'),
            child: const Text('Online Content'),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Offline'), findsOneWidget);

      // Reconnect
      mockService.setConnected(true);
      await tester.pumpAndSettle();

      // Wait for debounce
      await tester.pump(const Duration(milliseconds: 150));

      expect(refreshCount, 1);
      expect(find.text('Online Content'), findsOneWidget);

      mockService.dispose();
    });

    testWidgets('debounces rapid reconnection events', (tester) async {
      final mockService = MockConnectivityService();
      mockService.setConnected(false);

      int refreshCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: AutoRefreshOnReconnect(
            connectivityService: mockService,
            debounceDuration: const Duration(milliseconds: 200),
            onRefresh: () async {
              refreshCount++;
            },
            child: const Text('Online Content'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Rapid reconnection events
      mockService.setConnected(true);
      await tester.pump(const Duration(milliseconds: 50));

      mockService.setConnected(false);
      await tester.pump(const Duration(milliseconds: 50));

      mockService.setConnected(true);
      await tester.pump(const Duration(milliseconds: 50));

      mockService.setConnected(false);
      await tester.pump(const Duration(milliseconds: 50));

      mockService.setConnected(true);
      await tester.pumpAndSettle();

      // Wait for debounce
      await tester.pump(const Duration(milliseconds: 250));

      // Should only refresh once due to debouncing
      expect(refreshCount, 1);

      mockService.dispose();
    });

    testWidgets('does not trigger refresh when staying online', (tester) async {
      final mockService = MockConnectivityService();
      mockService.setConnected(true);

      int refreshCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: AutoRefreshOnReconnect(
            connectivityService: mockService,
            debounceDuration: const Duration(milliseconds: 100),
            onRefresh: () async {
              refreshCount++;
            },
            child: const Text('Online Content'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Stay online
      mockService.setConnected(true);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 150));

      expect(refreshCount, 0);

      mockService.dispose();
    });
  });

  group('AutoRefreshOnReconnectBuilder', () {
    testWidgets('fetches data and displays it', (tester) async {
      final mockService = MockConnectivityService();

      await tester.pumpWidget(
        MaterialApp(
          home: AutoRefreshOnReconnectBuilder<String>(
            connectivityService: mockService,
            futureBuilder: () async {
              await Future.delayed(const Duration(milliseconds: 100));
              return 'Test Data';
            },
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }
              if (snapshot.hasData) {
                return Text(snapshot.data!);
              }
              return const Text('No data');
            },
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();

      expect(find.text('Test Data'), findsOneWidget);

      mockService.dispose();
    });

    testWidgets('refetches data on reconnection', (tester) async {
      final mockService = MockConnectivityService();
      mockService.setConnected(true);

      int callCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: AutoRefreshOnReconnectBuilder<String>(
            connectivityService: mockService,
            debounceDuration: const Duration(milliseconds: 100),
            futureBuilder: () async {
              callCount++;
              await Future.delayed(const Duration(milliseconds: 50));
              return 'Data $callCount';
            },
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Text(snapshot.data!);
              }
              return const CircularProgressIndicator();
            },
            offlineBuilder: (context) => const Text('Offline'),
          ),
        ),
      );

      // Wait for initial data to load
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      expect(find.text('Data 1'), findsOneWidget);

      // Go offline
      mockService.setConnected(false);
      await tester.pumpAndSettle();
      expect(find.text('Offline'), findsOneWidget);

      // Reconnect
      mockService.setConnected(true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(callCount, 2);
      expect(find.text('Data 2'), findsOneWidget);

      mockService.dispose();
    });
  });
}
