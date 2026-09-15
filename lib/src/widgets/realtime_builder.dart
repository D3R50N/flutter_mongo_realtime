import 'package:flutter/material.dart';
import 'package:mongo_realtime/mongo_realtime.dart';

typedef RealtimeWidgetBuilder<T> = Widget Function(BuildContext context, T data);
typedef RealtimeLoadingBuilder = Widget Function(BuildContext context);
typedef RealtimeErrorBuilder = Widget Function(
  BuildContext context,
  Object error,
  StackTrace? stackTrace,
);
typedef RealtimeEmptyBuilder = Widget Function(BuildContext context);

/// A reactive Flutter widget that subscribes to a realtime stream, query, or document
/// and builds its UI whenever updates are emitted.
class RealtimeBuilder<T> extends StatelessWidget {
  const RealtimeBuilder({
    super.key,
    required this.stream,
    required this.builder,
    this.loadingBuilder,
    this.errorBuilder,
    this.emptyBuilder,
    this.initialData,
  });

  /// Subscribes to a [RealtimeQueryBuilder] emitting [RealtimeDocument] lists.
  static RealtimeBuilder<List<RealtimeDocument<M>>> query<M>({
    Key? key,
    required RealtimeQueryBuilder<M> query,
    required RealtimeWidgetBuilder<List<RealtimeDocument<M>>> builder,
    RealtimeLoadingBuilder? loadingBuilder,
    RealtimeErrorBuilder? errorBuilder,
    RealtimeEmptyBuilder? emptyBuilder,
    List<RealtimeDocument<M>>? initialData,
  }) {
    return RealtimeBuilder<List<RealtimeDocument<M>>>(
      key: key,
      stream: query.stream,
      builder: builder,
      loadingBuilder: loadingBuilder,
      errorBuilder: errorBuilder,
      emptyBuilder: emptyBuilder,
      initialData: initialData,
    );
  }

  /// Subscribes to a [RealtimeQueryBuilder] emitting parsed model value lists.
  static RealtimeBuilder<List<M>> queryValues<M>({
    Key? key,
    required RealtimeQueryBuilder<M> query,
    required RealtimeWidgetBuilder<List<M>> builder,
    RealtimeLoadingBuilder? loadingBuilder,
    RealtimeErrorBuilder? errorBuilder,
    RealtimeEmptyBuilder? emptyBuilder,
    List<M>? initialData,
  }) {
    return RealtimeBuilder<List<M>>(
      key: key,
      stream: query.streamWithValue,
      builder: builder,
      loadingBuilder: loadingBuilder,
      errorBuilder: errorBuilder,
      emptyBuilder: emptyBuilder,
      initialData: initialData,
    );
  }

  /// Subscribes to a [RealtimeDocumentReference] emitting a [RealtimeDocument].
  static RealtimeBuilder<RealtimeDocument<M>?> document<M>({
    Key? key,
    required RealtimeDocumentReference<M> document,
    required RealtimeWidgetBuilder<RealtimeDocument<M>?> builder,
    RealtimeLoadingBuilder? loadingBuilder,
    RealtimeErrorBuilder? errorBuilder,
    RealtimeDocument<M>? initialData,
  }) {
    return RealtimeBuilder<RealtimeDocument<M>?>(
      key: key,
      stream: document.stream,
      builder: builder,
      loadingBuilder: loadingBuilder,
      errorBuilder: errorBuilder,
      initialData: initialData,
    );
  }

  /// Subscribes to a [RealtimeDocumentReference] emitting a parsed model value.
  static RealtimeBuilder<M?> documentValue<M>({
    Key? key,
    required RealtimeDocumentReference<M> document,
    required RealtimeWidgetBuilder<M?> builder,
    RealtimeLoadingBuilder? loadingBuilder,
    RealtimeErrorBuilder? errorBuilder,
    M? initialData,
  }) {
    return RealtimeBuilder<M?>(
      key: key,
      stream: document.streamWithValue,
      builder: builder,
      loadingBuilder: loadingBuilder,
      errorBuilder: errorBuilder,
      initialData: initialData,
    );
  }

  /// The stream to listen to.
  final Stream<T> stream;

  /// Builder invoked when data is available.
  final RealtimeWidgetBuilder<T> builder;

  /// Optional widget displayed while awaiting initial snapshot.
  final RealtimeLoadingBuilder? loadingBuilder;

  /// Optional widget displayed when an error occurs.
  final RealtimeErrorBuilder? errorBuilder;

  /// Optional widget displayed when data is an empty list or collection.
  final RealtimeEmptyBuilder? emptyBuilder;

  /// Optional initial data before first emission.
  final T? initialData;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(
      stream: stream,
      initialData: initialData,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          if (errorBuilder != null) {
            return errorBuilder!(context, snapshot.error!, snapshot.stackTrace);
          }
          return Center(
            child: Text(
              'Realtime Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          if (loadingBuilder != null) {
            return loadingBuilder!(context);
          }
          return const Center(child: CircularProgressIndicator.adaptive());
        }

        final data = snapshot.data;
        if (data == null) {
          if (loadingBuilder != null) {
            return loadingBuilder!(context);
          }
          return const SizedBox.shrink();
        }

        if (emptyBuilder != null && data is Iterable && data.isEmpty) {
          return emptyBuilder!(context);
        }

        return builder(context, data);
      },
    );
  }
}
