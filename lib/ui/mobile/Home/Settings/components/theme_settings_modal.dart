// Copyright © 2026 Brayan Medrano - MG Music
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:provider/provider.dart';
import 'package:mg_music/services/ui/theme_service.dart';
import 'package:mg_music/services/ui/global_modal_service.dart';
import 'package:mg_music/services/ui/responsive_service.dart';
import 'package:mg_music/ui/tv/tv_focusable_item.dart';

class ThemeSettingsContent extends StatefulWidget {
  final bool isTv;
  const ThemeSettingsContent({super.key, this.isTv = false});

  static Future<void> showModal(BuildContext context, {bool isTv = false}) {
    return GlobalModalService.show(
      title: 'Tema',
      icon: Ionicons.color_palette_outline,
      content: ThemeSettingsContent(isTv: isTv),
      actions: [],
    );
  }

  @override
  State<ThemeSettingsContent> createState() => _ThemeSettingsContentState();
}

class _ThemeSettingsContentState extends State<ThemeSettingsContent> {
  Future<void> _selectTime(
    BuildContext context,
    ThemeService theme,
    bool isStart,
  ) async {
    final initialTime = isStart
        ? TimeOfDay(hour: theme.startHour, minute: theme.startMin)
        : TimeOfDay(hour: theme.endHour, minute: theme.endMin);

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(data: theme.themeData, child: child!);
      },
    );

    if (picked != null) {
      if (isStart) {
        await theme.setTimeBasedHours(
          startH: picked.hour,
          startM: picked.minute,
          endH: theme.endHour,
          endM: theme.endMin,
        );
      } else {
        await theme.setTimeBasedHours(
          startH: theme.startHour,
          startM: theme.startMin,
          endH: picked.hour,
          endM: picked.minute,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTypeRadio(
              context,
              themeService,
              AppThemeType.system,
              'Igual que el dispositivo',
              Ionicons.phone_portrait_outline,
            ),
            _buildTypeRadio(
              context,
              themeService,
              AppThemeType.timeBased,
              'Por Horario',
              Ionicons.time_outline,
            ),

            if (themeService.themeType == AppThemeType.timeBased)
              _buildTimeSelectors(context, themeService),

            _buildTypeRadio(
              context,
              themeService,
              AppThemeType.dark,
              'Siempre Oscuro',
              Ionicons.moon_outline,
            ),
            _buildTypeRadio(
              context,
              themeService,
              AppThemeType.light,
              'Siempre Claro',
              Ionicons.sunny_outline,
            ),
          ],
        );
      },
    );
  }

  Widget _buildTypeRadio(
    BuildContext context,
    ThemeService themeService,
    AppThemeType type,
    String title,
    IconData icon,
  ) {
    final mode = themeService.mode;
    final isSelected = themeService.themeType == type;

    final Widget radioContent = Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primaryBlueMid.withOpacity(0.4)
            : AppColors.surface(mode).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isSelected ? AppColors.themeBorder(mode) : Colors.transparent,
          width: 1.w,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isSelected
                ? AppColors.textPrimary(mode)
                : AppColors.textSecondary(mode),
            size: 20.r,
          ),
          SizedBox(width: 12.w),
          Text(
            title,
            style: TextStyle(
              color: isSelected
                  ? AppColors.textPrimary(mode)
                  : AppColors.textSecondary(mode),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 14.sp,
            ),
          ),
          const Spacer(),
          if (isSelected)
            Icon(
              Icons.check_circle,
              color: AppColors.primaryBlueMid,
              size: 16.r,
            ),
        ],
      ),
    );

    if (widget.isTv) {
      return TvFocusableItem(
        onTap: () => themeService.setThemeType(type),
        borderRadius: 16.r,
        child: radioContent,
      );
    }

    return GestureDetector(
      onTap: () => themeService.setThemeType(type),
      child: radioContent,
    );
  }

  Widget _buildTimeSelectors(BuildContext context, ThemeService themeService) {
    final mode = themeService.mode;
    final startStr = TimeOfDay(
      hour: themeService.startHour,
      minute: themeService.startMin,
    ).format(context);
    final endStr = TimeOfDay(
      hour: themeService.endHour,
      minute: themeService.endMin,
    ).format(context);

    return Container(
      margin: EdgeInsets.only(left: 32.w, right: 10.w, bottom: 12.h),
      padding: EdgeInsets.all(10.r),
      decoration: BoxDecoration(
        color: AppColors.iconContainer(mode).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTimeNode(
            'Oscuro',
            startStr,
            mode,
            Ionicons.moon,
            () => _selectTime(context, themeService, true),
          ),
          Icon(
            Ionicons.arrow_forward_outline,
            color: AppColors.textSecondary(mode),
            size: 14.r,
          ),
          _buildTimeNode(
            'Claro',
            endStr,
            mode,
            Ionicons.sunny,
            () => _selectTime(context, themeService, false),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeNode(
    String label,
    String time,
    AppThemeMode mode,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, size: 12.r, color: AppColors.textSecondary(mode)),
              SizedBox(width: 4.w),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.textSecondary(mode),
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            time,
            style: TextStyle(
              color: AppColors.textPrimary(mode),
              fontSize: 15.sp,
              fontWeight: FontWeight.bold,
              fontFamily: 'CircularStd',
            ),
          ),
        ],
      ),
    );
  }
}
