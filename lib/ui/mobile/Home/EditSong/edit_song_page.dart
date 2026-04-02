// Copyright © 2026 Brayan Medrano - MG Music
// Pantalla de edición de metadatos de canción

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:ionicons/ionicons.dart';
import 'package:mg_music/services/models/song_model.dart';
import 'package:mg_music/services/ui/responsive_service.dart';
import 'package:mg_music/services/ui/theme_service.dart';
import 'package:mg_music/services/ui/custom_toast_service.dart';
import 'package:mg_music/services/logic/song_fetcher.dart';
import 'package:mg_music/services/audio/audio_player_manager.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:audiotags/audiotags.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import 'package:mg_music/ui/tv/tv_focusable_item.dart';

class EditSongPage extends StatefulWidget {
  final LocalSong song;

  const EditSongPage({super.key, required this.song});

  @override
  State<EditSongPage> createState() => _EditSongPageState();
}

class _EditSongPageState extends State<EditSongPage> {
  late TextEditingController _titleController;
  late TextEditingController _artistController;
  
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _artistFocusNode = FocusNode();
  final FocusNode _saveFocusNode = FocusNode();
  final FocusNode _cancelFocusNode = FocusNode();
  final FocusNode _artworkFocusNode = FocusNode();
  final FocusNode _downloadFocusNode = FocusNode();

