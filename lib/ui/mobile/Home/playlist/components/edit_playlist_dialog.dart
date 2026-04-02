// Copyright © 2026 Brayan Medrano - MG Music
// Diálogo para editar nombre y carátula de una playlist

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ionicons/ionicons.dart';
import 'package:mg_music/services/logic/playlist_manager.dart';
import 'package:mg_music/services/models/song_model.dart';
import 'package:mg_music/services/ui/custom_toast_service.dart';
import 'package:mg_music/services/ui/global_modal_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:mg_music/services/ui/theme_service.dart';
import 'package:mg_music/services/ui/responsive_service.dart';

class EditPlaylistDialog extends StatefulWidget {
  final String playlistName;
  final List<LocalSong> songs;
  final PlaylistManager playlistManager;

  const EditPlaylistDialog({
    super.key,
    required this.playlistName,
    required this.songs,
    required this.playlistManager,
  });

  @override
  State<EditPlaylistDialog> createState() => _EditPlaylistDialogState();
}

class _EditPlaylistDialogState extends State<EditPlaylistDialog> {
  late final TextEditingController _nameController;
  final ImagePicker _picker = ImagePicker();

  String _selectedCoverIdentifier = '';
  Uint8List? _selectedCoverBytes;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.playlistName);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadInitialCover();
    });
  }


  Future<void> _loadInitialCover() async {
    final prefs = await SharedPreferences.getInstance();
    final coverId =
        prefs.getString('playlist_cover_${widget.playlistName}') ?? 'DEFAULT';
    await _selectCover(coverId, fromInit: true);
  }


  Future<void> _selectCover(String identifier, {bool fromInit = false}) async {
    Uint8List? imageBytes;
    String effectiveIdentifier = identifier;

    if (identifier == 'APP_LOGO') {
      try {
        final byteData = await DefaultAssetBundle.of(
          context,
        ).load('assets/MG-I-T.png');
        imageBytes = byteData.buffer.asUint8List();
      } catch (_) {
        effectiveIdentifier = 'DEFAULT';
      }
    } else if (identifier.startsWith('SONG_ID:')) {
      final songId = int.tryParse(identifier.split(':')[1]);
      if (songId != null) {
        final matches = widget.songs.where((s) => s.id == songId);
        if (matches.isNotEmpty) {
          imageBytes = matches.first.artwork;
        }
      }
    } else if (identifier.startsWith('FILE:')) {
      final filePath = identifier.substring(5);
      final file = File(filePath);
      
      if (file.existsSync()) {
        try {
          imageBytes = await file.readAsBytes();
        } catch (_) {}
      }

      if (imageBytes == null) {

        if (!fromInit) {
          CustomToastService.show(
            context,
            message: 'La imagen local no se encontró.',
            type: ToastType.warning,
          );
        }
        effectiveIdentifier = 'DEFAULT';
      }
    }

    if (!mounted) return;

    setState(() {
      _selectedCoverIdentifier = effectiveIdentifier;
      _selectedCoverBytes = imageBytes;
    });
  }


  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        await _selectCover('FILE:${image.path}');
      }
    } catch (e) {
      CustomToastService.show(
        context,
        message: 'Error al seleccionar imagen: $e',
        type: ToastType.error,
      );
    }
  }


  Future<void> _saveChanges() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final oldName = widget.playlistName;

    if (newName != oldName) {
      await widget.playlistManager.renamePlaylist(oldName, newName);
      final oldCover = prefs.getString('playlist_cover_$oldName');
      if (oldCover != null) {
        await prefs.setString('playlist_cover_$newName', oldCover);
        await prefs.remove('playlist_cover_$oldName');
      }
    }

    final coverKey = 'playlist_cover_$newName';
    if (_selectedCoverIdentifier == 'DEFAULT') {
      await prefs.remove(coverKey);
    } else {
      await prefs.setString(coverKey, _selectedCoverIdentifier);
    }

    if (mounted) {
      Navigator.of(context).pop(newName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mode = context.watch<ThemeService>().mode;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Nombre', style: TextStyle(color: AppColors.primaryBlueMid, fontSize: 13.sp)),
        SizedBox(height: 8.h),
        TextField(
          controller: _nameController,
          style: TextStyle(color: AppColors.textPrimary(mode)),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surface(mode),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.themeBorder(mode)),
              borderRadius: BorderRadius.circular(10.r),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.primaryBlueMid),
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
        ),
        SizedBox(height: 20.h),
        Text('Carátula', style: TextStyle(color: AppColors.primaryBlueMid, fontSize: 13.sp)),
        SizedBox(height: 10.h),
        _buildCoverOptions(mode),
        SizedBox(height: 25.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ModalActionButton(
              label: 'Cancelar',
              onPressed: () => Navigator.pop(context),
              color: AppColors.textSecondary(mode),
            ),
            ModalActionButton(
              label: 'Guardar',
              onPressed: _saveChanges,
              color: AppColors.primaryBlueMid,
            ),
          ],
        ),
      ],
    );
  }


  Widget _buildCoverOptions(AppThemeMode mode) {
    final songsWithArtwork = widget.songs
        .where((s) => s.artwork != null)
        .toList();

    return SizedBox(
      height: 120.h,
      width: double.maxFinite,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildCoverChoice(
            identifier: 'DEFAULT',
            child: Icon(
              Ionicons.musical_notes,
              color: AppColors.textPrimary(mode),
              size: 40.r,
            ),
            label: 'Default',
            mode: mode,
          ),
          _buildCoverChoice(
            identifier: 'APP_LOGO',
            child: Image.asset('assets/MG-I-T.png'),
            label: 'Logo App',
            mode: mode,
          ),
          _buildCoverChoice(
            identifier: 'PICK_LOCAL',
            onTap: _pickImageFromGallery,
            child: Icon(
              Ionicons.folder_open,
              color: AppColors.textPrimary(mode),
              size: 40.r,
            ),
            label: 'Local',
            mode: mode,
          ),
          ...songsWithArtwork.map((song) {
            return _buildCoverChoice(
              identifier: 'SONG_ID:${song.id}',
              child: Image.memory(song.artwork!, fit: BoxFit.cover),
              label: song.title,
              mode: mode,
            );
          }),
        ],
      ),
    );
  }


  Widget _buildCoverChoice({
    required String identifier,
    required Widget child,
    required String label,
    required AppThemeMode mode,
    VoidCallback? onTap,
  }) {
    final isSelected =
        _selectedCoverIdentifier == identifier ||
        (identifier == 'PICK_LOCAL' &&
            _selectedCoverIdentifier.startsWith('FILE:'));

    return GestureDetector(
      onTap: onTap ?? () => _selectCover(identifier),
      child: Container(
        width: 100.w,
        margin: EdgeInsets.only(right: 10.w),
        child: Column(
          children: [
            Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(
                    border: isSelected
                        ? Border.all(color: AppColors.primaryBlueMid, width: 3.w)
                        : Border.all(color: Colors.transparent, width: 3.w),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child:
                        identifier == 'PICK_LOCAL' &&
                            _selectedCoverIdentifier.startsWith('FILE:') &&
                            _selectedCoverBytes != null
                        ? Image.memory(_selectedCoverBytes!, fit: BoxFit.cover)
                        : child,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary(mode),
                fontSize: 12.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
