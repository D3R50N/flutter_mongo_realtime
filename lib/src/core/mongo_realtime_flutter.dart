import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:mongo_realtime/mongo_realtime.dart';
import 'package:path_provider/path_provider.dart';

enum RealtimeConnectionStatus {
  connected,
  reconnecting,
  paused,
  disconnected,
}

bool _flutterHooksRegistered = false;

void _ensureFlutterHooks() {
  if (_flutterHooksRegistered) return;
  _flutterHooksRegistered = true;
  MongoRealtime.registerFlutterHook(
    RealtimeFlutterHook(
      beforeConnect: ({
        required bool persistToDisk,
        RealtimeStorageAdapter? customStorage,
      }) async {
        if (customStorage != null || !persistToDisk || kIsWeb) {
          return customStorage;
        }
        try {
          final docsDir = await getApplicationDocumentsDirectory();
          final cacheDir = Directory('${docsDir.path}/mongo_realtime_cache');
          if (!await cacheDir.exists()) {
            await cacheDir.create(recursive: true);
          }
          final fileAdapter = FileStorageAdapter.fromDirectory(
            cacheDir,
            writeDebounce: const Duration(milliseconds: 100),
          );
          await fileAdapter.initialize();
          return fileAdapter;
        } catch (e) {
          debugPrint(
            '[MongoRealtimeFlutter] Disk storage initialization failed, using memory: $e',
          );
          return null;
        }
      },
      afterConnect: (client, autoLifecycle) {
        MongoRealtimeFlutter._attachToClient(client, autoLifecycle);
      },
      onConnected: (client) {
        MongoRealtimeFlutter._statusNotifier.value =
            RealtimeConnectionStatus.connected;
      },
      onDisconnected: (error) {
        if (MongoRealtimeFlutter._client?.isPaused != true) {
          MongoRealtimeFlutter._statusNotifier.value =
              RealtimeConnectionStatus.disconnected;
        }
      },
    ),
  );
}

/// The main entrypoint for MongoRealtime in Flutter applications.
///
/// Automatically provides:
/// 1. App lifecycle listening (`pause` in background, `resume` in foreground).
/// 2. Local disk caching via `path_provider` and `FileStorageAdapter`.
/// 3. Connection status notification.
class MongoRealtimeFlutter {
  MongoRealtimeFlutter._();

  static MongoRealtime? _client;
  static _MongoRealtimeLifecycleObserver? _observer;
  static final ValueNotifier<RealtimeConnectionStatus> _statusNotifier =
      ValueNotifier<RealtimeConnectionStatus>(RealtimeConnectionStatus.disconnected);

  /// Ensures Flutter hooks (lifecycle observer, disk cache) are registered.
  static void ensureInitialized() {
    _ensureFlutterHooks();
  }

  /// Connection status notifier.
  static ValueNotifier<RealtimeConnectionStatus> get statusNotifier {
    _ensureFlutterHooks();
    if (MongoRealtime.isInitialized && _client == null) {
      _attachToClient(MongoRealtime.client, true);
    }
    return _statusNotifier;
  }

  /// Attaches Flutter lifecycle observer and status tracking to a client.
  static void _attachToClient(MongoRealtime client, bool autoLifecycle) {
    _client = client;
    if (client.isConnected) {
      _statusNotifier.value = RealtimeConnectionStatus.connected;
    } else if (client.isPaused) {
      _statusNotifier.value = RealtimeConnectionStatus.paused;
    }
    if (autoLifecycle && _observer == null) {
      _observer = _MongoRealtimeLifecycleObserver(client, _statusNotifier);
      WidgetsBinding.instance.addObserver(_observer!);
    }
  }

  /// Returns the active [MongoRealtime] client instance.
  static MongoRealtime get client {
    _ensureFlutterHooks();
    final c = _client;
    if (c != null) return c;
    if (MongoRealtime.isInitialized) {
      _attachToClient(MongoRealtime.client, true);
      return MongoRealtime.client;
    }
    throw StateError(
      'MongoRealtime has not been connected. '
      'Call MongoRealtime.connect(url) before accessing the client.',
    );
  }

