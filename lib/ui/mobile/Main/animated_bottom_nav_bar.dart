import 'dart:ui';
import 'package:animations_plus/animations_plus.dart' hide ScaleAnimation;
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:ionicons/ionicons.dart';
import 'package:provider/provider.dart';
import 'package:mg_music/services/ui/theme_service.dart';
import 'package:mg_music/ui/mobile/Main/bottom_nav_item.dart';
import 'package:mg_music/ui/mobile/Main/painters.dart';
import 'package:mg_music/services/ui/responsive_service.dart';

class AnimatedBottomNavBar extends StatefulWidget {
  final int selectedIndex;
  final bool isSearching;
  final Function(int) onNavItemTap;
  final VoidCallback onSearchTap;

  const AnimatedBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.isSearching,
    required this.onNavItemTap,
    required this.onSearchTap,
  });

  @override
  State<AnimatedBottomNavBar> createState() => _AnimatedBottomNavBarState();
}

class _AnimatedBottomNavBarState extends State<AnimatedBottomNavBar> {
  bool _iconsVisible = false;

  @override
  /// Inicializa retardo para mostrar iconos con animación
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) {
        setState(() {
          _iconsVisible = true;
        });
      }
    });
  }

  @override
  /// Construye el nav bar animado con blur y gradiente
  Widget build(BuildContext context) {
    return SimpleFadeAnimation(
      duration: const Duration(milliseconds: 400),
      delay: const Duration(milliseconds: 150),
      child: SimpleSlideAnimation(
        duration: const Duration(milliseconds: 400),
        delay: const Duration(milliseconds: 150),
        direction: SlideDirection.down, // Slide from bottom
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Consumer<ThemeService>(
              builder: (context, themeService, _) {
                final mode = themeService.mode;
                return CustomPaint(
                  painter: NavBarPainter(
                    borderColor: mode == AppThemeMode.dark
                        ? Colors.blue.shade900
                        : Colors.blue.shade500,
                    mode: mode,
                  ),
                  child: Container(
                    height: 70.h + MediaQuery.of(context).padding.bottom,
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).padding.bottom,
                    ),
                    child: _iconsVisible
                        ? AnimationLimiter(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                _buildAnimatedNavItem(
                                  0,
                                  0,
                                  Ionicons.musical_notes_outline,
                                  Ionicons.musical_notes,
                                  'Pistas',
                                ),
                                _buildAnimatedNavItem(
                                  1,
                                  1,
                                  Ionicons.list_outline,
                                  Ionicons.list,
                                  'Playlists',
                                ),
                                _buildAnimatedSearchItem(2),
                                _buildAnimatedNavItem(
                                  2,
                                  3,
                                  Ionicons.heart_outline,
                                  Ionicons.heart,
                                  'Favoritos',
                                ),
                                _buildAnimatedNavItem(
                                  3,
                                  4,
                                  Ionicons.settings_outline,
                                  Ionicons.settings,
                                  'Ajustes',
                                ),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Construye un ítem animado del nav bar
  Widget _buildAnimatedNavItem(
    int index,
    int position,
    IconData iconOff,
    IconData iconOn,
    String label,
  ) {
    final bool isActuallySelected =
        widget.selectedIndex == index && !widget.isSearching;

    return Expanded(
      child: AnimationConfiguration.staggeredList(
        position: position,
        duration: const Duration(milliseconds: 800),
        child: ScaleAnimation(
          scale: 0.0,
          curve: Curves.elasticOut,
          child: FadeInAnimation(
            child: _BounceOnSelection(
              isSelected: isActuallySelected,
              child: BottomNavItem(
                iconOff: iconOff,
                iconOn: iconOn,
                label: label,
                isSelected: isActuallySelected,
                onTap: () => widget.onNavItemTap(index),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Construye el ítem de búsqueda animado
  Widget _buildAnimatedSearchItem(int position) {
    return Expanded(
      child: AnimationConfiguration.staggeredList(
        position: position,
        duration: const Duration(milliseconds: 800),
        child: ScaleAnimation(
          scale: 0.0,
          curve: Curves.elasticOut,
          child: FadeInAnimation(
            child: _BounceOnSelection(
              isSelected: widget.isSearching,
              child: BottomNavItem(
                iconOff: Ionicons.search_outline,
                iconOn: Ionicons.search,
                label: 'Buscar',
                isSelected: widget.isSearching,
                onTap: widget.onSearchTap,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BounceOnSelection extends StatefulWidget {
  final bool isSelected;
  final Widget child;

  const _BounceOnSelection({required this.isSelected, required this.child});

  @override
  State<_BounceOnSelection> createState() => _BounceOnSelectionState();
}

class _BounceOnSelectionState extends State<_BounceOnSelection>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  /// Inicializa el control de rebote al seleccionar
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  /// Dispara la animación cuando cambia a seleccionado
  void didUpdateWidget(covariant _BounceOnSelection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  /// Libera el controlador de animación
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  /// Aplica la animación de escala al hijo
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _scaleAnimation, child: widget.child);
  }
}
