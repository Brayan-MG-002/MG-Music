import 'package:flutter/material.dart';
import 'package:mg_music/services/models/song_model.dart';
import 'package:mg_music/services/audio/audio_player_manager.dart';
import 'package:mg_music/services/audio/ado_handler.dart';
import 'package:mg_music/services/ui/theme_service.dart';
import 'package:mg_music/services/ui/responsive_service.dart';
import 'package:provider/provider.dart';
import 'package:mg_music/services/ui/song_context_menu_service.dart';

class _CarouselItem {
  final int index;
  final double distance;
  _CarouselItem({required this.index, required this.distance});
}

class AdoSongsCarousel extends StatefulWidget {
  final LocalSong currentSong;
  const AdoSongsCarousel({super.key, required this.currentSong});

  @override
  State<AdoSongsCarousel> createState() => _AdoSongsCarouselState();
}

class _AdoSongsCarouselState extends State<AdoSongsCarousel> with SingleTickerProviderStateMixin {
  List<LocalSong> _adoSongs = [];
  double _scrollOffset = 0.0;
  double get _itemHeight => 55.0.h; 
  double _lastItemHeight = 0.0;
  late AnimationController _snapController;
  late Animation<double> _snapAnimation;

  @override
  void initState() {
    super.initState();
    _updateAdoSongs();
    
    int initialPage = _adoSongs.indexWhere((s) => s.path == widget.currentSong.path);
    if (initialPage == -1) initialPage = 0;
    _scrollOffset = initialPage * _itemHeight;

    _snapController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
  }

  void _updateAdoSongs() {
    final manager = AudioPlayerManager();
    _adoSongs = manager.playlist.where((s) => AdoHandler.isAdo(s)).toList();
    if (_adoSongs.isEmpty) {
      _adoSongs = [widget.currentSong];
    }
  }

  @override
  void didUpdateWidget(AdoSongsCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentSong.path != widget.currentSong.path) {
      _updateAdoSongs();
      int page = _adoSongs.indexWhere((s) => s.path == widget.currentSong.path);
      if (page != -1) {
        _animateTo(page * _itemHeight);
      }
    }
  }

  void _animateTo(double targetOffset) {
    _snapAnimation = Tween<double>(begin: _scrollOffset, end: targetOffset).animate(
      CurvedAnimation(parent: _snapController, curve: Curves.easeOutCubic)
    )..addListener(() {
        setState(() {
          _scrollOffset = _snapAnimation.value;
        });
      });
    _snapController.forward(from: 0.0);
  }

  void _snap() {
    double targetIndex = (_scrollOffset / _itemHeight).roundToDouble();
    targetIndex = targetIndex.clamp(0.0, (_adoSongs.length - 1).toDouble());
    _animateTo(targetIndex * _itemHeight);
  }

  @override
  void dispose() {
    _snapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_adoSongs.isEmpty) return const SizedBox.shrink();
    if (_adoSongs.length == 1 && _adoSongs.first.path == widget.currentSong.path) {
       // Optional: skip if only 1 song
    }
    
    final mode = context.watch<ThemeService>().mode;

    double centerIndexDouble = _scrollOffset / _itemHeight;
    int centerIndex = centerIndexDouble.round();
    int start = (centerIndex - 2).clamp(0, _adoSongs.length - 1);
    int end = (centerIndex + 2).clamp(0, _adoSongs.length - 1);

    // Sincronizar offset si cambió el tamaño (h)
    if (_lastItemHeight > 0 && _lastItemHeight != _itemHeight) {
      double currentIndex = _scrollOffset / _lastItemHeight;
      _scrollOffset = currentIndex * _itemHeight;
    }
    _lastItemHeight = _itemHeight;

    List<_CarouselItem> items = [];
    for (int i = start; i <= end; i++) {
       double distance = (centerIndexDouble - i).abs();
       items.add(_CarouselItem(index: i, distance: distance));
    }
    // SORT BY DISTANCE DESCENDING: Largest distance first, Center (0) LAST.
    // This perfectly solves the Z-index overlap issue!
    items.sort((a, b) => b.distance.compareTo(a.distance));

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight > 0 ? constraints.maxHeight : 180.h;
        final centerHeight = availableHeight / 2;

        List<Widget> children = [];
        for (var item in items) {
           int i = item.index;
           double dist = item.distance;
           
           double scale = (1 - (dist * 0.3)).clamp(0.6, 1.0);
           double opacity = (1 - (dist * 0.5)).clamp(0.0, 1.0);
           double dy = (i * _itemHeight) - _scrollOffset;

           final song = _adoSongs[i];
           final isPlaying = song.path == widget.currentSong.path;
           
           children.add(
             Positioned(
               top: centerHeight - (_itemHeight / 2) + dy,
               left: 0, 
               right: 0,
               child: Opacity(
                 opacity: opacity,
                 child: Transform.scale(
                   scale: scale,
                   child: GestureDetector(
                     onTap: () {
                       if (!isPlaying) {
                          AudioPlayerManager().playSong(song);
                       } else {
                          _animateTo(i * _itemHeight);
                       }
                     },
                     onLongPress: () => SongContextMenuService.showOptions(context, song, showEditDelete: false),
                     child: Container(
                       margin: EdgeInsets.symmetric(horizontal: 10.w),
                       padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                       decoration: BoxDecoration(
                         color: isPlaying ? AppColors.themeBorder(mode).withOpacity(0.15) : Colors.transparent,
                         borderRadius: BorderRadius.circular(15.r),
                         border: isPlaying ? Border.all(color: AppColors.themeBorder(mode), width: 1.5.w) : Border.all(color: Colors.transparent),
                       ),
                       child: Row(
                         children: [
                           ClipRRect(
                             borderRadius: BorderRadius.circular(10.r),
                             child: SizedBox(
                               width: 40.r,
                               height: 40.r,
                               child: song.artwork != null
                                   ? Image.memory(song.artwork!, fit: BoxFit.cover, gaplessPlayback: true)
                                   : Container(color: Colors.grey.withOpacity(0.3), child: const Icon(Icons.music_note)),
                             ),
                           ),
                           SizedBox(width: 15.w),
                           Expanded(
                             child: Text(
                               song.title,
                               maxLines: 1,
                               overflow: TextOverflow.ellipsis,
                               style: TextStyle(
                                 color: AppColors.textPrimary(mode),
                                 fontSize: 13.sp,
                                 fontWeight: isPlaying ? FontWeight.bold : FontWeight.w500,
                               ),
                             ),
                           ),
                         ],
                       ),
                     ),
                   ),
                 ),
               ),
             )
           );
        }

        return Container(
          width: double.infinity,
          height: availableHeight,
          margin: EdgeInsets.symmetric(horizontal: 20.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: AppColors.themeBorder(mode).withOpacity(0.6), width: 1.5.w),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: mode == AppThemeMode.dark
                  ? [AppColors.themeBorder(mode).withOpacity(0.25), Colors.black.withOpacity(0.0)]
                  : [AppColors.themeBorder(mode).withOpacity(0.25), Colors.white.withOpacity(0.0)],
            ),
          ),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragUpdate: (details) {
              setState(() {
                _scrollOffset -= details.primaryDelta!;
                _scrollOffset = _scrollOffset.clamp(0.0, (_adoSongs.length - 1) * _itemHeight);
              });
            },
            onVerticalDragEnd: (details) {
              _snap();
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20.r),
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.hardEdge,
                children: children,
              ),
            ),
          ),
        );
      }
    );
  }
}
