# Changelog

## 1.0.0

- Initial release of `flutter_mongo_realtime`.
- Automatic app lifecycle management (`pause` in background, `resume` on foreground) via `WidgetsBindingObserver`.
- Automatic offline disk caching via `path_provider` and `FileStorageAdapter`.
- Direct entrypoint via `MongoRealtime.connect()` and `MongoRealtime.client`.
- Reactive Flutter widgets:
  - `RealtimeBuilder`: Streamlines query, document, and collection subscriptions with built-in `loadingBuilder`, `emptyBuilder`, and `errorBuilder`.
  - `RealtimeStatusBuilder`: Rebuilds reactively on connection status updates (`connected`, `reconnecting`, `paused`, `disconnected`).
- Full re-export of the `mongo_realtime` API for single-dependency setup.
