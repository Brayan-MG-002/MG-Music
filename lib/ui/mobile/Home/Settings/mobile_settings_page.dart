// Copyright © 2026 Brayan Medrano - MG Music
// Página de configuración Mobile

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:ionicons/ionicons.dart';
import 'package:provider/provider.dart';
import 'package:mg_music/services/audio/audio_player_manager.dart';
import 'package:mg_music/ui/shared/screens/update_loading_dialog.dart';
import 'package:mg_music/services/logic/update_service.dart';
import 'package:mg_music/ui/shared/screens/update_dialog.dart';
import 'package:mg_music/ui/shared/screens/update_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:mg_music/services/ui/custom_toast_service.dart';
import 'package:mg_music/services/ui/theme_service.dart';
import 'package:mg_music/services/models/song_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'components/interactive_logo.dart';
import 'components/about_page.dart';
import 'components/sleep_timer_modal.dart';
import 'components/startup_mode_modal.dart';
import 'components/donate_modal.dart';
import 'components/link_dialog.dart';
import 'components/whats_new_page.dart';
import 'components/theme_settings_modal.dart';
import 'components/folder_settings_modal.dart';
import 'package:mg_music/services/audio/ado_handler.dart';
import 'package:mg_music/services/ui/ado_experience_service.dart';
import 'package:mg_music/services/ui/bottom_modal_service.dart';
import 'package:mg_music/services/ui/responsive_service.dart';
import 'components/backup_settings_page.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:mg_music/services/ui/global_modal_service.dart';
import 'package:mg_music/main.dart' show isBeta;
import 'dart:io';



class MobileSettingsPage extends StatefulWidget {
  final Function(Widget, String)? onNavigate;
  const MobileSettingsPage({super.key, this.onNavigate});

  @override
  State<MobileSettingsPage> createState() => _MobileSettingsPageState();
}

class _MobileSettingsPageState extends State<MobileSettingsPage> {
  bool _hasAdoSongs = true;
  String _appVersion = '';
  bool _adoBoostExpanded = false;
  bool _adoDynamicColorEnabled = false;
  bool _adoDynamicColorExpanded = false;
  int _adoDynamicColorMode = 0;
  bool _adoDedicatedPlayerEnabled = false;
  bool _hasPendingUpdate = false;

  @override
  void initState() {
    super.initState();
    _loadAdoStatus();
    _loadAppVersion();
    _loadPendingUpdateState();
    _adoDynamicColorEnabled = AdoExperienceService().dynamicColorEnabled;
    _adoDynamicColorMode = AdoExperienceService().dynamicColorMode;
    _adoDedicatedPlayerEnabled = AdoExperienceService().dedicatedPlayerEnabled;
  }

