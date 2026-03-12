import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import 'package:mg_music/services/theme_service.dart';

class MobilePlaylistShimmer extends StatefulWidget {
  final bool isGridView;

  const MobilePlaylistShimmer({super.key, required this.isGridView});

  @override
  State<MobilePlaylistShimmer> createState() => _MobilePlaylistShimmerState();
}

class _MobilePlaylistShimmerState extends State<MobilePlaylistShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  /// Inicializa controlador del shimmer
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  /// Libera el controlador
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  /// Construye shimmer en grilla o lista
  Widget build(BuildContext context) {
    final mode = context.watch<ThemeService>().mode;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: 0.3 + (_controller.value * 0.4),
          child: widget.isGridView ? _buildGrid(mode) : _buildList(mode),
        );
      },
    );
  }

  /// Construye shimmer en grilla
  Widget _buildGrid(AppThemeMode mode) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        return AnimationConfiguration.staggeredGrid(
          position: index,
          columnCount: 3,
          duration: const Duration(milliseconds: 375),
          child: ScaleAnimation(
            child: FadeInAnimation(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface(mode),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Construye shimmer en lista
  Widget _buildList(AppThemeMode mode) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 10,
      itemBuilder: (context, index) {
        return AnimationConfiguration.staggeredList(
          position: index,
          duration: const Duration(milliseconds: 375),
          child: SlideAnimation(
            verticalOffset: 50.0,
            child: FadeInAnimation(
              child: Container(
                height: 80,
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface(mode),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
