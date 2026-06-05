library circlestream.features.camera.data.upload_repository_impl;

import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';
import '../../../shared/models/post_model.dart';
import 'upload_repository.dart';

class UploadRepositoryImpl implements UploadRepository {
  final ApiClient _apiClient;

  UploadRepositoryImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  Future<PresignResult> presignUpload({
    required int circleId,
    required String filename,
    required String contentType,
    required int fileSize,
  }) async {
    final response = await _apiClient.post(
      Endpoints.presignUpload,
      data: {
        'circle_id': circleId,
        'filename': filename,
        'content_type': contentType,
        'file_size': fileSize,
      },
    );

    return PresignResult.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> uploadToB2({
    required String presignedUrl,
    required List<int> imageBytes,
    required String contentType,
    required void Function(double) onProgress,
  }) async {
    final rawDio = Dio();
    await rawDio.put(
      presignedUrl,
      data: Stream.fromIterable([imageBytes]),
      options: Options(
        headers: {
          'Content-Type': contentType,
          'Content-Length': imageBytes.length,
        },
      ),
      onSendProgress: (sent, total) {
        if (total > 0) {
          onProgress(sent / total);
        }
      },
    );
  }

  @override
  Future<PostModel> finalizeUpload({
    required int circleId,
    required String objectKey,
    String? thumbnailKey,
  }) async {
    final response = await _apiClient.post(
      Endpoints.finalizeUpload,
      data: {
        'circle_id': circleId,
        'object_key': objectKey,
        if (thumbnailKey != null) 'thumbnail_key': thumbnailKey,
      },
    );

    final data = response.data as Map<String, dynamic>;
    return PostModel.fromJson(data['post'] as Map<String, dynamic>);
  }
}
