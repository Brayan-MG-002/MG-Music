// Copyright © 2026 Brayan Medrano - MG Music
// Servicio especializado en la gestión de acciones relacionadas con playlists, como creación, adición de canciones y renombrado, con soporte para navegación TV.

import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:mg_music/services/logic/playlist_manager.dart';
import 'package:mg_music/services/models/song_model.dart';
import 'package:mg_music/services/ui/custom_toast_service.dart';
import 'package:mg_music/services/ui/global_modal_service.dart';
import 'package:flutter/services.dart';
import 'package:mg_music/services/ui/responsive_service.dart';

class PlaylistActionService {
  static const String _createNewPlaylistOption = '__CREATE_NEW_PLAYLIST__';

  static Future<void> showAddToPlaylistDialog(
    BuildContext context,
    LocalSong song,
  ) async {
    final playlistManager = PlaylistManager();

    final List<String> playlistOptions = [
      _createNewPlaylistOption,
      ...playlistManager.playlistsNotifier.value,
    ];

    final selectedOption = await GlobalModalService.showSelectionList<String>(
      title: "Añadir a Playlist",
      icon: Ionicons.add_circle,
      items: playlistOptions,
      labelBuilder: (item) {
        if (item == _createNewPlaylistOption) {
          return 'Crear Nueva Playlist';
        }
        return item;
      },
    );

    if (selectedOption == null) {
      return;
    }

    if (selectedOption == _createNewPlaylistOption) {
      final inputKey = GlobalKey<_NewPlaylistInputContentState>();
      final cancelFocus = FocusNode();
      final createFocus = FocusNode();
      final textFocus = FocusNode();

      final navigatorContext = GlobalModalService.navigatorKey.currentContext!;

      final newPlaylistName = await GlobalModalService.show<String>(
        title: "Nueva Playlist",
        icon: Ionicons.create,
        content: _NewPlaylistInputContent(
          key: inputKey,
          nextFocus: createFocus,
          autofocus: true,
          textFocus: textFocus,
        ),
        actions: [
          ModalActionButton(
            label: "Cancelar",
            onPressed: () => Navigator.pop(navigatorContext),
            color: Colors.grey,
            focusNode: cancelFocus,
          ),
          ModalActionButton(
            label: "Crear",
            onPressed: () async {
              final state = inputKey.currentState;
              if (state == null) return;

              final name = state.controller.text.trim();

              if (name.isEmpty) {
                state.setError('El nombre no puede estar vacío');
                return;
              }

              if (playlistManager.playlistsNotifier.value.contains(name)) {
                final addToExisting = await GlobalModalService.showConfirmation(
                  title: "Playlist Existente",
                  message:
                      "Ya existe una playlist llamada '$name'.\n¿Deseas añadir la canción a esta playlist o cambiar el nombre?",
                  confirmText: "Añadir",
                  cancelText: "Cambiar Nombre",
                  confirmButtonColor: Colors.blue.shade900,
                );

                if (addToExisting) {
                  playlistManager.addSongToPlaylist(name, song);
                  if (navigatorContext.mounted) {
                    Navigator.pop(navigatorContext);
                  }
                  CustomToastService.show(
                    navigatorContext,
                    message: 'Añadida a "$name"',
                    type: ToastType.success,
                  );
                } else {
                  state.setError('Por favor, elige otro nombre.');
                }
              } else {
                Navigator.pop(navigatorContext, name);
              }
            },
            color: Colors.blue.shade900,
            focusNode: createFocus,
          ),
        ],
        initialFocus: textFocus,
      );

      if (newPlaylistName != null && newPlaylistName.isNotEmpty) {
        playlistManager.createPlaylist(newPlaylistName);
        playlistManager.addSongToPlaylist(newPlaylistName, song);
        CustomToastService.show(
          context,
          message: 'Playlist "$newPlaylistName" creada y canción añadida',
          type: ToastType.success,
        );
      }
    } else {
      playlistManager.addSongToPlaylist(selectedOption, song);
      CustomToastService.show(
        context,
        message: 'Añadida a "$selectedOption"',
        type: ToastType.success,
      );
    }
  }

