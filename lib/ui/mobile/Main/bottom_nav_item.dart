import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mg_music/services/ui/theme_service.dart';
import 'package:mg_music/services/ui/responsive_service.dart';

class BottomNavItem extends StatelessWidget {
  final IconData iconOff;
  final IconData iconOn;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Widget? iconWidget;

  const BottomNavItem({
    super.key,
    required this.iconOff,
    required this.iconOn,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.iconWidget,
  });

  @override
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
            child: iconWidget ?? Icon(
              isSelected ? iconOn : iconOff,
              color: isSelected
                  ? AppColors.textPrimary(mode)
                  : AppColors.icon(mode).withOpacity(0.5),
              size: 24.r,
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: isSelected ? 14.h : 0,
            curve: Curves.easeOut,
            child: Opacity(
              opacity: isSelected ? 1 : 0,
              child: Text(
                label,
                style: TextStyle(
                  color: AppColors.textPrimary(mode),
                  fontSize: 10.sp,
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
