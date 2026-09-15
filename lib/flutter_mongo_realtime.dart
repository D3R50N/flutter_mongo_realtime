/// Official Flutter client and widgets for MongoRealtime.
///
/// Features:
/// - Seamless app lifecycle management (`pause()` / `resume()`)
/// - Automatic disk persistence via `path_provider` and `FileStorageAdapter`
/// - Reactive Flutter widgets: [RealtimeBuilder] and [RealtimeStatusBuilder]
/// - Re-exports the full [mongo_realtime] API.
library flutter_mongo_realtime;

export 'package:mongo_realtime/mongo_realtime.dart';

export 'src/core/mongo_realtime_flutter.dart' show RealtimeConnectionStatus;
export 'src/widgets/realtime_builder.dart';
export 'src/widgets/realtime_status_builder.dart';