  /// Returns true if initialized.
  static bool get isInitialized {
    _ensureFlutterHooks();
    if (_client != null) return true;
    if (MongoRealtime.isInitialized) {
      _attachToClient(MongoRealtime.client, true);
      return true;
    }
    return false;
  }

  /// Returns true if the client is currently connected.
  static bool get isConnected =>
      statusNotifier.value == RealtimeConnectionStatus.connected;

  /// Connects the MongoRealtime Flutter client.
  ///
  /// [url] The WebSocket endpoint (e.g. `ws://10.0.2.2:3000/` or `ws://localhost:3000/`).
  /// [autoLifecycle] Automatically pauses the client when the app is backgrounded and resumes on foreground (default: true).
  /// [persistToDisk] Automatically creates a `FileStorageAdapter` in the app's documents directory (default: true).
  /// [cachePolicy] Optional custom cache policy (default: max 1000 docs per collection).
  /// [heartbeatConfig] Optional heartbeat configuration (default: 20s ping, 10s timeout).
  /// [autoReconnectConfig] Optional reconnect configuration with backoff and jitter.
  static Future<MongoRealtime> connect({
    required String url,
    bool autoLifecycle = true,
    bool persistToDisk = true,
    RealtimeStorageAdapter? storageAdapter,
    RealtimeCachePolicy? cachePolicy,
    RealtimeHeartbeatConfig heartbeatConfig = const RealtimeHeartbeatConfig(
      interval: Duration(seconds: 20),
      pongTimeout: Duration(seconds: 10),
    ),
    RealtimeReconnectConfig autoReconnectConfig = const RealtimeReconnectConfig(
      enabled: true,
      delay: Duration(seconds: 1),
      maxDelay: Duration(seconds: 15),
      useExponentialBackoff: true,
      jitter: true,
    ),
    ConnectedHandler? onConnected,
    DisconnectedHandler? onDisconnected,
    WarningHandler? warningHandler,
    Object? authData,
  }) async {
    _ensureFlutterHooks();
    _statusNotifier.value = RealtimeConnectionStatus.reconnecting;

    return MongoRealtime.connect(
      url,
      autoLifecycle: autoLifecycle,
      persistToDisk: persistToDisk,
      storageAdapter: storageAdapter,
      cachePolicy: cachePolicy ??
          const RealtimeCachePolicy(
            maxDocumentsPerCollection: 1000,
            persistToStorage: true,
          ),
      heartbeatConfig: heartbeatConfig,
      autoReconnectConfig: autoReconnectConfig,
      onConnected: onConnected,
      onDisconnected: onDisconnected,
      warningHandler: warningHandler,
      authData: authData,
    );
  }

  /// Disposes the client and detaches lifecycle observers.
  static Future<void> dispose() async {
    if (_observer != null) {
      WidgetsBinding.instance.removeObserver(_observer!);
      _observer = null;
    }
    final c = _client ?? (MongoRealtime.isInitialized ? MongoRealtime.client : null);
    _client = null;
    _statusNotifier.value = RealtimeConnectionStatus.disconnected;
    if (c != null) {
      await c.dispose();
    }
  }
}

class _MongoRealtimeLifecycleObserver with WidgetsBindingObserver {
  _MongoRealtimeLifecycleObserver(this.client, this.statusNotifier);

  final MongoRealtime client;
  final ValueNotifier<RealtimeConnectionStatus> statusNotifier;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.inactive) {
      client.pause();
      statusNotifier.value = RealtimeConnectionStatus.paused;
    } else if (state == AppLifecycleState.resumed) {
      if (client.isPaused) {
        statusNotifier.value = RealtimeConnectionStatus.reconnecting;
        client.resume();
      } else if (client.isConnected) {
        statusNotifier.value = RealtimeConnectionStatus.connected;
      }
    }
  }
}
