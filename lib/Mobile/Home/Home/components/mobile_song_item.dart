import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:mg_music/Logic/audio_player_manager.dart';
import 'package:mg_music/Logic/favorites_manager.dart';
import 'package:mg_music/Logic/song_model.dart';
import 'package:mg_music/services/bottom_modal_service.dart';
import 'package:mg_music/services/custom_toast_service.dart';
import 'package:mg_music/services/playlist_action_service.dart';
import 'package:provider/provider.dart';
import 'package:mg_music/services/theme_service.dart';

class MobileSongItem extends StatefulWidget {
  final LocalSong song;
  final bool isAdo;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isGrid;
  final bool isPlaying;

  const MobileSongItem({
    super.key,
    required this.song,
    required this.isAdo,
    required this.onTap,
    this.onLongPress,
    required this.isGrid,
    this.isPlaying = false,
  });

  @override
  State<MobileSongItem> createState() => _MobileSongItemState();
}

class _MobileSongItemState extends State<MobileSongItem>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _fadeInController;
  late AnimationController _shakeController;
  late AnimationController _playingGlowController;

  @override
  /// Inicializa controladores de animación según estado inicial
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeInController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    )..forward();
    _playingGlowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    if (widget.isAdo && widget.isGrid && !widget.isPlaying) {
      _controller.repeat(reverse: true);
    }
    if (widget.isAdo && widget.isPlaying) {
      _playingGlowController.repeat(reverse: true);
    }
  }

  @override
  /// Ajusta glows según cambios de props (Ado, reproducción)
  void didUpdateWidget(MobileSongItem oldWidget) {
    super.didUpdateWidget(oldWidget);

    final shouldIdleGlow = widget.isAdo && widget.isGrid && !widget.isPlaying;
    if (shouldIdleGlow && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!shouldIdleGlow && _controller.isAnimating) {
      _controller.stop();
    }

    final shouldPlayingGlow = widget.isAdo && widget.isPlaying;
    if (shouldPlayingGlow && !_playingGlowController.isAnimating) {
      _playingGlowController.repeat(reverse: true);
    } else if (!shouldPlayingGlow && _playingGlowController.isAnimating) {
      _playingGlowController.stop();
      _playingGlowController.reset();
    }
  }

  @override
  /// Libera controladores
  void dispose() {
    _controller.dispose();
    _fadeInController.dispose();
    _shakeController.dispose();
    _playingGlowController.dispose();
    super.dispose();
  }

  /// Reacciona visualmente cuando se marca/desmarca favorito
  void _onFavoriteToggled() {
    final isFav = FavoritesManager().isFavorite(widget.song);
    if (isFav && widget.isAdo) {
      _shakeController.forward(from: 0).then((_) => _shakeController.reset());
    }
  }

  /// Muestra opciones de la canción en un modal inferior
  void _showOptions(BuildContext context) {
    final isFav = FavoritesManager().isFavorite(widget.song);

    BottomModalService.show(
      context,
      title: widget.song.title,
      subtitle: widget.song.artist,
      artwork: widget.song.artwork,
      options: [
        BottomModalOption(
          icon: Ionicons.play_skip_forward_outline,
          label: "Reproducir Siguiente",
          onTap: () {
            AudioPlayerManager().addNext(widget.song);
            Navigator.pop(context);
            CustomToastService.show(
              context,
              message: "Reproduciendo Siguiente",
              type: ToastType.info,
              icon: Ionicons.play_skip_forward,
            );
          },
        ),
        BottomModalOption(
          icon: isFav ? Ionicons.heart_dislike : Ionicons.heart,
          label: isFav ? "Quitar de Favoritos" : "Agregar a Favoritos",
          onTap: () async {
            final success = await FavoritesManager().toggleFavorite(
              widget.song,
            );
            if (!context.mounted) return;

            if (!success) {
              Navigator.pop(context);
              CustomToastService.show(
                context,
                message: 'No puedes desmarcar tu canción principal',
                type: ToastType.error,
              );
              return;
            }

            _onFavoriteToggled();
            Navigator.pop(context);
            CustomToastService.show(
              context,
              message: isFav
                  ? "Eliminado de Favoritos"
                  : "Agregado a Favoritos",
              type: isFav ? ToastType.warning : ToastType.success,
              icon: isFav ? Ionicons.heart_dislike : Ionicons.heart,
            );
          },
        ),
        BottomModalOption(
          icon: Ionicons.add_circle_outline,
          label: "Agregar a Playlist",
          onTap: () {
            Navigator.pop(context);
            PlaylistActionService.showAddToPlaylistDialog(context, widget.song);
          },
        ),
      ],
    );
  }

  @override
  /// Construye el ítem de canción con animaciones (brillo, shake)
  Widget build(BuildContext context) {
    final mode = context.watch<ThemeService>().mode;

    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress ?? () => _showOptions(context),
      child: FadeTransition(
        opacity: _fadeInController,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _controller,
            _shakeController,
            _playingGlowController,
          ]),
          builder: (context, child) {
            double offsetX = 0;
            if (_shakeController.isAnimating) {
              offsetX =
                  5.0 *
                  (0.5 - (0.5 - _shakeController.value).abs()) *
                  4 *
                  (1 - _shakeController.value);
              if (_shakeController.value > 0.5) offsetX = -offsetX;
            }

            Color? borderColor;
            if (widget.isPlaying) {
              borderColor = Colors.blueAccent;
            } else if (widget.isAdo) {
              borderColor = AppColors.themeBorder(mode);
            }

            List<BoxShadow> shadows = [];
            // 1. Brillo de reposo para Ado en Grid
            if (widget.isAdo && widget.isGrid && !widget.isPlaying) {
              final glowColor = AppColors.adoGlow(
                mode,
              ).withOpacity(0.3 + (_controller.value * 0.3));
              shadows.add(
                BoxShadow(color: glowColor, blurRadius: 10, spreadRadius: 1),
              );
            }
            // 2. Brillo animado para Ado en reproducción
            if (widget.isAdo && widget.isPlaying) {
              final glowValue = 0.5 + (_playingGlowController.value * 0.5);
              shadows.addAll([
                BoxShadow(
                  color: Colors.blueAccent.withOpacity(0.7 * glowValue),
                  blurRadius: 12.0,
                  spreadRadius: 2.0,
                ),
              ]);
            }

            return Transform.translate(
              offset: Offset(offsetX, 0),
              child: Container(
                margin: widget.isGrid
                    ? null
                    : const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: AppColors.songItemGradient(mode),
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: borderColor != null
                      ? Border.all(
                          color: borderColor,
                          width: widget.isPlaying ? 2.0 : 1.5,
                        )
                      : null,
                  boxShadow: shadows.isNotEmpty ? shadows : null,
                ),
                child: widget.isGrid
                    ? _buildGridContent(mode)
                    : _buildListContent(mode),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Contenido para modo grilla
  Widget _buildGridContent(AppThemeMode mode) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final double titleFontSize = screenWidth < 350
            ? 10.0
            : (screenWidth > 450 ? 14.0 : 12.0);
        final double artistFontSize = screenWidth < 350
            ? 9.0
            : (screenWidth > 450 ? 11.0 : 10.0);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: widget.song.artwork != null
                    ? Image.memory(
                        widget.song.artwork!,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: AppColors.imagePlaceholder(mode),
                        child: Center(
                          child: Image.asset('assets/MG-I-T.png', width: 50),
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: widget.isPlaying
                          ? Colors.blueAccent
                          : AppColors.textPrimary(mode),
                      fontWeight: FontWeight.bold,
                      fontSize: titleFontSize,
                    ),
                  ),
                  Text(
                    widget.song.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textSecondary(mode),
                      fontSize: artistFontSize,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// Contenido para modo lista
  Widget _buildListContent(AppThemeMode mode) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final double imageSize = screenWidth < 350
            ? 56.0
            : (screenWidth > 450 ? 72.0 : 64.0);
        final double titleFontSize = screenWidth < 350
            ? 13.0
            : (screenWidth > 450 ? 16.0 : 14.0);
        final double artistFontSize = screenWidth < 350
            ? 11.0
            : (screenWidth > 450 ? 13.0 : 12.0);

        return Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: widget.song.artwork != null
                    ? Image.memory(
                        widget.song.artwork!,
                        width: imageSize,
                        height: imageSize,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: imageSize,
                        height: imageSize,
                        color: AppColors.imagePlaceholder(mode),
                        child: Center(
                          child: Image.asset(
                            'assets/MG-I-T.png',
                            width: imageSize * 0.6,
                          ),
                        ),
                      ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: widget.isPlaying
                          ? Colors.blueAccent
                          : AppColors.textPrimary(mode),
                      fontWeight: FontWeight.bold,
                      fontSize: titleFontSize,
                    ),
                  ),
                  Text(
                    widget.song.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textSecondary(mode),
                      fontSize: artistFontSize,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                Ionicons.ellipsis_vertical,
                color: AppColors.icon(mode),
              ),
              onPressed: () => _showOptions(context),
              splashRadius: 20,
            ),
          ],
        );
      },
    );
  }
}
