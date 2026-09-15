# flutter_mongo_realtime

Flutter integration package for [MongoRealtime](https://github.com/D3R50N/mongo-realtime).

## Features

- Automatic app lifecycle handling (`pause` when backgrounded, `resume` when foregrounded).
- Automatic offline disk caching using `path_provider` and `FileStorageAdapter`.
- Reactive Flutter widgets (`RealtimeBuilder`, `RealtimeStatusBuilder`).
- Clean access via `MongoRealtime.initialize()` and `MongoRealtime.client`.
- Re-exports the complete `mongo_realtime` API for single-import usage.

## Getting Started

### 1. Installation

Add `flutter_mongo_realtime` to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_mongo_realtime: ^1.0.0
```

### 2. Connection

Connect to the realtime server in your `main()` entrypoint:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_mongo_realtime/flutter_mongo_realtime.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await MongoRealtime.connect(
    'ws://localhost:3000',
  );

  runApp(const MyApp());
}
```

### 3. Usage

Access the client anywhere in your application:

```dart
// Querying documents
final posts = MongoRealtime.client
    .collection('posts')
    .where('published', isEqualTo: true)
    .orderBy('createdAt', descending: true);

// Inserting documents
await MongoRealtime.client.collection('posts').insert({
  'title': 'New Post',
  'published': true,
  'createdAt': DateTime.now().toIso8601String(),
});

// Updating documents
await MongoRealtime.client.collection('posts').doc(postId).update({
  r'$set': {'published': false},
});
```

## Migration from mongo_realtime

Migration requires minimal changes:

1. Replace `mongo_realtime` with `flutter_mongo_realtime` in `pubspec.yaml`.
2. Keep your existing `MongoRealtime.connect(...)` call. It now automatically handles app lifecycle and persistent disk caching in Flutter.
3. Access the shared client cleanly via `MongoRealtime.client`.

## Reactive Widgets

### RealtimeBuilder

Subscribes to a query or document stream and handles loading, error, and empty states:

```dart
RealtimeBuilder<List<Post>>.queryValues(
  query: MongoRealtime.client
      .collection('posts', fromJson: Post.fromJson)
      .where('published', isEqualTo: true)
      .orderBy('createdAt', descending: true),
  loadingBuilder: (context) => const Center(child: CircularProgressIndicator()),
  emptyBuilder: (context) => const Center(child: Text('No posts found')),
  errorBuilder: (context, error, stack) => Center(child: Text('Error: $error')),
  builder: (context, posts) {
    return ListView.builder(
      itemCount: posts.length,
      itemBuilder: (context, index) => PostCard(post: posts[index]),
    );
  },
)
```

### RealtimeStatusBuilder

Rebuilds your widget tree whenever the connection status changes:

```dart
RealtimeStatusBuilder(
  builder: (context, status) {
    return Text('Status: ${status.name}');
  },
)
```

## Configuration Options

`MongoRealtime.connect()` options:

| Parameter | Type | Default | Description |
|---|---|---|---|
| `url` | `String` | required | WebSocket server endpoint |
| `autoLifecycle` | `bool` | `true` | Pause in background and resume on foreground |
| `persistToDisk` | `bool` | `true` | Persist snapshot cache to device storage |
| `cachePolicy` | `RealtimeCachePolicy?` | `1000 docs` | In-memory cache limits and storage policy |
| `heartbeatConfig` | `RealtimeHeartbeatConfig` | `20s/10s` | Ping/pong dead connection detection |
| `autoReconnectConfig` | `RealtimeReconnectConfig` | Exponential | Reconnection strategy with backoff |

## License

MIT License. See [LICENSE](LICENSE) for details.