  Uint8List? _newArtwork;
  Uint8List? _initialArtwork;
  late String _initialTitle;
  late String _initialArtist;
  bool _isSaving = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.song.title);
    _artistController = TextEditingController(text: widget.song.artist);
    _initialTitle = widget.song.title;
    _initialArtist = widget.song.artist;
    _newArtwork = widget.song.artwork;
    _initialArtwork = widget.song.artwork;

    _titleController.addListener(_checkForChanges);
    _artistController.addListener(_checkForChanges);
  }

  void _checkForChanges() {
    final titleChanged = _titleController.text.trim() != _initialTitle;
    final artistChanged = _artistController.text.trim() != _initialArtist;
    final artworkChanged = !listEquals(_newArtwork, _initialArtwork);

    if (mounted) {
      setState(() {
        _hasChanges = titleChanged || artistChanged || artworkChanged;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _titleFocusNode.dispose();
    _artistFocusNode.dispose();
    _saveFocusNode.dispose();
    _cancelFocusNode.dispose();
    _artworkFocusNode.dispose();
    _downloadFocusNode.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _newArtwork = bytes;
      });
      _checkForChanges();
    }
  }

  Future<void> _downloadArtwork() async {
    if (_newArtwork == null) {
      CustomToastService.show(
        context,
        message: "No hay carátula para descargar",
        type: ToastType.error,
      );
      return;
    }

    try {
      if (Platform.isAndroid) {
        if (!await Permission.storage.request().isGranted &&
            !await Permission.manageExternalStorage.request().isGranted) {
          CustomToastService.show(
            context,
            message: "Permiso de almacenamiento denegado",
            type: ToastType.error,
          );
          return;
        }

        final directory = Directory('/storage/emulated/0/Pictures/MG Music');
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }

        final fileName =
            "${widget.song.title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')}_artwork.png";
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(_newArtwork!);

        CustomToastService.show(
          context,
          message: "Carátula guardada en Pictures/MG Music",
          type: ToastType.success,
          icon: Ionicons.download_outline,
        );
      }
    } catch (e) {
      CustomToastService.show(
        context,
        message: "Error al descargar: $e",
        type: ToastType.error,
      );
    }
  }

  Future<void> _saveChanges() async {
    if (_titleController.text.trim().isEmpty) {
      CustomToastService.show(
        context,
        message: "El título no puede estar vacío",
        type: ToastType.error,
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final tag = Tag(
        title: _titleController.text.trim(),
        trackArtist: _artistController.text.trim(),
        albumArtist: _artistController.text.trim(),
        pictures: _newArtwork != null
            ? [
                Picture(
                  bytes: _newArtwork!,
                  mimeType: MimeType.png,
                  pictureType: PictureType.coverFront,
                ),
              ]
            : [],
      );

      await AudioTags.write(widget.song.path, tag);

      await SongFetcher.saveOverride(
        widget.song.path,
        _titleController.text.trim(),
        _artistController.text.trim(),
        _newArtwork,
      );

      SongFetcher.clearCache();
      SongFetcher.onLibraryChanged.value++;

      if (!context.mounted) return;

      CustomToastService.show(
        context,
        message: "Pista editada",
        type: ToastType.success,
        icon: Ionicons.save_outline,
      );
      Navigator.of(context).maybePop();
    } catch (e) {
      if (!context.mounted) return;
      CustomToastService.show(
        context,
        message: "Error al guardar: $e",
        type: ToastType.error,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _formatDuration(int? ms) {
    if (ms == null) return "--:--";
    final duration = Duration(milliseconds: ms);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return "$minutes:${seconds.toString().padLeft(2, '0')}";
  }

  String _formatPath(String path) {
    const storagePattern = '/storage/emulated/0';
    if (path.startsWith(storagePattern)) {
      return path.replaceFirst(storagePattern, 'Dispositivo');
    }
    return path;
  }

  @override
  Widget build(BuildContext context) {
    final mode = context.watch<ThemeService>().mode;
    final isTv = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimationLimiter(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isTv ? 40.w : 24.w, 
            vertical: isTv ? 30.h : 20.h
          ),
          child: Column(
            children: AnimationConfiguration.toStaggeredList(
              duration: const Duration(milliseconds: 600),
              childAnimationBuilder: (widget) => SlideAnimation(
                verticalOffset: 20.0,
                child: FadeInAnimation(child: widget),
              ),
              children: [
                ValueListenableBuilder<LocalSong?>(
                  valueListenable: AudioPlayerManager().currentSongNotifier,
                  builder: (context, playingSong, _) {
                    final isSameAsPlaying = playingSong?.id == widget.song.id;

                    if (isTv) {
                      return _buildTvLayout(mode, isSameAsPlaying);
                    }
                    return _buildMobileLayout(mode, isSameAsPlaying);
                  },
                ),
                SizedBox(height: isTv ? 40.h : 120.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(AppThemeMode mode, bool isSameAsPlaying) {
    return Column(
      children: [
        if (isSameAsPlaying) _buildPlaybackWarning(),
        _buildArtworkPreview(mode, isSameAsPlaying, isTv: false),
        SizedBox(height: 20.h),
        _buildDownloadButton(mode, isSameAsPlaying, isTv: false),
        SizedBox(height: 12.h),
        _buildTextField(
          controller: _titleController,
          focusNode: _titleFocusNode,
          label: "Título",
          icon: Ionicons.text_outline,
          mode: mode,
          enabled: !isSameAsPlaying,
        ),
        SizedBox(height: 12.h),
        _buildTextField(
          controller: _artistController,
          focusNode: _artistFocusNode,
          label: "Artista",
          icon: Ionicons.person_outline,
          mode: mode,
          enabled: !isSameAsPlaying,
        ),
        SizedBox(height: 16.h),
        _buildDetailsContainer(mode),
        SizedBox(height: 20.h),
        _buildActionButtons(mode, isSameAsPlaying, isTv: false),
      ],
    );
  }

  Widget _buildTvLayout(AppThemeMode mode, bool isSameAsPlaying) {
    return Column(
      children: [
        if (isSameAsPlaying) _buildPlaybackWarning(),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Columna Izquierda: Arte
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  _buildArtworkPreview(mode, isSameAsPlaying, isTv: true),
                  SizedBox(height: 24.h),
                  _buildDownloadButton(mode, isSameAsPlaying, isTv: true),
                ],
              ),
            ),
            SizedBox(width: 40.w),
            // Columna Derecha: Campos y Detalles
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  _buildTextField(
                    controller: _titleController,
                    focusNode: _titleFocusNode,
                    label: "Título",
                    icon: Ionicons.text_outline,
                    mode: mode,
                    enabled: !isSameAsPlaying,
                  ),
                  SizedBox(height: 16.h),
                  _buildTextField(
                    controller: _artistController,
                    focusNode: _artistFocusNode,
                    label: "Artista",
                    icon: Ionicons.person_outline,
                    mode: mode,
                    enabled: !isSameAsPlaying,
                  ),
                  SizedBox(height: 24.h),
                  _buildDetailsContainer(mode),
                  SizedBox(height: 32.h),
                  _buildActionButtons(mode, isSameAsPlaying, isTv: true),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlaybackWarning() {
    return Container(
      margin: EdgeInsets.only(bottom: 20.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.orange.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(Ionicons.warning_outline, color: Colors.orange, size: 20.r),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              "No se puede editar mientras se reproduce o está cargada en el reproductor.",
              style: TextStyle(
                color: Colors.orange,
                fontSize: 11.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtworkPreview(AppThemeMode mode, bool isSameAsPlaying, {required bool isTv}) {
    Widget artwork = Container(
      width: isTv ? 250.r : 150.r,
      height: isTv ? 250.r : 150.r,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isSameAsPlaying
              ? AppColors.textSecondary(mode).withOpacity(0.2)
              : AppColors.primaryBlueMid,
          width: 2.5.r,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: Opacity(
          opacity: isSameAsPlaying ? 0.5 : 1.0,
          child: _newArtwork != null
              ? Image.memory(_newArtwork!, fit: BoxFit.cover)
              : Container(
                  color: AppColors.imagePlaceholder(mode),
                  child: Center(
                    child: Icon(
                      Ionicons.musical_note,
                      size: isTv ? 100.r : 60.r,
                      color: AppColors.textSecondary(mode),
                    ),
                  ),
                ),
        ),
      ),
    );

    if (isTv) {
      return TvFocusableItem(
        focusNode: _artworkFocusNode,
        onTap: isSameAsPlaying ? null : _pickImage,
        borderRadius: 16.r,
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            artwork,
            if (!isSameAsPlaying) _buildCamIcon(),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: isSameAsPlaying ? null : _pickImage,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          artwork,
          if (!isSameAsPlaying) _buildCamIcon(),
        ],
      ),
    );
  }

  Widget _buildCamIcon() {
    return Container(
      margin: EdgeInsets.all(8.r),
      padding: EdgeInsets.all(8.r),
      decoration: BoxDecoration(
        color: AppColors.primaryBlueMid,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Icon(Ionicons.camera, size: 18.r, color: Colors.white),
    );
  }

  Widget _buildDownloadButton(AppThemeMode mode, bool isSameAsPlaying, {required bool isTv}) {
    final color = isSameAsPlaying
        ? AppColors.textSecondary(mode).withOpacity(0.5)
        : AppColors.primaryBlueMid;

    Widget child = Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Ionicons.download_outline, color: color, size: isTv ? 24.r : 18.r),
          SizedBox(width: 8.w),
          Text(
            "Descargar Carátula",
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: isTv ? 16.sp : 12.sp),
          ),
        ],
      ),
    );

    if (isTv) {
      return TvFocusableItem(
        focusNode: _downloadFocusNode,
        onTap: isSameAsPlaying ? null : _downloadArtwork,
        borderRadius: 8.r,
        child: child,
      );
    }

    return GestureDetector(
      onTap: isSameAsPlaying ? null : _downloadArtwork,
      child: child,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required IconData icon,
    required AppThemeMode mode,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w, bottom: 4.h),
          child: Text(
            label,
            style: TextStyle(
              color: enabled ? AppColors.textSecondary(mode) : AppColors.textSecondary(mode).withOpacity(0.5),
              fontSize: 11.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: enabled
                ? AppColors.background(mode).withOpacity(0.5)
                : AppColors.background(mode).withOpacity(0.2),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: enabled ? AppColors.primaryBlueMid : AppColors.textSecondary(mode).withOpacity(0.2),
              width: 1.2.r,
            ),
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            enabled: enabled,
            style: TextStyle(
              color: enabled ? AppColors.textPrimary(mode) : AppColors.textPrimary(mode).withOpacity(0.5),
              fontSize: 13.sp,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppColors.primaryBlueMid, size: 18.r),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsContainer(AppThemeMode mode) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.background(mode).withOpacity(0.2),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.primaryBlueMid.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          _buildReadOnlyDetail(
            label: "Almacenamiento",
            value: _formatPath(widget.song.path),
            icon: Ionicons.folder_open_outline,
            mode: mode,
          ),
          SizedBox(height: 16.h),
          _buildReadOnlyDetail(
            label: "Duración",
            value: _formatDuration(widget.song.duration),
            icon: Ionicons.time_outline,
            mode: mode,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(AppThemeMode mode, bool isSameAsPlaying, {required bool isTv}) {
    Widget cancelButton = Container(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.background(mode).withOpacity(0.4),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.textSecondary(mode).withOpacity(0.1)),
      ),
      child: Center(
        child: Text(
          "CANCELAR",
          style: TextStyle(
            color: AppColors.textSecondary(mode),
            fontWeight: FontWeight.bold,
            fontSize: 12.sp,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );

    Widget saveButton = AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: (_hasChanges && !isSameAsPlaying) ? 1.0 : 0.4,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: (_hasChanges && !isSameAsPlaying)
                ? [AppColors.primaryBlueMid, AppColors.background(mode)]
                : [AppColors.textSecondary(mode).withOpacity(0.2), AppColors.background(mode)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: (_hasChanges && !isSameAsPlaying)
              ? [BoxShadow(color: AppColors.primaryBlueMid.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))]
              : [],
        ),
        child: Center(
          child: _isSaving
              ? SizedBox(height: 20.r, width: 20.r, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(
                  "GUARDAR CAMBIOS",
                  style: TextStyle(
                    color: (_hasChanges && !isSameAsPlaying) ? Colors.white : AppColors.textSecondary(mode),
                    fontWeight: FontWeight.bold,
                    fontSize: 12.sp,
                    letterSpacing: 1.0,
                  ),
                ),
        ),
      ),
    );

    if (isTv) {
      return Row(
        children: [
          Expanded(
            child: TvFocusableItem(
              focusNode: _cancelFocusNode,
              onTap: () => Navigator.of(context).maybePop(),
              borderRadius: 12.r,
              child: cancelButton,
            ),
          ),
          SizedBox(width: 20.w),
          Expanded(
            flex: 2,
            child: TvFocusableItem(
              focusNode: _saveFocusNode,
              onTap: (_isSaving || !_hasChanges || isSameAsPlaying) ? null : _saveChanges,
              borderRadius: 12.r,
              child: saveButton,
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: GestureDetector(onTap: () => Navigator.of(context).maybePop(), child: cancelButton)),
        SizedBox(width: 12.w),
        Expanded(flex: 2, child: GestureDetector(onTap: (_isSaving || !_hasChanges || isSameAsPlaying) ? null : _saveChanges, child: saveButton)),
      ],
    );
  }

  Widget _buildReadOnlyDetail({
    required String label,
    required String value,
    required IconData icon,
    required AppThemeMode mode,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20.r, color: AppColors.primaryBlueMid),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: AppColors.textSecondary(mode), fontSize: 10.sp, fontWeight: FontWeight.bold),
              ),
              Text(
                value,
                style: TextStyle(color: AppColors.textPrimary(mode).withOpacity(0.7), fontSize: 11.sp),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

