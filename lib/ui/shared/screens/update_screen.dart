// Copyright © 2026 Brayan Medrano - MG Music
// Pantalla de actualización: gestión de descarga e instalación de nuevas versiones de la aplicación.

import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:io';
import 'dart:async';
import 'package:animations/animations.dart';
import 'package:provider/provider.dart';
import 'package:ionicons/ionicons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mg_music/services/logic/update_service.dart';
import 'package:mg_music/services/ui/global_modal_service.dart';
import 'package:mg_music/services/ui/custom_toast_service.dart';
import 'package:mg_music/services/logic/update_download_service.dart';
import 'package:mg_music/services/models/version_model.dart';
import 'package:mg_music/services/ui/theme_service.dart';
import 'package:mg_music/services/ui/responsive_service.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mg_music/ui/shared/splash.dart';
import 'package:mg_music/ui/tv/tv_focusable_item.dart';


enum _UpdatePageState { loading, error, info, downloading, done, upToDate }


class UpdateScreen extends StatefulWidget {
  final VersionModel? versionData;
  final bool isTv;

  const UpdateScreen({
    super.key,
    this.versionData,
    this.isTv = false,
  });

  @override
  State<UpdateScreen> createState() => _UpdateScreenState();
}

class _UpdateScreenState extends State<UpdateScreen>
    with TickerProviderStateMixin {
  late final AnimationController _glowController;

  static const _channel = MethodChannel('mg_music/notification');

  VersionModel? _dynamicVersionData;
  _UpdatePageState _pageState = _UpdatePageState.loading;
  String? _errorMessage;

  double _downloadProgress = 0.0;
  double _totalMB = 0.0;
  String? _downloadedFilePath;

  @override
  void initState() {
    super.initState();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _fetchVersionData();
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }


  Future<void> _fetchVersionData() async {
    if (widget.versionData != null) {
      final localCode = await UpdateService.getLocalVersionCode();
      final cmp = localCode >= widget.versionData!.versionCode ? 0 : -1;
      if (mounted) {
        setState(() {
          _dynamicVersionData = widget.versionData;
          _pageState = cmp >= 0 ? _UpdatePageState.upToDate : _UpdatePageState.info;
        });
      }
      return;
    }

    try {
      final result = await UpdateService.checkForUpdate(isTv: widget.isTv);

      if (mounted) {
        final data = result['data'] as VersionModel?;
        if (result['error'] != null && data == null) {
          setState(() {
            _errorMessage = result['error'];
            _pageState = _UpdatePageState.error;
          });
          return;
        }

        if (data != null) {
          final localCode = await UpdateService.getLocalVersionCode();
          final cmp = localCode >= data.versionCode ? 0 : -1;
          setState(() {
            _dynamicVersionData = data;
            _pageState = cmp >= 0 ? _UpdatePageState.upToDate : _UpdatePageState.info;
          });
        } else {
          setState(() {
            _pageState = _UpdatePageState.upToDate;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _pageState = _UpdatePageState.error;
        });
      }
    }
  }

  Future<bool> _requestPermissions() async {
    if (!Platform.isAndroid) return true;

    bool storageGranted =
        await Permission.storage.isGranted ||
        await Permission.manageExternalStorage.isGranted;

    if (!storageGranted) {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        if (!await Permission.manageExternalStorage.request().isGranted) {
          CustomToastService.show(
            context,
            message: 'Se necesitan permisos de almacenamiento para descargar',
            type: ToastType.error,
          );
          return false;
        }
      }
    }

    if (!await Permission.requestInstallPackages.isGranted) {
      await Permission.requestInstallPackages.request();
      if (!await Permission.requestInstallPackages.isGranted) {
        CustomToastService.show(
          context,
          message: 'Deberás autorizar la instalación al finalizar la descarga',
          type: ToastType.warning,
          duration: const Duration(seconds: 4),
        );
      }
    }

    return true;
  }

  Future<void> _startDownload() async {
    final data = _dynamicVersionData;
    if (data == null) return;

    final alreadyDownloaded = await UpdateDownloadService.isDownloaded(data.version);
    if (alreadyDownloaded) {
      if (mounted) {
        setState(() {
          _downloadedFilePath = UpdateDownloadService.apkPath(data.version);
          _downloadProgress = 1.0;
          _pageState = _UpdatePageState.done;
        });
        CustomToastService.show(
          context,
          message: 'Versión ya descargada — listo para instalar',
          type: ToastType.info,
        );
      }
      return;
    }

    if (!await _requestPermissions()) return;

    if (mounted) {
      setState(() {
        _pageState = _UpdatePageState.downloading;
        _downloadProgress = 0.0;
        _totalMB = 0.0;
      });
    }

    await Future.delayed(const Duration(milliseconds: 600));

    final version = data.version;
    final downloadUrl = data.apkUrl;

    final result = await UpdateDownloadService.downloadApk(
      url: downloadUrl,
      version: version,
      onProgress: (progress, totalMB, _) {
        if (mounted && _pageState == _UpdatePageState.downloading) {
          setState(() {
            _downloadProgress = progress;
            _totalMB = totalMB;
          });
        }
      },
    );

    if (!mounted) return;

    if (result.success) {
      setState(() {
        _downloadedFilePath = result.filePath;
        _downloadProgress = 1.0;
        _pageState = _UpdatePageState.done;
      });
      CustomToastService.show(
        context,
        message: 'Descarga completada — MG-Music-v$version.apk',
        type: ToastType.success,
        icon: Ionicons.checkmark_done_outline,
      );
      _installApk();
    } else if (result.message != 'Descarga cancelada') {
      setState(() {
        _pageState = _UpdatePageState.info;
        _errorMessage = result.message;
      });
      CustomToastService.show(
        context,
        message: result.message ?? 'Error en la descarga',
        type: ToastType.error,
      );
    } else {
      setState(() => _pageState = _UpdatePageState.info);
    }
  }

  Future<void> _cancelDownload() async {
    UpdateDownloadService.cancelDownload();

    if (mounted) {
      setState(() {
        _pageState = _UpdatePageState.info;
        _downloadProgress = 0.0;
        _totalMB = 0.0;
      });
    }
  }

  Future<void> _installApk() async {
    if (_downloadedFilePath == null) return;
    try {
      final file = File(_downloadedFilePath!);
      if (!await file.exists()) {
        if (mounted) {
          CustomToastService.show(
            context,
            message: 'Archivo APK no encontrado',
            type: ToastType.error,
          );
        }
        return;
      }
      await _channel.invokeMethod('installApk', {'path': _downloadedFilePath});
    } catch (e) {
      if (mounted) {
        CustomToastService.show(
          context,
          message: 'Error al abrir el instalador: $e',
          type: ToastType.error,
        );
      }
    }
  }

  Future<void> _launchWebsite(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    } catch (_) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        try {
          await launchUrl(uri);
        } catch (_) {}
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    ResponsiveService.init(context);
    final theme = context.watch<ThemeService>();
    final mode = theme.mode;
    final data = _dynamicVersionData;

    return Scaffold(
      backgroundColor: AppColors.background(mode),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: AppGradients.of(
                  mode,
                  GradientDirection.topLeftBottomRight,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              color: AppColors.background(mode).withOpacity(0.42),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: _buildAnimatedContent(mode, data),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildAnimatedContent(AppThemeMode mode, VersionModel? data) {
    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: 800.w),
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          children: [
            SizedBox(height: 8.h),
            AnimationLimiter(
              child: Column(
                children: AnimationConfiguration.toStaggeredList(
                  duration: const Duration(milliseconds: 500),
                  childAnimationBuilder: (widget) => SlideAnimation(
                    verticalOffset: 50.0.h,
                    child: FadeInAnimation(child: widget),
                  ),
                  children: [
                    _buildLogoSection(mode),
                    SizedBox(height: 28.h),
                  ],
                ),
              ),
            ),
            Expanded(
              child: PageTransitionSwitcher(
                duration: const Duration(milliseconds: 500),
                transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
                  return SharedAxisTransition(
                    animation: primaryAnimation,
                    secondaryAnimation: secondaryAnimation,
                    transitionType: SharedAxisTransitionType.horizontal,
                    fillColor: Colors.transparent,
                    child: child,
                  );
                },
                child: _buildStateContent(mode, data),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStateContent(AppThemeMode mode, VersionModel? data) {
    switch (_pageState) {
      case _UpdatePageState.loading:
        return _buildLoadingState(mode, key: const ValueKey('loading'));
      case _UpdatePageState.error:
        return _buildErrorState(mode, key: const ValueKey('error'));
      case _UpdatePageState.upToDate:
        return _buildUpToDateState(mode, data, key: const ValueKey('upToDate'));
      case _UpdatePageState.downloading:
        return _buildDownloadingState(mode, data, key: const ValueKey('downloading'));
      case _UpdatePageState.done:
        return _buildDoneState(mode, data, key: const ValueKey('done'));
      case _UpdatePageState.info:
        return _buildInfoState(mode, data, key: const ValueKey('info'));
    }
  }


  Widget _buildLogoSection(AppThemeMode mode) {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return Column(
          children: [
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlueMid
                        .withOpacity(0.25 * _glowController.value),
                    blurRadius: 28.r,
                    spreadRadius: 4.r,
                  ),
                ],
              ),
              child: Image.asset(
                'assets/MG-I-T.png',
                width: widget.isTv ? 110.r : 72.r,
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              'MG MUSIC',
              style: TextStyle(
                color: AppColors.textPrimary(mode),
                fontSize: 20.sp,
                fontWeight: FontWeight.w900,
                letterSpacing: 4.5,
              ),
            ),
            SizedBox(height: 4.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: AppColors.primaryBlueMid.withOpacity(0.14),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: AppColors.primaryBlueMid.withOpacity(0.35),
                  width: 1.w,
                ),
              ),
              child: Text(
                _pageState == _UpdatePageState.upToDate
                    ? 'AL DÍA'
                    : _dynamicVersionData != null
                        ? 'v${_dynamicVersionData!.version}'
                        : 'ACTUALIZACIÓN',
                style: TextStyle(
                  color: AppColors.primaryBlueMid,
                  fontSize: 9.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        );
      },
    );
  }


  Widget _buildLoadingState(AppThemeMode mode, {Key? key}) {
    return Center(
      key: key,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlueMid),
            strokeWidth: 2.w,
          ),
          SizedBox(height: 20.h),
          Text(
            'Verificando actualizaciones...',
            style: TextStyle(
              color: AppColors.textSecondary(mode),
              fontSize: 13.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(AppThemeMode mode, {Key? key}) {
    return Padding(
      key: key,
      padding: EdgeInsets.all(24.r),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Ionicons.cloud_offline_outline,
              color: Colors.redAccent, size: 56.sp),
          SizedBox(height: 16.h),
          Text(
            'No se pudo verificar',
            style: TextStyle(
              color: AppColors.textPrimary(mode),
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            _errorMessage ?? 'Verifica tu conexión e intenta de nuevo.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary(mode),
              fontSize: 13.sp,
              height: 1.4,
            ),
          ),
          SizedBox(height: 32.h),
          _ActionButton(
            label: 'Reintentar',
            icon: Ionicons.refresh_outline,
            isPrimary: true,
            mode: mode,
            onPressed: () {
              setState(() => _pageState = _UpdatePageState.loading);
              _fetchVersionData();
            },
          ),
          SizedBox(height: 12.h),
          _ActionButton(
            label: 'Cerrar',
            icon: Ionicons.close_outline,
            isPrimary: false,
            mode: mode,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildUpToDateState(AppThemeMode mode, VersionModel? data, {Key? key}) {
    return Padding(
      key: key,
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72.r,
            height: 72.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green.withOpacity(0.12),
              border: Border.all(
                color: Colors.green.withOpacity(0.4),
                width: 1.5.w,
              ),
            ),
            child: Icon(
              Ionicons.checkmark_done_circle_outline,
              color: Colors.green,
              size: 38.sp,
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            '¡Estás al día!',
            style: TextStyle(
              color: AppColors.textPrimary(mode),
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            data != null
                ? 'La versión v${data.version} es la más reciente disponible.'
                : 'Ya tienes la última versión instalada.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary(mode),
              fontSize: 13.sp,
              height: 1.4,
            ),
          ),
          SizedBox(height: 40.h),
          _ActionButton(
            label: 'Cerrar',
            icon: Ionicons.checkmark_outline,
            isPrimary: true,
            mode: mode,
            onPressed: () => Navigator.of(context).pop(),
          ),
          SizedBox(height: 12.h),
          _ActionButton(
            label: 'Descargar (ya actualizado)',
            icon: Ionicons.download_outline,
            isPrimary: false,
            mode: mode,
            isDisabled: true,
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildInfoState(AppThemeMode mode, VersionModel? data, {Key? key}) {
    if (data == null) {
      return _buildLoadingState(mode, key: key);
    }
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape ||
            widget.isTv;

    return AnimationLimiter(
      key: key,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: AnimationConfiguration.toStaggeredList(
            duration: const Duration(milliseconds: 550),
            childAnimationBuilder: (w) => SlideAnimation(
              verticalOffset: 40.h,
              child: FadeInAnimation(child: w),
            ),
            children: [
              if (isLandscape)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildInfoCard(mode, data)),
                    SizedBox(width: 24.w),
                    Expanded(child: _buildActionButtons(mode, data)),
                  ],
                )
              else ...[
                _buildInfoCard(mode, data),
                SizedBox(height: 24.h),
                _buildActionButtons(mode, data),
                SizedBox(height: 24.h),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(AppThemeMode mode, VersionModel data) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.all(18.r),
          decoration: BoxDecoration(
            color: AppColors.surface(mode)
                .withOpacity(mode == AppThemeMode.dark ? 0.18 : 0.38),
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(
              color: AppColors.themeBorder(mode).withOpacity(0.3),
              width: 1.w,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'v${data.version}',
                    style: TextStyle(
                      color: AppColors.textPrimary(mode),
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: _importanceColor(data.importance).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      _importanceName(data.importance),
                      style: TextStyle(
                        color: _importanceColor(data.importance),
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6.h),
              Text(
                data.title,
                style: TextStyle(
                  color: AppColors.textPrimary(mode).withOpacity(0.75),
                  fontSize: 13.sp,
                  height: 1.3,
                ),
              ),
              SizedBox(height: 14.h),
              Text(
                'NOVEDADES',
                style: TextStyle(
                  color: AppColors.textSecondary(mode).withOpacity(0.6),
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.4,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                data.changelog,
                style: TextStyle(
                  color: AppColors.textPrimary(mode).withOpacity(0.88),
                  fontSize: 13.sp,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(AppThemeMode mode, VersionModel data) {
    return FocusTraversalGroup(
      child: Column(
        children: [
          _ActionButton(
            label: 'Descargar e Instalar',
            icon: Ionicons.download_outline,
            isPrimary: true,
            mode: mode,
            isTv: widget.isTv,
            autofocus: widget.isTv,
            onPressed: _startDownload,
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: 'Ver en la Web',
                  icon: Ionicons.globe_outline,
                  isPrimary: false,
                  mode: mode,
                  isTv: widget.isTv,
                  onPressed: () => _launchWebsite(data.websiteUrl),
                ),
              ),
              if (!data.forceUpdate) ...[
                SizedBox(width: 12.w),
                Expanded(
                  child: _ActionButton(
                    label: 'Ahora no',
                    icon: Ionicons.time_outline,
                    isPrimary: false,
                    isDestructive: true,
                    mode: mode,
                    isTv: widget.isTv,
                    onPressed: () async {
                      // Activar el snooze de 2 días
                      final prefs = await SharedPreferences.getInstance();
                      final now = DateTime.now().millisecondsSinceEpoch;
                      final twoDays = 2 * 24 * 60 * 60 * 1000;
                      await prefs.setInt('update_snoozed_until', now + twoDays);
                      await prefs.setInt('snoozed_version_code', data.versionCode);

                      if (mounted) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const SplashScreen()),
                        );
                      }
                    },
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadingState(AppThemeMode mode, VersionModel? data, {Key? key}) {
    final version = data?.version ?? '';
    final percent = (_downloadProgress * 100).toInt();
    final totalText = _totalMB > 0
        ? '${_totalMB.toStringAsFixed(1)} MB'
        : 'Calculando...';

    return Padding(
      key: key,
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Ionicons.cloud_download_outline,
            size: 52.r,
            color: AppColors.primaryBlueMid,
          ),
          SizedBox(height: 20.h),
          Text(
            _downloadProgress == 0
                ? 'Preparando descarga...'
                : 'Descargando v$version',
            style: TextStyle(
              color: AppColors.textPrimary(mode),
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'MG-Music-v$version.apk',
            style: TextStyle(
              color: AppColors.textSecondary(mode),
              fontSize: 12.sp,
            ),
          ),
          SizedBox(height: 32.h),
          _ProgressBar(value: _downloadProgress, mode: mode),
          SizedBox(height: 10.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$percent%',
                style: TextStyle(
                  color: AppColors.primaryBlueMid,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                totalText,
                style: TextStyle(
                  color: AppColors.textSecondary(mode).withOpacity(0.7),
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 48.h),
          _ActionButton(
            label: 'Cancelar descarga',
            icon: Ionicons.close_circle_outline,
            isPrimary: false,
            isDestructive: true,
            mode: mode,
            onPressed: _cancelDownload,
          ),
        ],
      ),
    );
  }

  Widget _buildDoneState(AppThemeMode mode, VersionModel? data, {Key? key}) {
    return Padding(
      key: key,
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64.r,
            height: 64.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green.withOpacity(0.12),
              border: Border.all(
                color: Colors.green.withOpacity(0.4),
                width: 1.5.w,
              ),
            ),
            child: Icon(
              Ionicons.cloud_done_outline,
              color: Colors.green,
              size: 34.sp,
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            'Descarga completada',
            style: TextStyle(
              color: AppColors.textPrimary(mode),
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            data != null
                ? 'MG-Music-v${data.version}.apk listo para instalar'
                : 'Archivo listo para instalar',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary(mode),
              fontSize: 13.sp,
            ),
          ),
          SizedBox(height: 40.h),
          _ActionButton(
            label: 'Instalar ahora',
            icon: Ionicons.rocket_outline,
            isPrimary: true,
            mode: mode,
            onPressed: () async {
              final confirmed = await GlobalModalService.showConfirmation(
                title: 'Instalar Actualización',
                message:
                    '¿Listo para instalar v${data?.version ?? ''}? La app se cerrará durante el proceso.',
                confirmText: 'Instalar',
                icon: Ionicons.download_outline,
              );
              if (confirmed) _installApk();
            },
          ),
          SizedBox(height: 12.h),
          _ActionButton(
            label: 'Cerrar',
            icon: Ionicons.close_outline,
            isPrimary: false,
            mode: mode,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }


  Color _importanceColor(String importance) {
    switch (importance) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.amber;
      default:
        return AppColors.primaryBlueMid;
    }
  }

  String _importanceName(String importance) {
    switch (importance) {
      case 'critical':
        return 'CRÍTICA';
      case 'high':
        return 'IMPORTANTE';
      case 'medium':
        return 'RECOMENDADA';
      default:
        return 'NORMAL';
    }
  }
}


class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isPrimary;
  final bool isDestructive;
  final bool isDisabled;
  final bool isTv;
  final bool autofocus;
  final AppThemeMode mode;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.mode,
    this.isPrimary = false,
    this.isDestructive = false,
    this.isDisabled = false,
    this.isTv = false,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor =
        isDestructive ? Colors.grey : AppColors.primaryBlueMid;

    Widget interiorContent = Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isPrimary ? Colors.white : accentColor,
            size: 18.sp,
          ),
          SizedBox(width: 8.w),
          Text(
            label,
            style: TextStyle(
              color: isPrimary
                  ? Colors.white
                  : AppColors.textPrimary(mode).withOpacity(0.85),
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    Widget buttonContent = Opacity(
      opacity: isDisabled ? 0.38 : 1.0,
      child: Container(
        height: 50.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14.r),
          gradient: isPrimary
              ? LinearGradient(
                  colors: AppColors.fabGradient(mode),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: !isPrimary
              ? AppColors.surface(mode).withOpacity(0.08)
              : null,
          border: Border.all(
            color: isPrimary
                ? AppColors.fabAccent(mode).withOpacity(0.5)
                : accentColor.withOpacity(0.18),
            width: 1.2.w,
          ),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: AppColors.primaryBlueMid.withOpacity(0.18),
                    blurRadius: 12.r,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: isTv
            ? interiorContent // En TV quitamos el Material/InkWell para que no interfiera
            : Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isDisabled ? null : onPressed,
                  borderRadius: BorderRadius.circular(14.r),
                  child: interiorContent,
                ),
              ),
      ),
    );

    if (isTv) {
      return TvFocusableItem(
        onTap: isDisabled ? null : onPressed,
        autofocus: autofocus,
        borderRadius: 14.r,
        child: buttonContent,
      );
    }

    return buttonContent;
  }
}

class _ProgressBar extends StatelessWidget {
  final double value;
  final AppThemeMode mode;

  const _ProgressBar({required this.value, required this.mode});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 12.h,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface(mode).withOpacity(0.18),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: AppColors.primaryBlueMid.withOpacity(0.25),
          width: 1.w,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.r),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: value.clamp(0.0, 1.0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: AppColors.fabGradient(mode),
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(8.r),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlueMid.withOpacity(0.35),
                  blurRadius: 6.r,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
