library circlestream.features.camera.screens.camera_capture_screen;

import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../design/app_colors.dart';
import '../../../design/app_radius.dart';
import '../../../design/app_spacing.dart';
import '../../../design/app_text_styles.dart';

class CameraCaptureScreen extends StatefulWidget {
  final int circleId;
  final String circleName;

  const CameraCaptureScreen({
    super.key,
    required this.circleId,
    required this.circleName,
  });

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen>
    with WidgetsBindingObserver {
  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  bool _isInitialised = false;
  bool _hasError = false;
  int _selectedCameraIndex = 0;
  
  // Flash mode cycle: off -> auto -> always (on)
  final List<FlashMode> _flashModes = [
    FlashMode.off,
    FlashMode.auto,
    FlashMode.always,
  ];
  int _currentFlashIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Lock orientation to portrait
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    _initCameras();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    
    // Reset orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCameraController(cameraController.description);
    }
  }

  Future<void> _initCameras() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        // Try to find the back camera first
        int backIndex = _cameras.indexWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
        );
        _selectedCameraIndex = backIndex != -1 ? backIndex : 0;
        await _initCameraController(_cameras[_selectedCameraIndex]);
      } else {
        setState(() {
          _hasError = true;
        });
      }
    } catch (_) {
      setState(() {
        _hasError = true;
      });
    }
  }

  Future<void> _initCameraController(CameraDescription description) async {
    if (_controller != null) {
      await _controller!.dispose();
    }

    _controller = CameraController(
      description,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
      // Set default flash mode
      await _controller!.setFlashMode(_flashModes[_currentFlashIndex]);
      if (mounted) {
        setState(() {
          _isInitialised = true;
          _hasError = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isInitialised = false;
        });
      }
    }
  }

  Future<void> _cycleFlash() async {
    if (_controller == null || !_isInitialised) return;

    final nextIndex = (_currentFlashIndex + 1) % _flashModes.length;
    try {
      await _controller!.setFlashMode(_flashModes[nextIndex]);
      setState(() {
        _currentFlashIndex = nextIndex;
      });
    } catch (_) {}
  }

  Future<void> _toggleCamera() async {
    if (_cameras.length < 2 || _controller == null || !_isInitialised) return;

    final nextIndex = (_selectedCameraIndex + 1) % _cameras.length;
    setState(() {
      _isInitialised = false;
      _selectedCameraIndex = nextIndex;
    });

    await _initCameraController(_cameras[nextIndex]);
  }

  Future<void> _takePhoto() async {
    if (_controller == null || !_isInitialised || _controller!.value.isTakingPicture) {
      return;
    }

    try {
      final xFile = await _controller!.takePicture();
      if (mounted) {
        // Navigate to preview screen
        context.push(
          '/camera/preview',
          extra: {
            'imageFile': File(xFile.path),
            'circleId': widget.circleId,
            'circleName': widget.circleName,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengambil foto: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  IconData _getFlashIcon() {
    switch (_flashModes[_currentFlashIndex]) {
      case FlashMode.off:
        return Icons.flash_off_rounded;
      case FlashMode.auto:
        return Icons.flash_auto_rounded;
      case FlashMode.always:
        return Icons.flash_on_rounded;
      default:
        return Icons.flash_off_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.camera_alt_outlined,
                  size: 64,
                  color: AppColors.error,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Akses Kamera Ditolak',
                  style: GoogleFonts.poppins(
                    textStyle: AppTextStyles.h2,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'CircleStream memerlukan izin kamera untuk mengambil dan membagikan foto momen kamu. Silakan aktifkan izin kamera di Pengaturan perangkat.',
                  style: GoogleFonts.dmSans(
                    textStyle: AppTextStyles.bodyMedium,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton(
                  onPressed: () => context.pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                  child: Text(
                    'Kembali',
                    style: GoogleFonts.dmSans(
                      textStyle: AppTextStyles.labelMedium,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_isInitialised || _controller == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    // Viewfinder aspect ratio logic
    final size = MediaQuery.of(context).size;
    final deviceRatio = size.width / size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Viewfinder
          Center(
            child: Transform.scale(
              scale: 1.0 / (_controller!.value.aspectRatio * deviceRatio),
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: CameraPreview(_controller!),
              ),
            ),
          ),

          // HUD overlays
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Column(
                children: [
                  // Top Row Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Close
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                        onPressed: () => context.pop(),
                      ),
                      // Guide title
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          'Foto untuk ${widget.circleName}',
                          style: GoogleFonts.poppins(
                            textStyle: AppTextStyles.bodyMedium,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Flash Toggle
                      IconButton(
                        icon: Icon(
                          _getFlashIcon(),
                          color: Colors.white,
                          size: 26,
                        ),
                        onPressed: _cycleFlash,
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Bottom Controls Row
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // Spacer to balance switcher button
                        const SizedBox(width: 48),

                        // Shutter Button
                        GestureDetector(
                          onTap: _takePhoto,
                          child: Container(
                            height: 84,
                            width: 84,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 4,
                              ),
                            ),
                            child: Container(
                              margin: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                        // Camera Switcher
                        IconButton(
                          icon: const Icon(
                            Icons.flip_camera_ios_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                          onPressed: _toggleCamera,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