  Future<void> _loadPendingUpdateState() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getInt('pending_update_version_code') ?? 0;
    if (mounted) setState(() => _hasPendingUpdate = code > 0);
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _appVersion = info.version);
  }


  Future<void> _loadAdoStatus() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _hasAdoSongs = prefs.getBool('has_ado_songs') ?? true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mode = context.watch<ThemeService>().mode;

    final items = [
      SizedBox(height: 24.h),
      const Align(alignment: Alignment.center, child: InteractiveLogo()),
      if (isBeta)
        Padding(
          padding: EdgeInsets.only(top: 8.h),
          child: Center(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: AppColors.primaryBlueMid.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: AppColors.primaryBlueMid.withOpacity(0.5),
                  width: 1.w,
                ),
              ),
              child: Text(
                'BETA',
                style: TextStyle(
                  color: AppColors.primaryBlueMid,
                  fontWeight: FontWeight.w900,
                  fontSize: 12.sp,
                  letterSpacing: 2.0,
                ),
              ),
            ),
          ),
        ),
      SizedBox(height: 24.h),
      if (isBeta)
        _buildSettingItem(
          icon: Ionicons.bug_outline,
          title: 'Reportar Error (Beta)',
          subtitle: 'Informa fallos visuales o técnicos',
          onTap: () => _showBetaErrorReport(context, mode),
          mode: mode,
        ),

      _buildSectionTitle('General', mode),
      Consumer<ThemeService>(
        builder: (context, themeService, _) {
          String desc;
          switch (themeService.themeType) {
            case AppThemeType.system:
              desc = 'Igual que el dispositivo';
              break;
            case AppThemeType.timeBased:
              desc = 'Por horario automático';
              break;
            case AppThemeType.light:
              desc = 'Siempre claro';
              break;
            case AppThemeType.dark:
              desc = 'Siempre oscuro';
              break;
          }
          return _buildSettingItem(
            icon: Ionicons.color_palette_outline,
            title: 'Tema',
            subtitle: desc,
            onTap: () => ThemeSettingsContent.showModal(context),
            mode: mode,
          );
        },
      ),
      _buildSettingItem(
        icon: Ionicons.folder_outline,
        title: 'Ubicación de Música',
        subtitle: 'Elegir qué carpetas escanear',
        onTap: () => FolderSettingsContent.showModal(context),
        mode: mode,
      ),
      _buildSettingItem(
        icon: Ionicons.timer_outline,
        title: 'Temporizador',
        subtitle: 'Configurar apagado automático',
        onTap: () => SleepTimerModal.show(context),
        mode: mode,
      ),
      _buildSettingItem(
        icon: Ionicons.cloud_download_outline,
        title: 'Actualizar',
        subtitle: _hasPendingUpdate
            ? '⚠️ Actualización pendiente'
            : 'Buscar nueva versión de la app',
        onTap: () => _checkForUpdatesManual(context),
        mode: mode,
        hasBadge: _hasPendingUpdate,
      ),
      _buildSettingItem(
        icon: Ionicons.shield_checkmark_outline,
        title: 'Gestión de Copias',
        subtitle: 'Configurar, crear y restaurar respaldos',
        onTap: () => _navigateTo(context, const BackupSettingsPage()),
        mode: mode,
      ),

      SizedBox(height: 20.h),
      _buildSectionTitle('Experiencia Temática', mode),

      _buildSettingItem(
        icon: Ionicons.play_circle_outline,
        title: 'Inicio de App',
        subtitle: _hasAdoSongs
            ? 'Personalizar comportamiento al abrir'
            : 'Sin canciones de Ado — modo "última canción"',
        onTap: _hasAdoSongs ? () => StartupModeModal.show(context) : null,
        disabled: !_hasAdoSongs,
        mode: mode,
      ),

      _buildAdoBoostItem(mode),
      _buildDynamicColorItem(mode),
      _buildToggleSettingItem(
        icon: Ionicons.musical_notes_outline,
        title: 'Player Especial',
        subtitle: _hasAdoSongs
            ? 'Activar player de Ado'
            : 'Solo disponible con Ado',
        value: _adoDedicatedPlayerEnabled,
        disabled: !_hasAdoSongs,
        mode: mode,
        onChanged: (val) {
          setState(() => _adoDedicatedPlayerEnabled = val);
          AdoExperienceService().setDedicatedPlayerEnabled(val);
          CustomToastService.show(
            context,
            message: "Player Especial: ${val ? 'Activado' : 'Desactivado'}",
            type: ToastType.ado,
          );
        },
      ),

      SizedBox(height: 20.h),
      _buildSectionTitle('Información de la App', mode),
      _buildSettingItem(
        icon: Ionicons.sparkles_outline,
        title: 'Novedades de la Versión',
        subtitle: _appVersion.isEmpty ? 'Descubre qué hay de nuevo' : 'Descubre qué hay de nuevo en la v$_appVersion',
        onTap: () => _navigateTo(context, const WhatsNewPage()),
        mode: mode,
      ),
      _buildSettingItem(
        icon: Ionicons.information_circle_outline,
        title: 'Acerca de MG Music',
        subtitle: 'Inspiración, Desarrollo y Avisos legales',
        onTap: () => _navigateTo(context, const AboutPage()),
        mode: mode,
      ),
      _buildSettingItem(
        icon: Ionicons.logo_github,
        title: 'GitHub',
        subtitle: 'Código fuente',
        onTap: () => LinkDialog.show(
          context: context,
          title: 'Abrir GitHub',
          icon: Ionicons.logo_github,
          content:
              'Serás redirigido al repositorio de GitHub. Este código está subido por transparencia y no es de uso libre ni para distribución.',
          url: 'https://github.com/Brayan-MG-002/MG-Music',
        ),
        mode: mode,
      ),

      SizedBox(height: 20.h),
      _buildSectionTitle('Redes y Donación', mode),
      _buildSettingItem(
        icon: Ionicons.logo_facebook,
        title: 'Facebook',
        subtitle: 'Sígueme para novedades',
        onTap: () => LinkDialog.show(
          context: context,
          title: 'Ir a Facebook',
          icon: Ionicons.logo_facebook,
          content:
              'Serás redirigido a mi perfil de Facebook donde se publican todas las novedades y actualizaciones de la app.',
          url: 'https://www.facebook.com/Brayan.MG.002',
        ),
        mode: mode,
      ),
      _buildSettingItem(
        icon: Ionicons.logo_tiktok,
        title: 'TikTok',
        subtitle: '@brayan.mg.002',
        onTap: () => LinkDialog.show(
          context: context,
          title: 'Ir a TikTok',
          icon: Ionicons.logo_tiktok,
          content: 'Sígueme en TikTok para ver videos sobre el desarrollo y curiosidades de MG Music.',
          url: 'https://www.tiktok.com/@brayan.mg.002',
        ),
        mode: mode,
      ),
      _buildSettingItem(
        icon: Ionicons.logo_whatsapp,
        title: 'WhatsApp',
        subtitle: 'Soporte directo',
        onTap: () => LinkDialog.show(
          context: context,
          title: 'Abrir WhatsApp',
          icon: Ionicons.logo_whatsapp,
          content:
              'Usa este chat para reportar errores o enviar sugerencias directamente.',
          url: 'https://wa.me/573168060939',
        ),
        mode: mode,
      ),

      _buildSettingItem(
        icon: Ionicons.cash_outline,
        title: 'Donar',
        subtitle: 'Apoya el proyecto con PayPal',
        onTap: () => DonateModal.show(context),
        mode: mode,
      ),
      SizedBox(height: 120.h),
    ];

    return Scaffold(
      backgroundColor: AppColors.background(mode),
      body: RepaintBoundary(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 0),
          child: AnimationLimiter(
            child: RepaintBoundary(
              child: Column(
                children: AnimationConfiguration.toStaggeredList(
                  duration: const Duration(milliseconds: 500),
                  delay: const Duration(milliseconds: 100),
                  childAnimationBuilder: (widget) => SlideAnimation(
                    verticalOffset: 50.0,
                    child: ScaleAnimation(
                      scale: 0.5,
                      curve: Curves.elasticOut,
                      child: FadeInAnimation(child: widget),
                    ),
                  ),
                  children: items,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildAdoBoostItem(AppThemeMode mode) {
    final manager = AudioPlayerManager();
    return ValueListenableBuilder<bool>(
      valueListenable: manager.adoBoostEnabledNotifier,
      builder: (context, enabled, _) {
        return ValueListenableBuilder<double>(
          valueListenable: manager.adoBoostLevelNotifier,
          builder: (context, level, _) {
            return ValueListenableBuilder<LocalSong?>(
              valueListenable: manager.currentSongNotifier,
              builder: (context, currentSong, _) {
                final isAdoPlaying = (currentSong != null
                    ? AdoHandler.isAdo(currentSong)
                    : false);
                final isAvailable = _hasAdoSongs && isAdoPlaying;

                return Opacity(
                  opacity: isAvailable ? 1.0 : 0.5,
                  child: IgnorePointer(
                    ignoring: !isAvailable,
                    child: Container(
                      margin: EdgeInsets.only(bottom: 12.h),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: AppColors.themeBorder(mode),
                          width: 2.w,
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primaryBlueMid.withOpacity(0.25),
                            AppColors.surface(mode).withOpacity(0.0),
                          ],
                        ),
                      ),
                      child: Column(
                        children: [
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(20.r),
                                bottom: _adoBoostExpanded
                                    ? Radius.zero
                                    : Radius.circular(20.r),
                              ),
                              onTap: () => setState(
                                () => _adoBoostExpanded = !_adoBoostExpanded,
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(12.r),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(10.r),
                                      decoration: BoxDecoration(
                                        color: mode == AppThemeMode.dark
                                            ? Colors.black.withOpacity(0.3)
                                            : Colors.white.withOpacity(0.5),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Ionicons.volume_high_outline,
                                        color: enabled
                                            ? AppColors.primaryBlueMid
                                            : Colors.grey,
                                        size: 24.r,
                                      ),
                                    ),
                                    SizedBox(width: 15.w),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Amplificador',
                                            style: TextStyle(
                                              color: AppColors.textPrimary(
                                                mode,
                                              ),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14.5.sp,
                                            ),
                                          ),
                                          SizedBox(height: 2.h),
                                          Text(
                                            !isAvailable
                                                ? 'Solo disponible con canciones de Ado'
                                                : 'Mejora el volumen y claridad',
                                            style: TextStyle(
                                              color: !isAvailable
                                                  ? Colors.red.shade400
                                                  : AppColors.textSecondary(
                                                      mode,
                                                    ),
                                              fontSize: 11.sp,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Switch(
                                      value: enabled,
                                      activeColor: AppColors.primaryBlueMid,
                                      onChanged: (v) =>
                                          manager.setAdoBoostEnabled(v),
                                    ),
                                    Icon(
                                      _adoBoostExpanded
                                          ? Ionicons.chevron_up
                                          : Ionicons.chevron_down,
                                      color: AppColors.primaryBlueMid,
                                      size: 18.r,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          AnimatedCrossFade(
                            duration: const Duration(milliseconds: 250),
                            crossFadeState: _adoBoostExpanded
                                ? CrossFadeState.showSecond
                                : CrossFadeState.showFirst,
                            firstChild: const SizedBox.shrink(),
                            secondChild: Padding(
                              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Divider(
                                    color: AppColors.primaryBlueMid.withOpacity(
                                      0.4,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Icon(
                                        Ionicons.volume_low_outline,
                                        color: AppColors.primaryBlueMid,
                                        size: 18.r,
                                      ),
                                      Expanded(
                                        child: SliderTheme(
                                          data: SliderTheme.of(context)
                                              .copyWith(
                                            activeTrackColor:
                                                AppColors.primaryBlueMid,
                                            inactiveTrackColor:
                                                AppColors.themeBorder(
                                              mode,
                                            ).withOpacity(0.3),
                                            thumbColor:
                                                AppColors.textPrimary(
                                              mode,
                                            ),
                                            overlayColor: AppColors
                                                .primaryBlueMid
                                                .withOpacity(0.2),
                                            trackHeight: 3.h,
                                          ),
                                          child: Slider(
                                            value: level,
                                            min: 1.0,
                                            max: 1.5,
                                            divisions: 5,
                                            onChanged: enabled
                                                ? (v) => manager
                                                      .setAdoBoostLevel(v)
                                                : null,
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        Ionicons.volume_high_outline,
                                        color: AppColors.primaryBlueMid,
                                        size: 18.r,
                                      ),
                                    ],
                                  ),
                                  Center(
                                    child: Text(
                                      '${level.toStringAsFixed(1)}× volumen',
                                      style: TextStyle(
                                        color: AppColors.primaryBlueMid,
                                        fontSize: 11.sp,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }


  Widget _buildSectionTitle(String title, AppThemeMode mode) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h, top: 10.h),
      child: Center(
        child: Text(
          title,
          style: TextStyle(
            color: AppColors.primaryBlueMid,
            fontWeight: FontWeight.bold,
            fontSize: 14.sp,
          ),
        ),
      ),
    );
  }


  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required AppThemeMode mode,
    VoidCallback? onTap,
    bool disabled = false,
    bool hasBadge = false,
  }) {
    return Opacity(
      opacity: disabled ? 0.4 : 1.0,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: hasBadge
                ? Colors.orange.withOpacity(0.7)
                : AppColors.themeBorder(mode),
            width: hasBadge ? 2.w : 2.w,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              hasBadge
                  ? Colors.orange.withOpacity(0.12)
                  : AppColors.primaryBlueMid.withOpacity(0.25),
              AppColors.background(mode).withOpacity(0.0),
            ],
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20.r),
            onTap: disabled ? null : onTap,
            child: Padding(
              padding: EdgeInsets.all(12.r),
              child: Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: EdgeInsets.all(10.r),
                        decoration: BoxDecoration(
                          color: mode == AppThemeMode.dark
                              ? Colors.black.withOpacity(0.3)
                              : Colors.white.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          icon,
                          color: AppColors.textPrimary(mode),
                          size: 24.r,
                        ),
                      ),
                      if (hasBadge)
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            width: 12.r,
                            height: 12.r,
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.background(mode),
                                width: 1.5.w,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(width: 15.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: AppColors.textPrimary(mode),
                            fontWeight: FontWeight.bold,
                            fontSize: 14.5.sp,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: hasBadge
                                ? Colors.orange
                                : AppColors.textSecondary(mode),
                            fontSize: 11.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!disabled)
                    Icon(
                      Ionicons.chevron_forward,
                      color: AppColors.primaryBlueMid,
                      size: 24.r,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildToggleSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required AppThemeMode mode,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool disabled = false,
  }) {
    return Opacity(
      opacity: disabled ? 0.4 : 1.0,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: AppColors.themeBorder(mode), width: 2.w),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryBlueMid.withOpacity(0.25),
              AppColors.background(mode).withOpacity(0.0),
            ],
          ),
        ),
        child: IgnorePointer(
          ignoring: disabled,
          child: Padding(
            padding: EdgeInsets.all(12.r),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    color: mode == AppThemeMode.dark
                        ? Colors.black.withOpacity(0.3)
                        : Colors.white.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: AppColors.textPrimary(mode), size: 24.r),
                ),
                SizedBox(width: 15.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: AppColors.textPrimary(mode),
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5.sp,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: AppColors.textSecondary(mode),
                          fontSize: 11.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: value,
                  activeColor: AppColors.primaryBlueMid,
                  onChanged: onChanged,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildDynamicColorItem(AppThemeMode mode) {
    return ValueListenableBuilder<LocalSong?>(
      valueListenable: AudioPlayerManager().currentSongNotifier,
      builder: (context, currentSong, _) {
        final isAdoPlaying = currentSong != null ? AdoHandler.isAdo(currentSong) : false;
        final isAvailable = _hasAdoSongs && isAdoPlaying;

        return Opacity(
          opacity: isAvailable ? 1.0 : 0.5,
          child: Container(
            margin: EdgeInsets.only(bottom: 12.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: AppColors.themeBorder(mode), width: 2.w),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryBlueMid.withOpacity(0.25),
                  AppColors.background(mode).withOpacity(0.0),
                ],
              ),
            ),
            child: IgnorePointer(
              ignoring: !isAvailable,
              child: Column(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(20.r),
                    onTap: () {
                      setState(() => _adoDynamicColorExpanded = !_adoDynamicColorExpanded);
                    },
                    child: Padding(
                      padding: EdgeInsets.all(12.r),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(10.r),
                            decoration: BoxDecoration(
                              color: mode == AppThemeMode.dark
                                  ? Colors.black.withOpacity(0.3)
                                  : Colors.white.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Ionicons.color_fill_outline,
                              color: AppColors.textPrimary(mode),
                              size: 20.r,
                            ),
                          ),
                          SizedBox(width: 15.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Color Dinámico',
                                  style: TextStyle(
                                    color: AppColors.textPrimary(mode),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.sp,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  isAvailable ? 'Adaptar colores a la portada' : 'Solo disponible con Ado',
                                  style: TextStyle(
                                    color: isAvailable ? AppColors.textSecondary(mode) : Colors.redAccent,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _adoDynamicColorEnabled,
                            activeColor: AppColors.primaryBlueMid,
                            onChanged: (val) {
                              setState(() {
                                _adoDynamicColorEnabled = val;
                                if (val) _adoDynamicColorExpanded = true;
                              });
                              AdoExperienceService().setDynamicColorEnabled(val);
                            },
                          ),
                            Icon(
                              _adoDynamicColorExpanded
                                  ? Ionicons.chevron_up
                                  : Ionicons.chevron_down,
                              color: AppColors.primaryBlueMid,
                              size: 18.r,
                            ),
                        ],
                      ),
                    ),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: (!_adoDynamicColorExpanded)
                        ? const SizedBox.shrink()
                        : Opacity(
                            opacity: _adoDynamicColorEnabled ? 1.0 : 0.4,
                            child: IgnorePointer(
                              ignoring: !_adoDynamicColorEnabled,
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                                child: Container(
                                  padding: EdgeInsets.all(12.r),
                                  decoration: BoxDecoration(
                                    color: mode == AppThemeMode.dark
                                        ? Colors.black.withOpacity(0.3)
                                        : Colors.white.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(15.r),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        'Modos de Transición',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: AppColors.textPrimary(mode),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14.sp,
                                        ),
                                      ),
                                      SizedBox(height: 10.h),
                                      Column(
                                        children: [
                                          _buildModeTile('Fijo', 0, mode, context),
                                          SizedBox(height: 4.h),
                                          _buildModeTile('Latido', 1, mode, context),
                                          SizedBox(height: 4.h),
                                          _buildModeTile('Múltiple', 2, mode, context),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }


  Widget _buildModeTile(String label, int modeValue, AppThemeMode themeMode, BuildContext context) {
    bool isSelected = _adoDynamicColorMode == modeValue;
    return InkWell(
      onTap: () {
        setState(() => _adoDynamicColorMode = modeValue);
        AdoExperienceService().setDynamicColorMode(modeValue);
      },
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlueMid.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlueMid.withOpacity(0.5) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Ionicons.radio_button_on : Ionicons.radio_button_off,
              color: isSelected ? AppColors.primaryBlueMid : AppColors.textSecondary(themeMode),
              size: 20.r,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColors.textPrimary(themeMode) : AppColors.textSecondary(themeMode),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14.sp,
                ),
              ),
            ),
            IconButton(
              icon: Icon(Ionicons.help_circle_outline, size: 22.r, color: AppColors.textSecondary(themeMode)),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => _showModeInfo(modeValue, context),
            ),
          ],
        ),
      ),
    );
  }


  void _showModeInfo(int modeValue, BuildContext context) {
    String title = '';
    String content = '';
    IconData icon = Ionicons.information_circle_outline;

    switch (modeValue) {
      case 0:
        title = 'Modo Fijo';
        content = 'Extrae el color más dominante o vibrante de la carátula actual y lo establece sin alteraciones. Es el modo más rápido, ligero y recomendado.';
        icon = Ionicons.color_fill_outline;
        break;
      case 1:
        title = 'Modo Latido';
        content = 'Simula el ritmo de un latido palpitante. Transiciona suave y constantemente (ida y vuelta) entre el color extraído de la carátula y el clásico tono de tu tema por defecto.';
        icon = Ionicons.pulse_outline;
        break;
      case 2:
        title = 'Modo Múltiple';
        content = 'Extrae una paleta de múltiples colores clave de la carátula (Dominantes y Vibrantes) y realiza una lenta transición cíclica, mostrándote todos los tonos que conforman la portada.';
        icon = Ionicons.color_palette_outline;
        break;
    }

    BottomModalService.show(
      context,
      title: title,
      subtitle: '¿Cómo funciona?',
      child: Padding(
         padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
         child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Icon(icon, color: AppColors.primaryBlueMid, size: 40.r),
               SizedBox(width: 15.w),
               Expanded(
                 child: Text(
                   content,
                   style: TextStyle(
                     color: AppColors.textPrimary(Provider.of<ThemeService>(context, listen: false).mode),
                     fontSize: 14.sp,
                     height: 1.4,
                   ),
                 ),
               ),
            ],
         ),
      ),
    );
  }

  Future<void> _showBetaErrorReport(BuildContext context, AppThemeMode mode) async {
    final textController = TextEditingController();

    // 1. Elegir tipo de error usando GlobalModalService
    final selectedType = await GlobalModalService.showSelectionList<String>(
      title: 'Tipo de Error',
      icon: Ionicons.bug_outline,
      items: ['Visual / Diseño', 'Funcional / Técnico', 'Otro / Sugerencia'],
      labelBuilder: (item) => item,
    );

    if (selectedType == null) return;


    if (!context.mounted) return;
    
    final confirmDescription = await GlobalModalService.show<bool>(
      title: 'Detalles del Error',
      icon: Ionicons.create_outline,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Por favor describe brevemente qué sucede:',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary(mode), fontSize: 13.sp),
          ),
          SizedBox(height: 15.h),
          TextField(
            controller: textController,
            maxLines: 4,
            autofocus: true,
            style: TextStyle(color: AppColors.textPrimary(mode)),
            decoration: InputDecoration(
              hintText: 'Ej: Al abrir el reproductor la imagen parpadea...',
              hintStyle: TextStyle(color: AppColors.textSecondary(mode).withOpacity(0.5)),
              filled: true,
              fillColor: AppColors.surface(mode).withOpacity(0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15.r),
                borderSide: BorderSide(color: AppColors.themeBorder(mode)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15.r),
                borderSide: BorderSide(color: AppColors.themeBorder(mode).withOpacity(0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15.r),
                borderSide: BorderSide(color: AppColors.primaryBlueMid),
              ),
            ),
          ),
        ],
      ),
      actions: [
        ModalActionButton(
          label: 'Cancelar',
          onPressed: () => Navigator.pop(GlobalModalService.navigatorKey.currentContext!, false),
          color: Colors.grey.shade600,
        ),
        ModalActionButton(
          label: 'Siguiente',
          onPressed: () => Navigator.pop(GlobalModalService.navigatorKey.currentContext!, true),
          color: AppColors.primaryBlueMid,
        ),
      ],
    );

    if (confirmDescription != true || textController.text.trim().isEmpty) return;


    if (!context.mounted) return;


    final deviceInfo = DeviceInfoPlugin();
    String deviceModel = "Desconocido";
    String androidVersion = "Desconocida";
    String brand = "";

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceModel = androidInfo.model;
        androidVersion = androidInfo.version.release;
        brand = androidInfo.brand;
      }
    } catch (_) {}

    final appVersion = _appVersion.isEmpty ? 'N/A' : _appVersion;
    final message = '''*REPORTE DE ERROR - MG MUSIC BETA*
-------------------------------
*Tipo:* $selectedType
*Descripción:* ${textController.text.trim()}

*DATOS TÉCNICOS:*
• App Versión: $appVersion
• Android: $androidVersion
• Dispositivo: $brand $deviceModel
-------------------------------''';

    final whatsappUrl = "https://wa.me/573168060939?text=${Uri.encodeComponent(message)}";

    await LinkDialog.show(
      context: context,
      title: 'Confirmar Envío',
      icon: Ionicons.logo_whatsapp,
      content: 'Se enviará tu mensaje junto con información técnica (App, Android y Dispositivo) para ayudarnos a resolver el error.\n\n¿Abrir WhatsApp?',
      url: whatsappUrl,
    );
  }

  void _navigateTo(BuildContext context, Widget page) {

    String title = '';
    if (page is BackupSettingsPage) title = 'Gestión de Copias';
    if (page is AboutPage) title = 'Acerca de MG Music';
    if (page is WhatsNewPage) title = 'Novedades v$_appVersion';

    if (widget.onNavigate != null) {
      widget.onNavigate!(page, title);
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (context) => page));
    }
  }


  Future<void> _checkForUpdatesManual(BuildContext context) async {
    BuildContext? dialogContext;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        dialogContext = ctx;
        return const UpdateLoadingDialog();
      },
    );

    await Future.delayed(const Duration(milliseconds: 300));

    try {
      final updateInfo = await UpdateService.checkForUpdate();

      if (mounted && dialogContext != null && dialogContext!.mounted) {
        try {
          Navigator.of(dialogContext!).pop();
        } catch (_) {}
      }

      await Future.delayed(const Duration(milliseconds: 250));
      if (!mounted) return;

      // Limpiar pending si fue verificado manualmente
      final prefs = await SharedPreferences.getInstance();

      if (updateInfo['hasUpdate']) {
        // Mostrar primero el modal de confirmación (UpdateDialog)
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => UpdateDialog(versionData: updateInfo['data']),
        );
      } else if (updateInfo['error'] != null) {
        _showUpdateResultSnackBar(context, updateInfo['error'], isSuccess: false);
      } else {
        // Ya está actualizado — navegar a UpdateScreen para mostrar el estado "Al día"
        await prefs.remove('pending_update_version_code');
        if (mounted) setState(() => _hasPendingUpdate = false);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => UpdateScreen(versionData: updateInfo['data']),
            fullscreenDialog: true,
          ),
        );
      }
    } catch (_) {
      if (mounted && dialogContext != null && dialogContext!.mounted) {
        try {
          Navigator.of(dialogContext!).pop();
        } catch (_) {}
      }
      await Future.delayed(const Duration(milliseconds: 250));
      if (mounted) {
        _showUpdateResultSnackBar(
          context,
          'Error al verificar actualizaciones',
          isSuccess: false,
        );
      }
    }
  }


  void _showUpdateResultSnackBar(
    BuildContext context,
    String message, {
    required bool isSuccess,
  }) {
    CustomToastService.show(
      context,
      message: message,
      type: isSuccess ? ToastType.success : ToastType.error,
    );
  }

}
