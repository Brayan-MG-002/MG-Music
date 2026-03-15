import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

class SearchRotatingArtwork extends StatefulWidget {
  final Uint8List? artwork;
  final bool isPlaying;
  final bool isAdo;

  const SearchRotatingArtwork({
    super.key,
    required this.artwork,
    required this.isPlaying,
    required this.isAdo,
  });

  @override
  State<SearchRotatingArtwork> createState() => _SearchRotatingArtworkState();
}

class _SearchRotatingArtworkState extends State<SearchRotatingArtwork>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  /// Inicializa la rotación y la sincroniza con reproducción
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    if (!widget.isPlaying) _controller.stop();
  }

  @override
  /// Actualiza el estado de rotación si cambia reproducción
  void didUpdateWidget(covariant SearchRotatingArtwork oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      widget.isPlaying ? _controller.repeat() : _controller.stop();
    }
  }

  @override
  /// Libera el controlador
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  /// Construye la carátula con borde especial para Ado
  Widget build(BuildContext context) {
    return RotationTransition(
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
    );
  }
}