  static Future<void> showAddMultipleToPlaylistDialog(
    BuildContext context,
    List<LocalSong> songs,
  ) async {
    if (songs.isEmpty) return;
    final playlistManager = PlaylistManager();

    final List<String> playlistOptions = [
      _createNewPlaylistOption,
      ...playlistManager.playlistsNotifier.value,
    ];

    final selectedOption = await GlobalModalService.showSelectionList<String>(
      title: "Añadir ${songs.length} a Playlist",
      icon: Ionicons.add_circle,
      items: playlistOptions,
      labelBuilder: (item) {
        if (item == _createNewPlaylistOption) {
          return 'Crear Nueva Playlist';
        }
        return item;
      },
    );

    if (selectedOption == null) return;

    if (selectedOption == _createNewPlaylistOption) {
      final inputKey = GlobalKey<_NewPlaylistInputContentState>();
      final cancelFocus = FocusNode();
      final createFocus = FocusNode();
      final textFocus = FocusNode();
      final navigatorContext = GlobalModalService.navigatorKey.currentContext!;

      final newPlaylistName = await GlobalModalService.show<String>(
        title: "Nueva Playlist",
        icon: Ionicons.create,
        content: _NewPlaylistInputContent(
          key: inputKey,
          nextFocus: createFocus,
          autofocus: true,
          textFocus: textFocus,
        ),
        actions: [
          ModalActionButton(
            label: "Cancelar",
            onPressed: () => Navigator.pop(navigatorContext),
            color: Colors.grey,
            focusNode: cancelFocus,
          ),
          ModalActionButton(
            label: "Crear",
            onPressed: () async {
              final state = inputKey.currentState;
              if (state == null) return;
              final name = state.controller.text.trim();
              if (name.isEmpty) {
                state.setError('El nombre no puede estar vacío');
                return;
              }
              if (playlistManager.playlistsNotifier.value.contains(name)) {
                final addToExisting = await GlobalModalService.showConfirmation(
                  title: "Playlist Existente",
                  message: "¿Añadir las canciones a la playlist '$name' existente?",
                  confirmText: "Añadir",
                  cancelText: "Cambiar Nombre",
                  confirmButtonColor: Colors.blue.shade900,
                );
                if (addToExisting) {
                  for (var song in songs) {
                    await playlistManager.addSongToPlaylist(name, song);
                  }
                  if (navigatorContext.mounted) Navigator.pop(navigatorContext);
                  CustomToastService.show(navigatorContext, message: 'Añadidas a "$name"', type: ToastType.success);
                } else {
                  state.setError('Por favor, elige otro nombre.');
                }
              } else {
                Navigator.pop(navigatorContext, name);
              }
            },
            color: Colors.blue.shade900,
            focusNode: createFocus,
          ),
        ],
        initialFocus: textFocus,
      );

      if (newPlaylistName != null && newPlaylistName.isNotEmpty) {
        await playlistManager.createPlaylist(newPlaylistName);
        for (var song in songs) {
          await playlistManager.addSongToPlaylist(newPlaylistName, song);
        }
        CustomToastService.show(context, message: 'Playlist "$newPlaylistName" creada y ${songs.length} pistas añadidas', type: ToastType.success);
      }
    } else {
      for (var song in songs) {
        await playlistManager.addSongToPlaylist(selectedOption, song);
      }
      CustomToastService.show(context, message: 'Añadidas ${songs.length} pistas a "$selectedOption"', type: ToastType.success);
    }
  }

  static Future<void> showCreatePlaylistDialog(BuildContext context) async {
    final playlistManager = PlaylistManager();
    final inputKey = GlobalKey<_NewPlaylistInputContentState>();
    final cancelFocus = FocusNode();
    final createFocus = FocusNode();
    final textFocus = FocusNode();
    final navigatorContext = GlobalModalService.navigatorKey.currentContext!;

    final newPlaylistName = await GlobalModalService.show<String>(
      title: "Nueva Playlist",
      icon: Ionicons.create,
      content: _NewPlaylistInputContent(
        key: inputKey,
        nextFocus: createFocus,
        autofocus: true,
        textFocus: textFocus,
      ),
      actions: [
        ModalActionButton(
          label: "Cancelar",
          onPressed: () => Navigator.pop(navigatorContext),
          color: Colors.grey,
          focusNode: cancelFocus,
        ),
        ModalActionButton(
          label: "Crear",
          onPressed: () async {
            final state = inputKey.currentState;
            if (state == null) return;
            final name = state.controller.text.trim();
            if (name.isEmpty) {
              state.setError('El nombre no puede estar vacío');
              return;
            }
            if (playlistManager.playlistsNotifier.value.contains(name)) {
              state.setError('Ya existe una playlist con ese nombre');
              return;
            }
            await playlistManager.createPlaylist(name);
            Navigator.pop(navigatorContext, name);
          },
          color: Colors.blue.shade900,
          focusNode: createFocus,
        ),
      ],
      initialFocus: textFocus,
    );

    if (newPlaylistName != null && newPlaylistName.isNotEmpty) {
      CustomToastService.show(
        context,
        message: 'Playlist "$newPlaylistName" creada',
        type: ToastType.success,
      );
    }
  }

