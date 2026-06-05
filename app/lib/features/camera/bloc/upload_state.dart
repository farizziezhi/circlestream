library circlestream.features.camera.bloc.upload_state;

import 'package:equatable/equatable.dart';
import '../../../shared/models/post_model.dart';

enum UploadStep { compress, presign, upload, finalize }

abstract class UploadState extends Equatable {
  const UploadState();

  @override
  List<Object?> get props => [];
}

class UploadIdle extends UploadState {
  const UploadIdle();
}

class UploadCompressing extends UploadState {
  const UploadCompressing();
}

class UploadPresigning extends UploadState {
  const UploadPresigning();
}

class UploadingToB2 extends UploadState {
  final double progress;

  const UploadingToB2({required this.progress});

  @override
  List<Object?> get props => [progress];
}

class UploadFinalizing extends UploadState {
  const UploadFinalizing();
}

class UploadSuccess extends UploadState {
  final PostModel post;

  const UploadSuccess({required this.post});

  @override
  List<Object?> get props => [post];
}

class UploadError extends UploadState {
  final String error;
  final UploadStep step;

  const UploadError({
    required this.error,
    required this.step,
  });

  @override
  List<Object?> get props => [error, step];
}
