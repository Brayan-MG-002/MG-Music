import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:mg_music/services/logic/favorites_manager.dart';
import 'package:mg_music/services/models/song_model.dart';
import 'package:mg_music/services/audio/ado_handler.dart';
import 'package:provider/provider.dart';
import 'package:mg_music/services/ui/theme_service.dart';
import 'package:mg_music/services/ui/responsive_service.dart';
import 'package:mg_music/services/ui/song_context_menu_service.dart';

class MobileSongItem extends StatefulWidget {
  final LocalSong song;
  final bool isAdo;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isGrid;
  final bool isPlaying;
  final bool isSelected;
  final VoidCallback? onEditSong;
  final VoidCallback? onSongDeleted;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onMultiSelect;

  const MobileSongItem({
    super.key,
    required this.song,
    required this.isAdo,
    required this.onTap,
    this.onLongPress,
    required this.isGrid,
    this.isPlaying = false,
    this.isSelected = false,
    this.onEditSong,
    this.onSongDeleted,
    this.onDoubleTap,
    this.onMultiSelect,
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
      duration: const Duration(milliseconds: 400),
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
  void dispose() {
    _controller.dispose();
    _fadeInController.dispose();
    _shakeController.dispose();
    _playingGlowController.dispose();
    super.dispose();
  }

  void _onFavoriteToggled() {
    final isFav = FavoritesManager().isFavorite(widget.song);
    if (isFav && widget.isAdo) {
      _shakeController.forward(from: 0).then((_) => _shakeController.reset());
    }
  }

  void _showOptions(BuildContext context) {
    SongContextMenuService.showOptions(
      context,
      widget.song,
      onFavoriteToggled: _onFavoriteToggled,
      onEditSong: widget.onEditSong,
      onSongDeleted: widget.onSongDeleted,
      onMultiSelect: widget.onMultiSelect,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mode = context.watch<ThemeService>().mode;

    return RepaintBoundary(
      child: GestureDetector(
        onTap: widget.onTap,
        onDoubleTap: widget.onDoubleTap,
        onLongPress: widget.onLongPress ?? () => _showOptions(context),
        child: FadeTransition(
          opacity: _fadeInController,
          child: SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0, 0.1),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: _fadeInController,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                CurvedAnimation(
                  parent: _fadeInController,
                  curve: Curves.easeOutCubic,
                ),
              ),
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _controller,
                  _shakeController,
                  _playingGlowController,
                ]),
                builder: (context, staticContent) {
                  double offsetX = 0;
                  if (_shakeController.isAnimating) {
                    offsetX =
                        5.0 *
                        (0.5 - (0.5 - _shakeController.value).abs()) *
                        4 *
                        (1 - _shakeController.value);
                    if (_shakeController.value > 0.5) offsetX = -offsetX;
                  }

                  final isHQ = AdoHandler.isHighQuality(widget.song);

                  Gradient? borderGradient;
                  Color? borderColor;
                  double borderWidth = widget.isPlaying ? 2.0 : 1.5;

                  if (widget.isSelected) {
                    borderColor = Colors.blueAccent;
                    borderWidth = 2.5.r;
                  } else if (widget.isPlaying) {
                    if (widget.isAdo && isHQ) {
                      borderGradient = const LinearGradient(
                        colors: [Colors.blueAccent, Color(0xFFFFD700)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        stops: [0.4, 1.0],
                      );
                    } else if (!widget.isAdo && isHQ) {
                      borderColor = const Color(0xFFFFD700);
                    } else {
                      borderColor = Colors.blueAccent;
                    }
                  } else {
                    if (widget.isAdo && isHQ) {
                      borderGradient = LinearGradient(
                        colors: [
                          AppColors.themeBorder(mode),
                          const Color(0xFFFFD700),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        stops: const [0.4, 1.0],
                      );
                    } else if (widget.isAdo && !isHQ) {
                      borderColor = AppColors.themeBorder(mode);
                    } else if (!widget.isAdo && isHQ) {
                      borderColor = const Color(0xFFFFD700);
                    }
                  }

                  List<BoxShadow> shadows = [];
                  if (widget.isAdo && widget.isGrid && !widget.isPlaying) {
                    final glowColor = isHQ
                        ? const Color(
                            0xFFFFD700,
                          ).withOpacity(0.3 + (_controller.value * 0.3))
                        : AppColors.adoGlow(
                            mode,
                          ).withOpacity(0.3 + (_controller.value * 0.3));

                    shadows.add(
                      BoxShadow(
                        color: glowColor,
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    );
                  }
                  if (widget.isAdo && widget.isPlaying) {
                    final glowValue =
                        0.5 + (_playingGlowController.value * 0.5);
                    final glowColor = isHQ
                        ? const Color(0xFFFFD700)
                        : Colors.blueAccent;
                    shadows.addAll([
                      BoxShadow(
                        color: glowColor.withOpacity(0.7 * glowValue),
                        blurRadius: 12.0,
                        spreadRadius: 2.0,
                      ),
                    ]);
                  }

                  Widget itemContainer;

                  if (borderGradient != null) {
                    itemContainer = Container(
                      margin: widget.isGrid
                          ? null
                          : EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 4.h,
                            ),
                      padding: EdgeInsets.all(borderWidth),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.r),
                        gradient: borderGradient,
                        boxShadow: shadows.isNotEmpty ? shadows : null,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            12.r - borderWidth,
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: AppColors.songItemGradient(mode),
                          ),
                        ),
                        child: staticContent,
                      ),
                    );
                  } else {
                    itemContainer = Container(
                      margin: widget.isGrid
                          ? null
                          : EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 4.h,
                            ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: AppColors.songItemGradient(mode),
                        ),
                        borderRadius: BorderRadius.circular(12.r),
                        border: borderColor != null
                            ? Border.all(color: borderColor, width: borderWidth)
                            : null,
                        boxShadow: shadows.isNotEmpty ? shadows : null,
                      ),
                      child: staticContent,
                    );
                  }