  static Future<String?> showRenamePlaylistDialog(
    BuildContext context, {
    required String oldName,
  }) async {
    final playlistManager = PlaylistManager();
    final inputKey = GlobalKey<_NewPlaylistInputContentState>();
    final cancelFocus = FocusNode();
    final saveFocus = FocusNode();
    final textFocus = FocusNode();
    final navigatorContext = GlobalModalService.navigatorKey.currentContext!;

    final newName = await GlobalModalService.show<String>(
      title: "Renombrar Playlist",
      icon: Ionicons.pencil,
      content: _NewPlaylistInputContent(
        key: inputKey,
        nextFocus: saveFocus,
        autofocus: true,
        initialText: oldName,
        textFocus: textFocus,
      ),
      actions: [
        ModalActionButton(
          label: "Cancelar",
          onPressed: () => Navigator.pop(navigatorContext),
          color: Colors.grey,
          focusNode: cancelFocus,
        ),
        ModalActionButton(
          label: "Guardar",
          onPressed: () async {
            final state = inputKey.currentState;
            if (state == null) return;
            final name = state.controller.text.trim();
            if (name.isEmpty) {
              state.setError('El nombre no puede estar vacío');
              return;
            }
            if (name == oldName) {
              Navigator.pop(navigatorContext, name);
              return;
            }
            if (playlistManager.playlistsNotifier.value.contains(name)) {
              state.setError('Ya existe una playlist con ese nombre');
              return;
            }
            await playlistManager.renamePlaylist(oldName, name);
            Navigator.pop(navigatorContext, name);
          },
          color: Colors.blue.shade900,
          focusNode: saveFocus,
        ),
      ],
      initialFocus: textFocus,
    );

    if (newName != null && newName.isNotEmpty && newName != oldName) {
      CustomToastService.show(
        context,
        message: 'Renombrada a "$newName"',
        type: ToastType.success,
      );
    }
    return newName;
  }
}

class _NewPlaylistInputContent extends StatefulWidget {
  final FocusNode? nextFocus;
  final bool autofocus;
  final String? initialText;
  final FocusNode? textFocus;
  const _NewPlaylistInputContent({
    super.key,
    this.nextFocus,
    this.autofocus = false,
    this.initialText,
    this.textFocus,
  });

  @override
  State<_NewPlaylistInputContent> createState() =>
      _NewPlaylistInputContentState();
}

class _NewPlaylistInputContentState extends State<_NewPlaylistInputContent> {
  final TextEditingController _textController = TextEditingController();
  late final FocusNode _textFocus;
  late final bool _ownsFocus;
  String? _errorText;

  TextEditingController get controller => _textController;

  void setError(String? error) {
    if (!mounted) return;
    setState(() => _errorText = error);
  }

  @override
  void initState() {
    super.initState();
    _ownsFocus = widget.textFocus == null;
    _textFocus = widget.textFocus ?? FocusNode();
    if (widget.initialText != null) {
      _textController.text = widget.initialText!;
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: _textController.text.length),
      );
    }
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _textFocus.requestFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    if (_ownsFocus) {
      _textFocus.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: (node, event) {
        if (event is KeyUpEvent) {
          final key = event.logicalKey;
          if (key == LogicalKeyboardKey.arrowDown ||
              key == LogicalKeyboardKey.select ||
              key == LogicalKeyboardKey.enter) {
            if (widget.nextFocus != null) {
              FocusScope.of(context).requestFocus(widget.nextFocus);
              return KeyEventResult.handled;
            }
          }
        }
        return KeyEventResult.ignored;
      },
      child: TextField(
        controller: _textController,
        style: TextStyle(color: Colors.white, fontSize: 14.sp),
        cursorColor: Colors.blue.shade900,
        focusNode: _textFocus,
        autofocus: widget.autofocus,
        textInputAction: TextInputAction.done,
        onEditingComplete: () {
          if (widget.nextFocus != null) {
            FocusScope.of(context).requestFocus(widget.nextFocus);
          } else {
            FocusScope.of(context).unfocus();
          }
        },
        onChanged: (value) {
          if (_errorText != null) setError(null);
        },
        decoration: InputDecoration(
          hintText: 'Nombre de la playlist',
          hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14.sp),
          errorText: _errorText,
          errorStyle: TextStyle(color: Colors.redAccent, fontSize: 12.sp),
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.r),
            borderSide: BorderSide(color: Colors.grey.shade800, width: 1.w),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.r),
            borderSide: BorderSide(color: Colors.blue.shade900, width: 1.2.w),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.r),
            borderSide: BorderSide(color: Colors.redAccent, width: 1.w),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.r),
            borderSide: BorderSide(color: Colors.redAccent, width: 1.2.w),
          ),
          filled: true,
          fillColor: Colors.grey.shade900,
        ),
      ),
    );
  }
}
