library circlestream.features.camera.data.upload_repository;

import '../../../shared/models/post_model.dart';

class PresignResult {
  final String uploadUrl;
  final String objectKey;
  final int expiresIn;

  const PresignResult({
    required this.uploadUrl,
    required this.objectKey,
    required this.expiresIn,
  });

  factory PresignResult.fromJson(Map<String, dynamic> json) {
    return PresignResult(
      uploadUrl: json['upload_url'] as String,
      objectKey: json['object_key'] as String,
      expiresIn: json['expires_in'] as int,
    );
  }
}

abstract class UploadRepository {
  Future<PresignResult> presignUpload({
    required int circleId,
    required String filename,
    required String contentType,
    required int fileSize,
  });

  Future<void> uploadToB2({
    required String presignedUrl,
    required List<int> imageBytes,
    required String contentType,
    required void Function(double) onProgress,
  });

  Future<PostModel> finalizeUpload({
    required int circleId,
    required String objectKey,
    String? thumbnailKey,
  });
}
