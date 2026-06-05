library circlestream.features.feed.screens.feed_screen;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../design/app_colors.dart';
import '../../../design/app_radius.dart';
import '../../../design/app_spacing.dart';
import '../../../design/app_text_styles.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_error_widget.dart';
import '../../../shared/widgets/app_loading_indicator.dart';
import '../../../core/di/injection.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';
import '../../circle/bloc/circle_bloc.dart';
import '../../circle/bloc/circle_event.dart';
import '../../circle/bloc/circle_state.dart';
import '../../reaction/widgets/floating_emoji_animation.dart';
import '../../realtime/bloc/realtime_bloc.dart';
import '../../realtime/bloc/realtime_event.dart';
import '../../realtime/bloc/realtime_state.dart';
import '../bloc/feed_bloc.dart';
import '../bloc/feed_event.dart';
import '../bloc/feed_state.dart';
import '../widgets/photo_card.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final ScrollController _scrollController = ScrollController();
  int? _activeCircleId;
  String? _activeCircleName;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadCircles();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    // Disconnect realtime when leaving feed screen
    context.read<RealtimeBloc>().add(const DisconnectRealtimeEvent());
    super.dispose();
  }

  void _loadCircles() {
    context.read<CircleBloc>().add(const LoadCirclesEvent());
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      context.read<FeedBloc>().add(const LoadMoreFeedEvent());
    }
  }

  void _selectCircle(int circleId, String circleName) {
    if (_activeCircleId == circleId) return;

    // Disconnect from old realtime channel
    context.read<RealtimeBloc>().add(const DisconnectRealtimeEvent());

    setState(() {
      _activeCircleId = circleId;
      _activeCircleName = circleName;
    });

    // Load new feed and connect to new realtime channel
    context.read<FeedBloc>().add(LoadFeedEvent(circleId: circleId));
    context.read<RealtimeBloc>().add(ConnectRealtimeEvent(circleId: circleId));
  }

  @override
  Widget build(BuildContext context) {
    return FloatingEmojiOverlay(
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          title: Text(
            _activeCircleName ?? 'Feed',
            style: GoogleFonts.poppins(textStyle: AppTextStyles.h1),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            // Offline Connection Banner
            BlocBuilder<RealtimeBloc, RealtimeState>(
              builder: (context, state) {
                if (state is RealtimeDisconnected || state is RealtimeError) {
                  return Container(
                    width: double.infinity,
                    color: AppColors.warning.withOpacity(0.2),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Center(
                      child: Text(
                        'Koneksi terputus — Tarik untuk memuat ulang',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            // Main UI Switcher depending on Circle State
            Expanded(
              child: BlocConsumer<CircleBloc, CircleState>(
                listener: (context, state) {
                  if (state is CircleListLoaded && state.circles.isNotEmpty) {
                    if (_activeCircleId == null) {
                      final first = state.circles.first;
                      _selectCircle(first.id, first.name);
                    }
                  }
                },
                builder: (context, state) {
                  if (state is CircleLoading && _activeCircleId == null) {
                    return const AppLoadingIndicator();
                  }

                  if (state is CircleError && _activeCircleId == null) {
                    return AppErrorWidget(
                      message: state.error,
                      onRetry: _loadCircles,
                    );
                  }

                  if (state is CircleListLoaded) {
                    if (state.circles.isEmpty) {
                      return AppEmptyState(
                        message: 'Kamu belum bergabung circle',
                        subMessage: 'Buat circle baru atau gabung circle temanmu untuk mulai berbagi momen!',
                        actionLabel: 'Buat Circle',
                        onAction: () => context.push('/circles/create'),
                      );
                    }

                    return Column(
                      children: [
                        // Circle Selector Row
                        if (state.circles.length > 1)
                          _buildCircleSelector(state.circles),

                        // Feed Section
                        Expanded(
                          child: BlocBuilder<FeedBloc, FeedState>(
                            builder: (context, feedState) {
                              if (feedState is FeedLoading) {
                                return const AppLoadingIndicator();
                              }

                              if (feedState is FeedError) {
                                return AppErrorWidget(
                                  message: feedState.error,
                                  onRetry: () {
                                    if (_activeCircleId != null) {
                                      context.read<FeedBloc>().add(
                                            LoadFeedEvent(
                                              circleId: _activeCircleId!,
                                            ),
                                          );
                                    }
                                  },
                                );
                              }

                              if (feedState is FeedLoaded) {
                                if (feedState.posts.isEmpty) {
                                  return AppEmptyState(
                                    message: 'Belum ada foto',
                                    subMessage: 'Jadilah yang pertama berbagi momen!',
                                    actionLabel: 'Ambil Foto',
                                    onAction: () {
                                      // Trigger modal capture screen
                                      context.push('/camera');
                                    },
                                  );
                                }

                                return RefreshIndicator(
                                  color: AppColors.primary,
                                  onRefresh: () async {
                                    if (_activeCircleId != null) {
                                      context.read<FeedBloc>().add(
                                            RefreshFeedEvent(
                                              circleId: _activeCircleId!,
                                            ),
                                          );
                                    }
                                  },
                                  child: ListView.builder(
                                    controller: _scrollController,
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.md,
                                      vertical: AppSpacing.sm,
                                    ),
                                    itemCount: feedState.posts.length +
                                        (feedState.hasMore ? 1 : 0),
                                    itemBuilder: (context, index) {
                                      if (index == feedState.posts.length) {
                                        return const Padding(
                                          padding: EdgeInsets.symmetric(
                                            vertical: AppSpacing.md,
                                          ),
                                          child: AppLoadingIndicator(),
                                        );
                                      }

                                      final post = feedState.posts[index];
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: AppSpacing.md,
                                        ),
                                        child: PhotoCard(
                                          post: post,
                                        ),
                                      );
                                    },
                                  ),
                                );
                              }

                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      ],
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleSelector(List<dynamic> circles) {
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: circles.length,
        itemBuilder: (context, index) {
          final circle = circles[index];
          final isSelected = circle.id == _activeCircleId;

          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: ChoiceChip(
              label: Text(circle.name),
              selected: isSelected,
              onSelected: (_) => _selectCircle(circle.id, circle.name),
              selectedColor: AppColors.primary.withOpacity(0.15),
              backgroundColor: AppColors.surface,
              labelStyle: GoogleFonts.dmSans(
                textStyle: AppTextStyles.bodyMedium,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.surfaceAlt,
                width: 1,
              ),
            ),
          );
        },
      ),
    );
  }
}
