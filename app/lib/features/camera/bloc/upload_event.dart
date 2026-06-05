library circlestream.features.camera.bloc.upload_event;

import 'dart:io';
import 'package:equatable/equatable.dart';

abstract class UploadEvent extends Equatable {
  const UploadEvent();

  @override
  List<Object?> get props => [];
}

class StartUploadEvent extends UploadEvent {
  final File imageFile;
  final int circleId;

  const StartUploadEvent({
    required this.imageFile,
    required this.circleId,
  });

  @override
  List<Object?> get props => [imageFile, circleId];
}

class RetryUploadEvent extends UploadEvent {
  const RetryUploadEvent();
}

class CancelUploadEvent extends UploadEvent {
  const CancelUploadEvent();
}

class ResetUploadEvent extends UploadEvent {
  const ResetUploadEvent();
}
