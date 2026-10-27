import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const apiBaseUrl = 'https://api.escuelajs.co/api/v1';

/// A single Dio instance shared by the whole app.
///
/// Individual requests are cancelled with their own [CancelToken]; the client
/// itself is only closed when the root [ProviderScope] is disposed.
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      responseType: ResponseType.json,
    ),
  );
  ref.onDispose(dio.close);
  return dio;
});
