import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

class SearchRotatingArtwork extends StatefulWidget {
  final Uint8List? artwork;
  final bool isPlaying;
  final bool isAdo;
  final VoidCallback? onTap;

  const SearchRotatingArtwork({
    super.key,
    required this.artwork,
    required this.isPlaying,
    required this.isAdo,
    this.onTap,
  });

  @override
  State<SearchRotatingArtwork> createState() => _SearchRotatingArtworkState();
}

class _SearchRotatingArtworkState extends State<SearchRotatingArtwork>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    if (!widget.isPlaying) _controller.stop();
  }

  @override
  void didUpdateWidget(covariant SearchRotatingArtwork oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      widget.isPlaying ? _controller.repeat() : _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: RotationTransition(
        turns: _controller,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.isAdo ? Colors.blue.shade900 : Colors.transparent,
              width: 2,
            ),
            image: widget.artwork != null
                ? DecorationImage(
                    image: MemoryImage(widget.artwork!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: widget.artwork == null
              ? const Icon(Ionicons.musical_note, color: Colors.white, size: 20)
              : null,
        ),
      ),
    );
  }
}
