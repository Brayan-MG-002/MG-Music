// Copyright © 2026 Brayan Medrano - MG Music
// Servicio reutilizable para gestionar acciones de playlists (Añadir/Crear)

import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:mg_music/services/logic/playlist_manager.dart';
import 'package:mg_music/services/models/song_model.dart';
import 'package:mg_music/services/ui/custom_toast_service.dart';
import 'package:mg_music/services/ui/global_modal_service.dart';
import 'package:flutter/services.dart';

class PlaylistActionService {
  // Constante interna para la opción de crear nueva playlist
  static const String _createNewPlaylistOption = '__CREATE_NEW_PLAYLIST__';

  /// Muestra el flujo completo para añadir una canción a una playlist:
  /// 1. Seleccionar existente o crear nueva.
  /// 2. Si es nueva, pedir nombre.
  /// 3. Confirmar si ya existe o crearla.
  /// 4. Añadir la canción y mostrar feedback.
  static Future<void> showAddToPlaylistDialog(
    BuildContext context,
    LocalSong song,
  ) async {
    final playlistManager = PlaylistManager();

    // 1. Mostrar modal para seleccionar playlist existente o crear nueva
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
      return; // El usuario canceló
    }

    if (selectedOption == _createNewPlaylistOption) {
      // 2. Si eligió "Crear Nueva", mostramos el input
      final inputKey = GlobalKey<_NewPlaylistInputContentState>();
      final cancelFocus = FocusNode();
      final createFocus = FocusNode();
      final textFocus = FocusNode();

      // Usamos el navigatorKey global para asegurar que el contexto del diálogo sea correcto al cerrar
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
                // Si ya existe, pedimos confirmación
                final addToExisting = await GlobalModalService.showConfirmation(
                  title: "Playlist Existente",
                  message:
                      "Ya existe una playlist llamada '$name'.\n¿Deseas añadir la canción a esta playlist o cambiar el nombre?",
                  confirmText: "Añadir",
                  cancelText: "Cambiar Nombre",
                  confirmButtonColor: Colors.blue.shade900,
                );

                if (addToExisting) {
                  // 1. Añadimos a la existente
                  playlistManager.addSongToPlaylist(name, song);
                  // 2. Cerramos el modal de Input
                  if (navigatorContext.mounted) {
                    Navigator.pop(navigatorContext);
                  }
                  // 3. Feedback
                  CustomToastService.show(
                    navigatorContext,
                    message: 'Añadida a "$name"',
                    type: ToastType.success,
                  );
                } else {
                  // Si cancela, nos quedamos en el input para que cambie el nombre
                  state.setError('Por favor, elige otro nombre.');
                }
              } else {
                // Si no existe, retornamos el nombre para crearlo fuera
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
      // Usuario seleccionó una existente directamente
      playlistManager.addSongToPlaylist(selectedOption, song);
      CustomToastService.show(
        context,
        message: 'Añadida a "$selectedOption"',
        type: ToastType.success,
      );
    }
  }

  /// Muestra solo el flujo de creación de playlist (sin canción asociada).
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

  /// Renombra una playlist existente mostrando un modal con input enfocable para TV.
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

/// Widget interno para gestionar el input y el estado de error
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
        style: const TextStyle(color: Colors.white),
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
          hintStyle: TextStyle(color: Colors.grey.shade600),
          errorText: _errorText,
          errorStyle: const TextStyle(color: Colors.redAccent),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade800),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.blue.shade900),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.redAccent),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.redAccent),
          ),
          filled: true,
          fillColor: Colors.grey.shade900,
        ),
      ),
    );
  }
}