                  return Transform.translate(
                    offset: Offset(offsetX, 0),
                    child: Stack(
                      children: [
                        itemContainer,
                        if (widget.isSelected)
                          Positioned(
                            top: 8.r,
                            right: 8.r,
                            child: Container(
                              padding: EdgeInsets.all(4.r),
                              decoration: const BoxDecoration(
                                color: Colors.blueAccent,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Ionicons.checkmark,
                                color: Colors.white,
                                size: widget.isGrid ? 14.r : 18.r,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
                child: widget.isGrid
                    ? _buildGridContent(mode)
                    : _buildListContent(mode),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGridContent(AppThemeMode mode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
            child: widget.song.artwork != null
                ? Image.memory(
                    widget.song.artwork!,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                : Container(
                    color: AppColors.imagePlaceholder(mode),
                    child: Center(
                      child: Image.asset('assets/MG-I-T.png', width: 50.r),
                    ),
                  ),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(8.0.r),
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
                  fontSize: 11.sp,
                ),
              ),
              Text(
                widget.song.artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textSecondary(mode),
                  fontSize: 9.sp,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildListContent(AppThemeMode mode) {
    return Row(
      children: [
        Padding(
          padding: EdgeInsets.all(8.0.r),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: widget.song.artwork != null
                ? Image.memory(
                    widget.song.artwork!,
                    width: 64.r,
                    height: 64.r,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 64.r,
                    height: 64.r,
                    color: AppColors.imagePlaceholder(mode),
                    child: Center(
                      child: Image.asset('assets/MG-I-T.png', width: 38.r),
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
                  fontSize: 13.sp,
                ),
              ),
              Text(
                widget.song.artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textSecondary(mode),
                  fontSize: 11.sp,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: Icon(Ionicons.ellipsis_vertical, color: AppColors.icon(mode)),
          onPressed: () => _showOptions(context),
          splashRadius: 20.r,
        ),
      ],
    );
  }
}
