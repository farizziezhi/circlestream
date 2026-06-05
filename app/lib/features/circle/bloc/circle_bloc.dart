library circlestream.features.circle.bloc.circle_bloc;

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/circle_repository.dart';
import 'circle_event.dart';
import 'circle_state.dart';

class CircleBloc extends Bloc<CircleEvent, CircleState> {
  final CircleRepository _circleRepository;

  CircleBloc({required CircleRepository circleRepository})
      : _circleRepository = circleRepository,
        super(CircleInitial()) {
    on<LoadCirclesEvent>(_onLoadCircles);
    on<CreateCircleEvent>(_onCreateCircle);
    on<JoinCircleEvent>(_onJoinCircle);
    on<LoadCircleDetailEvent>(_onLoadDetail);
    on<LoadMembersEvent>(_onLoadMembers);
    on<LeaveCircleEvent>(_onLeaveCircle);
    on<LoadInviteCodesEvent>(_onLoadInviteCodes);
    on<GenerateInviteCodeEvent>(_onGenerateInviteCode);
  }

  Future<void> _onLoadCircles(
      LoadCirclesEvent event, Emitter<CircleState> emit) async {
    emit(CircleLoading());
    try {
      final circles = await _circleRepository.getMyCircles();
      emit(CircleListLoaded(circles: circles));
    } catch (e) {
      emit(CircleError(error: _mapError(e)));
    }
  }

  Future<void> _onCreateCircle(
      CreateCircleEvent event, Emitter<CircleState> emit) async {
    emit(CircleLoading());
    try {
      final result = await _circleRepository.createCircle(event.name);
      emit(CircleCreated(result: result));
    } catch (e) {
      emit(CircleError(error: _mapError(e)));
    }
  }

  Future<void> _onJoinCircle(
      JoinCircleEvent event, Emitter<CircleState> emit) async {
    emit(CircleLoading());
    try {
      final result = await _circleRepository.joinCircle(event.inviteCode);
      emit(CircleJoined(result: result));
    } catch (e) {
      emit(CircleError(error: _mapError(e)));
    }
  }

  Future<void> _onLoadDetail(
      LoadCircleDetailEvent event, Emitter<CircleState> emit) async {
    emit(CircleLoading());
    try {
      final circle = await _circleRepository.getCircle(event.circleId);
      emit(CircleDetailLoaded(circle: circle));
    } catch (e) {
      emit(CircleError(error: _mapError(e)));
    }
  }

  Future<void> _onLoadMembers(
      LoadMembersEvent event, Emitter<CircleState> emit) async {
    emit(CircleLoading());
    try {
      final members = await _circleRepository.getMembers(event.circleId);
      emit(CircleMembersLoaded(members: members));
    } catch (e) {
      emit(CircleError(error: _mapError(e)));
    }
  }

  Future<void> _onLeaveCircle(
      LeaveCircleEvent event, Emitter<CircleState> emit) async {
    emit(CircleLoading());
    try {
      await _circleRepository.leaveCircle(event.circleId);
      emit(CircleLeft());
    } catch (e) {
      emit(CircleError(error: _mapError(e)));
    }
  }

  Future<void> _onLoadInviteCodes(
      LoadInviteCodesEvent event, Emitter<CircleState> emit) async {
    emit(CircleLoading());
    try {
      final codes = await _circleRepository.getInviteCodes(event.circleId);
      emit(CircleInviteCodesLoaded(inviteCodes: codes));
    } catch (e) {
      emit(CircleError(error: _mapError(e)));
    }
  }

  Future<void> _onGenerateInviteCode(
      GenerateInviteCodeEvent event, Emitter<CircleState> emit) async {
    emit(CircleLoading());
    try {
      final code = await _circleRepository.generateInviteCode(
        event.circleId,
        maxUses: event.maxUses,
      );
      emit(CircleInviteCodeGenerated(inviteCode: code));
    } catch (e) {
      emit(CircleError(error: _mapError(e)));
    }
  }

  String _mapError(Object error) {
    if (error is DioException) {
      final res = error.response;
      if (res != null && res.data is Map) {
        final errCode = res.data['error'] as String?;
        switch (errCode) {
          case 'circle_not_found':
            return 'Circle tidak ditemukan';
          case 'invite_code_not_found':
            return 'Kode undangan tidak ditemukan';
          case 'invite_code_expired':
            return 'Kode undangan sudah kadaluarsa';
          case 'invite_code_exhausted':
            return 'Kode undangan sudah habis digunakan';
          case 'circle_full':
            return 'Circle sudah penuh (10/10)';
          case 'already_member':
            return 'Kamu sudah bergabung di circle ini';
          case 'owner_cannot_leave':
            return 'Owner tidak bisa keluar. Transfer kepemilikan atau hapus circle terlebih dahulu';
          case 'not_member':
            return 'Kamu bukan anggota circle ini';
          case 'validation_error':
            return 'Periksa kembali data yang kamu masukkan';
        }
      }
    }
    return 'Terjadi kesalahan, coba lagi';
  }
}
