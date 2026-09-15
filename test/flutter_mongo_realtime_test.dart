import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mongo_realtime/flutter_mongo_realtime.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MongoRealtime & MongoRealtimeFlutter client state', () {
    test('throws StateError when client accessed before connect', () {
      expect(MongoRealtime.isInitialized, isFalse);
      expect(() => MongoRealtime.client, throwsStateError);
    });
  });

  group('RealtimeBuilder Widget', () {
    testWidgets('renders loading widget when stream is waiting', (tester) async {
      final controller = StreamController<List<String>>();
      addTearDown(controller.close);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RealtimeBuilder<List<String>>(
              stream: controller.stream,
              loadingBuilder: (context) => const Text('Loading items...'),
              builder: (context, data) => Text('Count: ${data.length}'),
            ),
          ),
        ),
      );

      expect(find.text('Loading items...'), findsOneWidget);
      expect(find.text('Count: 0'), findsNothing);
    });

    testWidgets('renders data when stream emits values', (tester) async {
      final controller = StreamController<List<String>>();
      addTearDown(controller.close);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RealtimeBuilder<List<String>>(
              stream: controller.stream,
              builder: (context, data) => Column(
                children: data.map((item) => Text(item)).toList(),
              ),
            ),
          ),
        ),
      );

      controller.add(['Alice', 'Bob']);
      await tester.pump();

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
    });

    testWidgets('renders emptyBuilder when list is empty', (tester) async {
      final controller = StreamController<List<String>>();
      addTearDown(controller.close);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RealtimeBuilder<List<String>>(
              stream: controller.stream,
              emptyBuilder: (context) => const Text('No items found'),
              builder: (context, data) => Text('Count: ${data.length}'),
            ),
          ),
        ),
      );

      controller.add([]);
      await tester.pump();

      expect(find.text('No items found'), findsOneWidget);
      expect(find.text('Count: 0'), findsNothing);
    });

    testWidgets('renders errorBuilder when stream emits error', (tester) async {
      final controller = StreamController<List<String>>();
      addTearDown(controller.close);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RealtimeBuilder<List<String>>(
              stream: controller.stream,
              errorBuilder: (context, error, stack) => Text('Failed: $error'),
              builder: (context, data) => Text('Count: ${data.length}'),
            ),
          ),
        ),
      );

      controller.addError('Connection dropped');
      await tester.pump();

      expect(find.text('Failed: Connection dropped'), findsOneWidget);
    });
  });

  group('RealtimeStatusBuilder', () {
    testWidgets('rebuilds whenever connection status changes', (tester) async {
      final status = ValueNotifier<RealtimeConnectionStatus>(
        RealtimeConnectionStatus.disconnected,
      );
      addTearDown(status.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RealtimeStatusBuilder(
              statusNotifier: status,
              builder: (context, currentStatus) => Text('Status: ${currentStatus.name}'),
            ),
          ),
        ),
      );

      expect(find.text('Status: disconnected'), findsOneWidget);

      status.value = RealtimeConnectionStatus.reconnecting;
      await tester.pump();
      expect(find.text('Status: reconnecting'), findsOneWidget);

      status.value = RealtimeConnectionStatus.connected;
      await tester.pump();
      expect(find.text('Status: connected'), findsOneWidget);

      status.value = RealtimeConnectionStatus.paused;
      await tester.pump();
      expect(find.text('Status: paused'), findsOneWidget);
    });
  });
}
