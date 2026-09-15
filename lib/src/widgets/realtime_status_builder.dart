import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../core/mongo_realtime_flutter.dart';

/// A widget that listens to connection status changes and rebuilds.
class RealtimeStatusBuilder extends StatelessWidget {
  const RealtimeStatusBuilder({
    super.key,
    this.statusNotifier,
    required this.builder,
  });

  /// The global connection status notifier for Flutter applications.
  static ValueNotifier<RealtimeConnectionStatus> get notifier =>
      MongoRealtimeFlutter.statusNotifier;

  /// Optional custom status notifier. Defaults to [RealtimeStatusBuilder.notifier].
  final ValueListenable<RealtimeConnectionStatus>? statusNotifier;

  /// Builder invoked whenever the connection status updates.
  final Widget Function(BuildContext context, RealtimeConnectionStatus status) builder;

  @override
  Widget build(BuildContext context) {
    final notifier = statusNotifier ?? MongoRealtimeFlutter.statusNotifier;
    return ValueListenableBuilder<RealtimeConnectionStatus>(
      valueListenable: notifier,
      builder: (context, status, _) => builder(context, status),
    );
  }
}
