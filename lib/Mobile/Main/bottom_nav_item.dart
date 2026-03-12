import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mg_music/services/theme_service.dart';

class BottomNavItem extends StatelessWidget {
  final IconData iconOff;
  final IconData iconOn;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const BottomNavItem({
    super.key,
    required this.iconOff,
    required this.iconOn,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  /// Construye un ítem del nav inferior con animación de escala
  Widget build(BuildContext context) {
    final mode = context.watch<ThemeService>().mode;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedScale(
            duration: const Duration(milliseconds: 200),
            scale: isSelected ? 1.1 : 1.0,
            curve: Curves.easeOut,
            child: Icon(
              isSelected ? iconOn : iconOff,
              color: isSelected
                  ? AppColors.primaryBlueLight
                  : AppColors.icon(mode).withOpacity(0.5),
              size: 24,
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: isSelected ? 14 : 0,
            curve: Curves.easeOut,
            child: Opacity(
              opacity: isSelected ? 1 : 0,
              child: Text(
                label,
                style: TextStyle(
                  color: AppColors.primaryBlueLight,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.visible,
                maxLines: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
