// Copyright © 2026 Brayan Medrano - MG Music
// Página principal de configuración TV

import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:ionicons/ionicons.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mg_music/Logic/song_model.dart';
import 'package:mg_music/Logic/audio_player_manager.dart';
import 'package:mg_music/TV/tv_focusable_item.dart';
import 'package:mg_music/services/update_service.dart';
import 'package:mg_music/services/custom_toast_service.dart';
import 'package:mg_music/services/global_modal_service.dart';
import 'package:mg_music/services/theme_service.dart';
import 'package:mg_music/screens/update_dialog.dart';
import 'package:mg_music/screens/update_loading_dialog.dart';
import 'package:mg_music/Logic/audio_player_logic/ado_handler.dart';
import 'tv_settings_widgets.dart';
import 'tv_settings_logo.dart';

class TvSettingsPage extends StatefulWidget {
  const TvSettingsPage({super.key});

  @override
  State<TvSettingsPage> createState() => _TvSettingsPageState();
}

class _TvSettingsPageState extends State<TvSettingsPage> {
  bool _hasAdoSongs = true;
  bool _adoBoostExpanded = false;

  @override
  /// Inicializa el estado y carga datos de Ado
  void initState() {
    super.initState();
    _loadAdoStatus();
  }

  /// Lee del almacenamiento si hay canciones de Ado
  Future<void> _loadAdoStatus() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _hasAdoSongs = prefs.getBool('has_ado_songs') ?? true;
      });
    }
  }

  @override
  /// Construye la página de ajustes TV
  Widget build(BuildContext context) {
    final mode = context.watch<ThemeService>().mode;
    final manager = AudioPlayerManager();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 0),
        child: AnimationLimiter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: AnimationConfiguration.toStaggeredList(
              duration: const Duration(milliseconds: 450),
              delay: const Duration(milliseconds: 80),
              childAnimationBuilder: (widget) => SlideAnimation(
                verticalOffset: 40.0,
                child: FadeInAnimation(child: widget),
              ),
              children: [
                const SizedBox(height: 24),
                const Center(child: TvSettingsLogo()),
                const SizedBox(height: 36),

                TvSettingsSectionTitle(title: 'General', mode: mode),

                TvSettingsRow(
                  left: _buildThemeToggle(mode),
                  right: ValueListenableBuilder<bool>(
                    valueListenable: manager.showVisualizerNotifier,
                    builder: (context, show, _) => TvSettingsSwitchTile(
                      icon: Ionicons.bar_chart_outline,
                      title: 'Visualizador',
                      subtitle: show ? 'Activado' : 'Desactivado',
                      value: show,
                      onChanged: (val) => manager.toggleVisualizer(val),
                      mode: mode,
                    ),
                  ),
                ),

                TvSettingsRow(
                  left: ValueListenableBuilder<int?>(
                    valueListenable: manager.sleepTimerNotifier,
                    builder: (context, minutes, _) {
                      final isActive = minutes != null;
                      return TvSettingsTile(
                        icon: isActive
                            ? Ionicons.timer
                            : Ionicons.timer_outline,
                        title: 'Temporizador',
                        subtitle: isActive
                            ? '$minutes min restantes'
                            : 'Apagado',
                        isActive: isActive,
                        onTap: () => _showSleepTimerDialog(mode),
                        mode: mode,
                      );
                    },
                  ),
                  right: TvSettingsTile(
                    icon: Ionicons.cloud_download_outline,
                    title: 'Actualizar',
                    subtitle: 'Buscar nueva versión',
                    onTap: () => _checkForUpdatesManual(),
                    mode: mode,
                  ),
                ),

                TvSettingsSectionTitle(
                  title: 'Experiencia Temática',
                  mode: mode,
                ),

                TvSettingsRow(
                  left: ValueListenableBuilder<String>(
                    valueListenable: manager.startupModeNotifier,
                    builder: (context, startupMode, _) {
                      final isAdoMode =
                          startupMode == AudioPlayerManager.startupAdo;
                      return TvSettingsTile(
                        icon: Ionicons.play_circle_outline,
                        title: 'Inicio de App',
                        subtitle: !_hasAdoSongs
                            ? 'Sin canciones de Ado'
                            : isAdoMode
                            ? 'Modo Ado'
                            : 'Última sesión',
                        isActive: isAdoMode,
                        onTap: _hasAdoSongs ? _showStartupDialog : null,
                        disabled: !_hasAdoSongs,
                        mode: mode,
                      );
                    },
                  ),
                  right: _buildAdoBoostTile(mode),
                ),

                TvSettingsSectionTitle(
                  title: 'Información de la App',
                  mode: mode,
                ),

                TvSettingsRow(
                  left: TvSettingsTile(
                    icon: Ionicons.musical_notes,
                    title: 'Acerca de MG Music',
                    subtitle: 'Inspiración y avisos legales',
                    onTap: () => _showAboutDialog(),
                    mode: mode,
                  ),
                  right: TvSettingsTile(
                    icon: Ionicons.logo_facebook,
                    title: 'Facebook',
                    subtitle: 'Sígueme',
                    onTap: () => _showTvLinkDialog(
                      title: 'Facebook',
                      message:
                          'Visita este enlace desde tu celular o computadora:\n\nhttps://www.facebook.com/Brayan.MG.002',
                      icon: Ionicons.logo_facebook,
                    ),
                    mode: mode,
                  ),
                ),

                TvSettingsRow(
                  left: TvSettingsTile(
                    icon: Ionicons.logo_whatsapp,
                    title: 'WhatsApp',
                    subtitle: 'Soporte directo',
                    onTap: () => _showTvLinkDialog(
                      title: 'WhatsApp (Soporte)',
                      message:
                          'Guarda este número o escríbeme directamente:\n\n+57 316 806 0939',
                      icon: Ionicons.logo_whatsapp,
                    ),
                    mode: mode,
                  ),
                  right: TvSettingsTile(
                    icon: Ionicons.logo_github,
                    title: 'GitHub',
                    subtitle: 'Código fuente',
                    onTap: () => _showTvLinkDialog(
                      title: 'GitHub',
                      message:
                          'Visita el repositorio desde tu celular o PC:\n\nhttps://github.com/Brayan-MG-002/MG-Music',
                      icon: Ionicons.logo_github,
                    ),
                    mode: mode,
                  ),
                ),

                TvSettingsRow(
                  left: TvSettingsTile(
                    icon: Ionicons.cash_outline,
                    title: 'Donar',
                    subtitle: 'Apoya con Nequi',
                    onTap: () => _showDonateDialog(),
                    mode: mode,
                  ),
                  right: const SizedBox.shrink(),
                ),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Tile de tema con interruptor
  Widget _buildThemeToggle(AppThemeMode mode) {
    return Consumer<ThemeService>(
      builder: (context, themeService, _) {
        final isDark = themeService.isDark;
        return TvFocusableItem(
          onTap: () => themeService.toggle(),
          borderRadius: 20,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.themeBorder(mode), width: 2),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryBlueMid.withOpacity(0.2),
                  AppColors.surface(mode).withOpacity(0.0),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.black.withOpacity(0.3)
                            : Colors.blue.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
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
                          size: 22,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Switch(
                      value: !isDark,
                      activeColor: Colors.blue.shade700,
                      onChanged: (_) => themeService.toggle(),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Tema',
                  style: TextStyle(
                    color: AppColors.textPrimary(mode),
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text(
                    isDark ? 'Modo Oscuro' : 'Modo Claro',
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
        );
      },
    );
  }

  /// Tile expandible para AdoBoost
  Widget _buildAdoBoostTile(AppThemeMode mode) {
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
                final isAdoPlaying =
                    currentSong != null && AdoHandler.isAdo(currentSong);
                final isAvailable = _hasAdoSongs && isAdoPlaying;

                return Opacity(
                  opacity: isAvailable ? 1.0 : 0.5,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
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
                          AppColors.primaryBlueMid.withOpacity(0.2),
                          AppColors.surface(mode).withOpacity(0.0),
                        ],
                      ),
                    ),
                    child: Column(
                      children: [
                        TvFocusableItem(
                          onTap: isAvailable
                              ? () => setState(
                                  () => _adoBoostExpanded = !_adoBoostExpanded,
                                )
                              : null,
                          borderRadius: 18,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: mode == AppThemeMode.dark
                                        ? Colors.black.withOpacity(0.3)
                                        : Colors.white.withOpacity(0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Ionicons.volume_high_outline,
                                    color: enabled ? Colors.blue : Colors.grey,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Amplificador',
                                        style: TextStyle(
                                          color: AppColors.textPrimary(mode),
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        !isAvailable
                                            ? 'Solo con canciones de Ado'
                                            : enabled
                                            ? '${level.toStringAsFixed(1)}× activo'
                                            : 'Desactivado',
                                        style: TextStyle(
                                          color: !isAvailable
                                              ? Colors.red.shade400
                                              : AppColors.textSecondary(mode),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  _adoBoostExpanded
                                      ? Ionicons.chevron_up
                                      : Ionicons.chevron_down,
                                  color: AppColors.primaryBlueMid,
                                  size: 14,
                                ),
                              ],
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
                            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                            child: Column(
                              children: [
                                Divider(
                                  color: Colors.blue.shade900.withOpacity(0.4),
                                ),

                                TvFocusableItem(
                                  onTap: isAvailable
                                      ? () =>
                                            manager.setAdoBoostEnabled(!enabled)
                                      : null,
                                  borderRadius: 12,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 10,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          enabled
                                              ? Ionicons.power
                                              : Ionicons.power_outline,
                                          color: enabled
                                              ? Colors.blue
                                              : Colors.grey,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            enabled
                                                ? 'Boost activo — pulsa para desactivar'
                                                : 'Boost apagado — pulsa para activar',
                                            style: TextStyle(
                                              color: AppColors.textPrimary(
                                                mode,
                                              ),
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                        Switch(
                                          value: enabled,
                                          onChanged: isAvailable
                                              ? (v) => manager
                                                    .setAdoBoostEnabled(v)
                                              : null,
                                          thumbColor: WidgetStateProperty.all(
                                            Colors.white,
                                          ),
                                          trackColor:
                                              WidgetStateProperty.resolveWith(
                                                (states) =>
                                                    states.contains(
                                                      WidgetState.selected,
                                                    )
                                                    ? Colors.blue.shade700
                                                    : Colors.grey.shade700,
                                              ),
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 6),

                                Row(
                                  children: [
                                    TvFocusableItem(
                                      onTap:
                                          (isAvailable &&
                                              enabled &&
                                              level > 1.0)
                                          ? () => manager.setAdoBoostLevel(
                                              ((level - 0.1) * 10).round() / 10,
                                            )
                                          : null,
                                      borderRadius: 10,
                                      child: Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: Icon(
                                          Ionicons.remove_circle_outline,
                                          color:
                                              (isAvailable &&
                                                  enabled &&
                                                  level > 1.0)
                                              ? Colors.blue.shade300
                                              : Colors.grey,
                                          size: 26,
                                        ),
                                      ),
                                    ),

                                    Expanded(
                                      child: Column(
                                        children: [
                                          Text(
                                            '${level.toStringAsFixed(1)}×',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: enabled
                                                  ? Colors.blue.shade200
                                                  : Colors.grey,
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            'volumen de boost',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: AppColors.textSecondary(
                                                mode,
                                              ),
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    TvFocusableItem(
                                      onTap:
                                          (isAvailable &&
                                              enabled &&
                                              level < 1.5)
                                          ? () => manager.setAdoBoostLevel(
                                              ((level + 0.1) * 10).round() / 10,
                                            )
                                          : null,
                                      borderRadius: 10,
                                      child: Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: Icon(
                                          Ionicons.add_circle_outline,
                                          color:
                                              (isAvailable &&
                                                  enabled &&
                                                  level < 1.5)
                                              ? Colors.blue.shade300
                                              : Colors.grey,
                                          size: 26,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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

  /// Muestra opciones de inicio de la app
  void _showStartupDialog() {
    final manager = AudioPlayerManager();
    GlobalModalService.show(
      title: 'Al iniciar la app...',
      icon: Ionicons.play_circle_outline,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _radioOption(
            title: 'Prioridad Ado',
            subtitle: 'Elige una canción aleatoria de Ado.',
            mode: AudioPlayerManager.startupAdo,
            manager: manager,
          ),
          const SizedBox(height: 8),
          _radioOption(
            title: 'Continuar reproducción',
            subtitle: 'Carga la última canción y posición.',
            mode: AudioPlayerManager.startupLast,
            manager: manager,
          ),
        ],
      ),
      actions: [
        ModalActionButton(
          label: 'Cerrar',
          onPressed: () => Navigator.of(
            GlobalModalService.navigatorKey.currentContext!,
          ).pop(),
          color: Colors.grey,
        ),
      ],
    );
  }

  /// Opción de modo de inicio para el diálogo
  Widget _radioOption({
    required String title,
    required String subtitle,
    required String mode,
    required AudioPlayerManager manager,
  }) {
    return ValueListenableBuilder<String>(
      valueListenable: manager.startupModeNotifier,
      builder: (context, currentMode, _) {
        final isSelected = currentMode == mode;
        return TvFocusableItem(
          onTap: () {
            manager.setStartupMode(mode);
            Navigator.pop(context);
            CustomToastService.show(
              context,
              message: isSelected ? 'Modo ya estaba activo' : 'Modo cambiado',
              type: ToastType.success,
            );
          },
          borderRadius: 12,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Icon(
                  isSelected
                      ? Ionicons.radio_button_on
                      : Ionicons.radio_button_off,
                  color: isSelected ? Colors.blue : Colors.grey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Muestra diálogo para temporizador de sueño
  void _showSleepTimerDialog(AppThemeMode mode) {
    final options = [
      ('15 Minutos', 15),
      ('30 Minutos', 30),
      ('60 Minutos', 60),
    ];

    GlobalModalService.show(
      title: 'Temporizador de Sueño',
      icon: Ionicons.timer_outline,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...options.map(
            (o) => TvFocusableItem(
              onTap: () {
                AudioPlayerManager().setSleepTimer(o.$2);
                Navigator.of(
                  GlobalModalService.navigatorKey.currentContext!,
                ).pop();
                CustomToastService.show(
                  GlobalModalService.navigatorKey.currentContext!,
                  message: 'Temporizador: ${o.$1}',
                  type: ToastType.info,
                  icon: Ionicons.timer_outline,
                );
              },
              borderRadius: 12,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Icon(
                      Ionicons.time_outline,
                      color: AppColors.primaryBlueMid,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      o.$1,
                      style: TextStyle(
                        color: AppColors.textPrimary(mode),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Divider(color: Colors.white12),
          TvFocusableItem(
            onTap: () {
              AudioPlayerManager().setSleepTimer(0);
              Navigator.of(
                GlobalModalService.navigatorKey.currentContext!,
              ).pop();
              CustomToastService.show(
                GlobalModalService.navigatorKey.currentContext!,
                message: 'Temporizador desactivado',
                type: ToastType.info,
                icon: Ionicons.timer_outline,
              );
            },
            borderRadius: 12,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Row(
                children: [
                  const Icon(Ionicons.close_circle_outline, color: Colors.red),
                  const SizedBox(width: 12),
                  Text(
                    'Desactivar',
                    style: TextStyle(
                      color: AppColors.textPrimary(mode),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: [
        ModalActionButton(
          label: 'Cerrar',
          onPressed: () => Navigator.of(
            GlobalModalService.navigatorKey.currentContext!,
          ).pop(),
          color: Colors.grey,
        ),
      ],
    );
  }

  /// Muestra un diálogo simple con enlace informativo
  void _showTvLinkDialog({
    required String title,
    required String message,
    required IconData icon,
  }) {
    GlobalModalService.show(
      title: title,
      icon: icon,
      message: message,
      actions: [
        ModalActionButton(
          label: 'Entendido',
          onPressed: () => Navigator.of(
            GlobalModalService.navigatorKey.currentContext!,
          ).pop(),
          color: Colors.blue.shade700,
        ),
      ],
    );
  }

  /// Muestra diálogo de donación
  void _showDonateDialog() {
    GlobalModalService.show(
      title: 'Donar con Nequi',
      icon: Ionicons.cash_outline,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Image.asset('assets/MG Studios/MG-D.png'),
          ),
          const SizedBox(height: 16),
          const Text(
            '316 806 0939',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '¡Gracias por tu apoyo! 💙',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
      actions: [
        ModalActionButton(
          label: 'Cerrar',
          onPressed: () => Navigator.of(
            GlobalModalService.navigatorKey.currentContext!,
          ).pop(),
          color: Colors.grey,
        ),
      ],
    );
  }

  /// Muestra información acerca de la app
  void _showAboutDialog() {
    GlobalModalService.show(
      title: 'Sobre MG Music',
      icon: Ionicons.musical_notes,
      content: _buildAboutContent(),
      actions: [
        ModalActionButton(
          label: 'Cerrar',
          onPressed: () => Navigator.of(
            GlobalModalService.navigatorKey.currentContext!,
          ).pop(),
          color: Colors.blue.shade700,
        ),
      ],
    );
  }

  /// Construye el contenido del diálogo "Acerca de"
  Widget _buildAboutContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _aboutSection(
          title: '🎵 Inspiración',
          body:
              'Esta app nació de mi admiración por la cantante Ado. Notarás detalles especiales cuando reproduzcas sus canciones: colores, orden preferencial y efectos exclusivos.',
        ),
        const SizedBox(height: 16),
        _aboutSection(
          title: '⚖️ Aviso Legal',
          body:
              'Esta es una aplicación independiente creada por un fan. No es una app oficial ni pretende serlo.',
        ),
        const SizedBox(height: 16),
        _aboutSection(
          title: '💻 Desarrollo',
          body:
              'Mantengo este proyecto personalmente con dedicación. Puedes ver el progreso en las actualizaciones periódicas.',
        ),
      ],
    );
  }

  /// Construye una sección de texto para "Acerca de"
  Widget _aboutSection({required String title, required String body}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.blue.shade200,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade900.withOpacity(0.3)),
          ),
          child: Text(
            body,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ),
      ],
    );
  }

  /// Ejecuta la verificación manual de actualización
  Future<void> _checkForUpdatesManual() async {
    BuildContext? dialogCtx;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        dialogCtx = ctx;
        return const UpdateLoadingDialog();
      },
    );
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      final info = await UpdateService.checkForUpdate();
      if (mounted && dialogCtx != null && dialogCtx!.mounted) {
        try {
          Navigator.of(dialogCtx!).pop();
        } catch (_) {}
      }
      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;

      if (info['hasUpdate'] == true) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => UpdateDialog(versionData: info['data'], isTv: true),
        );
      } else if (info['error'] != null) {
        CustomToastService.show(
          context,
          message: 'Error: ${info['error']}',
          type: ToastType.error,
        );
      } else {
        CustomToastService.show(
          context,
          message: 'Ya tienes la última versión 🎉',
          type: ToastType.success,
          icon: Ionicons.checkmark_circle,
        );
      }
    } catch (e) {
      if (mounted && dialogCtx != null && dialogCtx!.mounted) {
        try {
          Navigator.of(dialogCtx!).pop();
        } catch (_) {}
      }
      if (mounted) {
        CustomToastService.show(
          context,
          message: 'Error inesperado: $e',
          type: ToastType.error,
        );
      }
    }
  }
}
