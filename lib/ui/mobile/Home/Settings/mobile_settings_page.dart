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
import 'package:mg_music/services/audio/ado_handler.dart';

/// Página de configuración Mobile
class MobileSettingsPage extends StatefulWidget {
  const MobileSettingsPage({super.key});

  @override
  State<MobileSettingsPage> createState() => _MobileSettingsPageState();
}

class _MobileSettingsPageState extends State<MobileSettingsPage> {
  bool _hasAdoSongs = true;
  bool _adoBoostExpanded = false;

  @override
  /// Inicializa estado y carga si hay canciones de Ado
  void initState() {
    super.initState();
    _loadAdoStatus();
  }

  /// Lee de preferencias si existen canciones de Ado
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
      const SizedBox(height: 24),
      const Align(alignment: Alignment.center, child: InteractiveLogo()),
      const SizedBox(height: 24),

      _buildSectionTitle('General', mode),
      _buildThemeToggleItem(mode),
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
        subtitle: 'Buscar nueva versión de la app',
        onTap: () => _checkForUpdatesManual(context),
        mode: mode,
      ),

      const SizedBox(height: 20),
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

      const SizedBox(height: 20),
      _buildSectionTitle('Información de la App', mode),
      _buildSettingItem(
        icon: Ionicons.sparkles_outline,
        title: 'Novedades de la Versión',
        subtitle: 'Descubre qué hay de nuevo en la v1.1.1',
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
      _buildSettingItem(
        icon: Ionicons.cash_outline,
        title: 'Donar',
        subtitle: 'Apoya con Nequi',
        onTap: () => DonateModal.show(context),
        mode: mode,
      ),
      const SizedBox(height: 120),
    ];

    return Scaffold(
      backgroundColor: AppColors.background(mode),
      body: RepaintBoundary(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
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

  /// Construye el tile de cambio de tema
  Widget _buildThemeToggleItem(AppThemeMode mode) {
    return Consumer<ThemeService>(
      builder: (context, themeService, _) {
        final isDark = themeService.isDark;
        return GestureDetector(
          onTap: () => themeService.toggle(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.themeBorder(mode), width: 2),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryBlueMid.withOpacity(0.25),
                  AppColors.surface(mode).withOpacity(0.0),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  // Ícono con fondo animado
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.black.withOpacity(0.3)
                          : Colors.blue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      transitionBuilder: (child, anim) => RotationTransition(
                        turns: Tween(begin: 0.75, end: 1.0).animate(anim),
                        child: FadeTransition(opacity: anim, child: child),
                      ),
                      child: Icon(
                        isDark
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        key: ValueKey(isDark),
                        color: isDark ? Colors.white : Colors.orange.shade700,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  // Texto
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 400),
                          style: TextStyle(
                            color: AppColors.textPrimary(mode),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          child: const Text('Tema'),
                        ),
                        const SizedBox(height: 2),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            isDark ? 'Modo Oscuro activo' : 'Modo Claro activo',
                            key: ValueKey(isDark),
                            style: TextStyle(
                              color: AppColors.textSecondary(mode),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Activar Switch
                  Switch(
                    value: !isDark,
                    activeColor: Colors.blue.shade700,
                    onChanged: (v) => themeService.toggle(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Construye el bloque expandible de AdoBoost
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
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.themeBorder(mode),
                          width: 2,
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
                                top: const Radius.circular(20),
                                bottom: _adoBoostExpanded
                                    ? Radius.zero
                                    : const Radius.circular(20),
                              ),
                              onTap: () => setState(
                                () => _adoBoostExpanded = !_adoBoostExpanded,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: mode == AppThemeMode.dark
                                            ? Colors.black.withOpacity(0.3)
                                            : Colors.white.withOpacity(0.5),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Ionicons.volume_high_outline,
                                        color: enabled
                                            ? Colors.blue
                                            : Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(width: 15),
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
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            !isAvailable
                                                ? 'Solo disponible con canciones de Ado'
                                                : enabled
                                                ? 'Boost activo: ${level.toStringAsFixed(1)}×'
                                                : 'Boost desactivado',
                                            style: TextStyle(
                                              color: !isAvailable
                                                  ? Colors.red.shade400
                                                  : AppColors.textSecondary(
                                                      mode,
                                                    ),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Switch on/off
                                    Switch(
                                      value: enabled,
                                      activeColor: Colors.blue.shade700,
                                      onChanged: (v) =>
                                          manager.setAdoBoostEnabled(v),
                                    ),
                                    Icon(
                                      _adoBoostExpanded
                                          ? Ionicons.chevron_up
                                          : Ionicons.chevron_down,
                                      color: AppColors.primaryBlueMid,
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          RepaintBoundary(
                            child: AnimatedCrossFade(
                              duration: const Duration(milliseconds: 250),
                              crossFadeState: _adoBoostExpanded
                                  ? CrossFadeState.showSecond
                                  : CrossFadeState.showFirst,
                              firstChild: const SizedBox.shrink(),
                              secondChild: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Divider(
                                      color: Colors.blue.shade900.withOpacity(
                                        0.4,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Icon(
                                          Ionicons.volume_low_outline,
                                          color: Colors.blue.shade300,
                                          size: 18,
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
                                                  trackHeight: 3,
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
                                          color: Colors.blue.shade300,
                                          size: 18,
                                        ),
                                      ],
                                    ),
                                    Center(
                                      child: Text(
                                        '${level.toStringAsFixed(1)}× volumen',
                                        style: TextStyle(
                                          color: Colors.blue.shade300,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
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

  /// Título de sección
  Widget _buildSectionTitle(String title, AppThemeMode mode) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 10),
      child: Center(
        child: Text(
          title,
          style: TextStyle(
            color: AppColors.primaryBlueMid,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  /// Tile de ajuste genérico con icono, títulos y flecha
  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required AppThemeMode mode,
    VoidCallback? onTap,
    bool disabled = false,
  }) {
    return Opacity(
      opacity: disabled ? 0.4 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.themeBorder(mode), width: 2),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryBlueMid.withOpacity(0.25),
              AppColors.background(mode).withOpacity(0.0),
            ],
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: disabled ? null : onTap,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: mode == AppThemeMode.dark
                          ? Colors.black.withOpacity(0.3)
                          : Colors.white.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: AppColors.textPrimary(mode)),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: AppColors.textPrimary(mode),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: AppColors.textSecondary(mode),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!disabled)
                    Icon(Ionicons.chevron_forward, color: Colors.blue.shade900),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Navega a una página de ajustes secundaria
  void _navigateTo(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  /// Verifica actualizaciones mostrando un diálogo de carga
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

      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;

      if (updateInfo['hasUpdate']) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => UpdateDialog(versionData: updateInfo['data']),
        );
      } else if (updateInfo['error'] != null) {
        _showUpdateResultSnackBar(
          context,
          updateInfo['error'],
          isSuccess: false,
        );
      } else {
        _showUpdateResultSnackBar(
          context,
          'Ya tienes la última versión instalada',
          isSuccess: true,
        );
      }
    } catch (_) {
      if (mounted && dialogContext != null && dialogContext!.mounted) {
        try {
          Navigator.of(dialogContext!).pop();
        } catch (_) {}
      }
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 300));
        _showUpdateResultSnackBar(
          context,
          'Error al verificar actualizaciones',
          isSuccess: false,
        );
      }
    }
  }

  /// Muestra resultado de verificación de actualización como toast
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
