library circlestream.features.camera.bloc.upload_bloc;

import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import '../data/upload_repository.dart';
import 'upload_event.dart';
import 'upload_state.dart';

class UploadBloc extends Bloc<UploadEvent, UploadState> {
  final UploadRepository _uploadRepository;

  File? _originalFile;
  int? _circleId;
  File? _compressedMain;
  File? _compressedThumb;
  PresignResult? _presignMain;
  PresignResult? _presignThumb;

  UploadBloc({required UploadRepository uploadRepository})
      : _uploadRepository = uploadRepository,
        super(const UploadIdle()) {
    on<StartUploadEvent>(_onStartUpload);
    on<RetryUploadEvent>(_onRetryUpload);
    on<CancelUploadEvent>(_onCancelUpload);
    on<ResetUploadEvent>(_onResetUpload);
  }

  void _resetCache() {
    _originalFile = null;
    _circleId = null;
    _compressedMain = null;
    _compressedThumb = null;
    _presignMain = null;
    _presignThumb = null;
  }

  Future<void> _onStartUpload(
      StartUploadEvent event, Emitter<UploadState> emit) async {
    _resetCache();
    _originalFile = event.imageFile;
    _circleId = event.circleId;

    await _executeUploadFlow(emit);
  }

  Future<void> _onRetryUpload(
      RetryUploadEvent event, Emitter<UploadState> emit) async {
    if (_originalFile == null || _circleId == null) {
      emit(const UploadIdle());
      return;
    }
    await _executeUploadFlow(emit);
  }

  void _onCancelUpload(CancelUploadEvent event, Emitter<UploadState> emit) {
    _resetCache();
    emit(const UploadIdle());
  }

  void _onResetUpload(ResetUploadEvent event, Emitter<UploadState> emit) {
    _resetCache();
    emit(const UploadIdle());
  }

  Future<File?> _compressImage({
    required File file,
    required String targetPath,
    required int maxWidthHeight,
    required int quality,
  }) async {
    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      minWidth: maxWidthHeight,
      minHeight: maxWidthHeight,
      quality: quality,
    );
    if (result == null) return null;
    return File(result.path);
  }

  Future<void> _executeUploadFlow(Emitter<UploadState> emit) async {
    // Step 1: Compress
    if (_compressedMain == null || _compressedThumb == null) {
      emit(const UploadCompressing());
      try {
        final tempDir = Directory.systemTemp;
        final mainPath =
            '${tempDir.path}/main_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final thumbPath =
            '${tempDir.path}/thumb_${DateTime.now().millisecondsSinceEpoch}.jpg';

        File? mainCompressed = await _compressImage(
          file: _originalFile!,
          targetPath: mainPath,
          maxWidthHeight: 1080,
          quality: 85,
        );

        if (mainCompressed == null) {
          throw Exception('Compress main image returned null');
        }

        if (await mainCompressed.length() > 3 * 1024 * 1024) {
          mainCompressed = await _compressImage(
            file: _originalFile!,
            targetPath: mainPath,
            maxWidthHeight: 1080,
            quality: 70,
          );
        }

        if (mainCompressed == null) {
          throw Exception('Compress main image re-compress returned null');
        }

        final thumbCompressed = await _compressImage(
          file: _originalFile!,
          targetPath: thumbPath,
          maxWidthHeight: 400,
          quality: 75,
        );

        if (thumbCompressed == null) {
          throw Exception('Compress thumbnail image returned null');
        }

        _compressedMain = mainCompressed;
        _compressedThumb = thumbCompressed;
      } catch (e) {
        emit(const UploadError(
          error: 'Gagal memproses foto',
          step: UploadStep.compress,
        ));
        return;
      }
    }

    // Step 2: Presign
    if (_presignMain == null || _presignThumb == null) {
      emit(const UploadPresigning());
      try {
        final mainSize = await _compressedMain!.length();
        final mainPresign = await _uploadRepository.presignUpload(
          circleId: _circleId!,
          filename: 'photo.jpg',
          contentType: 'image/jpeg',
          fileSize: mainSize,
        );

        final thumbSize = await _compressedThumb!.length();
        final thumbPresign = await _uploadRepository.presignUpload(
          circleId: _circleId!,
          filename: 'thumb.jpg',
          contentType: 'image/jpeg',
          fileSize: thumbSize,
        );

        _presignMain = mainPresign;
        _presignThumb = thumbPresign;
      } catch (e) {
        emit(const UploadError(
          error: 'Gagal memulai upload',
          step: UploadStep.presign,
        ));
        return;
      }
    }

    // Step 3: Upload to B2
    emit(const UploadingToB2(progress: 0.0));
    try {
      double mainProgress = 0.0;
      double thumbProgress = 0.0;

      void updateOverallProgress() {
        final overall = (mainProgress + thumbProgress) / 2.0;
        emit(UploadingToB2(progress: overall));
      }

      await _uploadRepository.uploadToB2(
        presignedUrl: _presignMain!.uploadUrl,
        imageBytes: await _compressedMain!.readAsBytes(),
        contentType: 'image/jpeg',
        onProgress: (p) {
          mainProgress = p;
          updateOverallProgress();
        },
      );

      await _uploadRepository.uploadToB2(
        presignedUrl: _presignThumb!.uploadUrl,
        imageBytes: await _compressedThumb!.readAsBytes(),
        contentType: 'image/jpeg',
        onProgress: (p) {
          thumbProgress = p;
          updateOverallProgress();
        },
      );
    } catch (e) {
      emit(const UploadError(
        error: 'Gagal mengupload foto, coba lagi',
        step: UploadStep.upload,
      ));
      return;
    }

    // Step 4: Finalize
    emit(const UploadFinalizing());
    try {
      final post = await _uploadRepository.finalizeUpload(
        circleId: _circleId!,
        objectKey: _presignMain!.objectKey,
        thumbnailKey: _presignThumb!.objectKey,
      );
      emit(UploadSuccess(post: post));
      _resetCache();
    } catch (e) {
      emit(const UploadError(
        error: 'Foto terupload tapi gagal disimpan, coba lagi',
        step: UploadStep.finalize,
      ));
    }
  }
}
