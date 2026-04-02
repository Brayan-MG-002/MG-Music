// Copyright © 2026 Brayan Medrano - MG Music
// Página de ajustes principal para la interfaz de TV, con opciones de personalización, gestión de archivos y enlaces de soporte.

import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:ionicons/ionicons.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mg_music/services/models/song_model.dart';
import 'package:mg_music/services/audio/audio_player_manager.dart';
import 'package:mg_music/ui/tv/tv_focusable_item.dart';
import 'package:mg_music/services/logic/update_service.dart';
import 'package:mg_music/services/ui/custom_toast_service.dart';
import 'package:mg_music/services/ui/global_modal_service.dart';
import 'package:mg_music/services/ui/theme_service.dart';
import 'package:mg_music/ui/shared/screens/update_dialog.dart';
import 'package:mg_music/ui/shared/screens/update_loading_dialog.dart';
import 'package:mg_music/services/audio/ado_handler.dart';
import 'dart:io';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:mg_music/main.dart' show isBeta;
import 'package:mg_music/ui/mobile/Home/Settings/components/backup_settings_page.dart';
import 'package:mg_music/ui/mobile/Home/Settings/components/folder_settings_modal.dart';
import 'package:mg_music/ui/mobile/Home/Settings/components/theme_settings_modal.dart';
import 'package:mg_music/ui/mobile/Home/Settings/components/link_dialog.dart';
import 'package:mg_music/services/ui/ado_experience_service.dart';
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
  String _appVersion = '';
  bool _hasPendingUpdate = false;

  @override
  void initState() {
    super.initState();
    _loadAdoStatus();
    _loadAppVersion();
    _loadPendingUpdateState();
  }

  Future<void> _loadAdoStatus() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _hasAdoSongs = prefs.getBool('has_ado_songs') ?? true;
      });
    }
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _appVersion = info.version);
  }

  Future<void> _loadPendingUpdateState() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getInt('pending_update_version_code') ?? 0;
    if (mounted) setState(() => _hasPendingUpdate = code > 0);
  }

  @override
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
                if (isBeta)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlueMid.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primaryBlueMid.withOpacity(0.5),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          'BETA',
                          style: TextStyle(
                            color: AppColors.primaryBlueMid,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            letterSpacing: 2.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 36),

                if (isBeta) ...[
                  TvSettingsSectionTitle(title: 'Beta Program', mode: mode),
                  TvSettingsRow(
                    left: TvSettingsTile(
                      icon: Ionicons.bug_outline,
                      title: 'Reportar Error (Beta)',
                      subtitle: 'Informa fallos visuales o técnicos',
                      onTap: () => _showBetaErrorReport(context, mode),
                      mode: mode,
                    ),
                    right: const SizedBox.shrink(),
                  ),
                ],

                TvSettingsSectionTitle(title: 'General', mode: mode),

                TvSettingsRow(
                  left: _buildThemeTile(mode),
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
                  left: TvSettingsTile(
                    icon: Ionicons.folder_outline,
                    title: 'Ubicación de Música',
                    subtitle: 'Elegir qué carpetas escanear',
                    onTap: () => FolderSettingsContent.showModal(context, isTv: true),
                    mode: mode,
                  ),
                  right: TvSettingsTile(
                    icon: Ionicons.shield_checkmark_outline,
                    title: 'Gestión de Copias',
                    subtitle: 'Configurar, crear y restaurar respaldos',
                    onTap: () => _navigateTo(const BackupSettingsPage()),
                    mode: mode,
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
                            ? (minutes == -1
                                ? 'Al terminar canción'
                                : '$minutes min restantes')
                            : 'Apagado',
                        isActive: isActive,
                        onTap: () => GlobalModalService.showSleepTimerDialog(context),
                        mode: mode,
                      );
                    },
                  ),
                  right: TvSettingsTile(
                    icon: Ionicons.cloud_download_outline,
                    title: 'Actualizar',
                    subtitle: _hasPendingUpdate
                        ? '⚠️ Actualización pendiente'
                        : 'Buscar nueva versión',
                    onTap: () => _checkForUpdatesManual(),
                    mode: mode,
                    badge: _hasPendingUpdate,
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

                TvSettingsRow(
                  left: ValueListenableBuilder<bool>(
                    valueListenable: AdoExperienceService().dynamicColorEnabledNotifier,
                    builder: (context, enabled, _) => TvSettingsSwitchTile(
                      icon: Ionicons.color_filter_outline,
                      title: 'Colores Dinámicos',
                      subtitle: enabled ? 'Activados' : 'Desactivados',
                      value: enabled,
                      onChanged: (val) => AdoExperienceService().setDynamicColorEnabled(val),
                      mode: mode,
                    ),
                  ),
                  right: ValueListenableBuilder<int>(
                    valueListenable: AdoExperienceService().dynamicColorModeNotifier,
                    builder: (context, colorMode, _) {
                      final labels = ['Fijo', 'Latido', 'Múltiple'];
                      final isEnabled = AdoExperienceService().dynamicColorEnabled;
                      return TvSettingsTile(
                        icon: Ionicons.options_outline,
                        title: 'Modo de Color',
                        subtitle: !isEnabled ? 'Habilita colores primero' : labels[colorMode],
                        onTap: isEnabled ? () async {
                          final selected = await GlobalModalService.showSelectionList<int>(
                            title: 'Modo de Color Dinámico',
                            icon: Ionicons.color_filter_outline,
                            items: [0, 1, 2],
                            labelBuilder: (idx) => labels[idx],
                          );
                          if (selected != null) {
                            AdoExperienceService().setDynamicColorMode(selected);
                          }
                        } : null,
                        disabled: !isEnabled,
                        mode: mode,
                      );
                    },
                  ),
                ),

                TvSettingsSectionTitle(
                  title: 'Información de la App',
                  mode: mode,
                ),

                TvSettingsRow(
                  left: TvSettingsTile(
                    icon: Ionicons.sparkles_outline,
                    title: 'Novedades de la Versión',
                    subtitle: _appVersion.isEmpty
                        ? 'Descubre qué hay de nuevo'
                        : 'Descubre qué hay de nuevo en la v$_appVersion',
                    onTap: () => _showWhatsNewDialog(),
                    mode: mode,
                  ),
                  right: TvSettingsTile(
                    icon: Ionicons.musical_notes,
                    title: 'Acerca de MG Music',
                    subtitle: 'Inspiración y avisos legales',
                    onTap: () => _showAboutDialog(),
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
                  right: TvSettingsTile(
                    icon: Ionicons.logo_paypal,
                    title: 'Donar',
                    subtitle: 'Apoya con PayPal',
                    onTap: () => _showDonateDialog(),
                    mode: mode,
                  ),
                ),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeTile(AppThemeMode mode) {
    return Consumer<ThemeService>(
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

        return TvSettingsTile(
          icon: Ionicons.color_palette_outline,
          title: 'Tema',
          subtitle: desc,
          onTap: () => ThemeSettingsContent.showModal(context, isTv: true),
          mode: mode,
        );
      },
    );
  }

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

  Future<void> _showBetaErrorReport(
    BuildContext context,
    AppThemeMode mode,
  ) async {
    final textController = TextEditingController();

    // 1. Elegir tipo de error
    final selectedType = await GlobalModalService.showSelectionList<String>(
      title: 'Tipo de Error',
      icon: Ionicons.bug_outline,
      items: ['Visual / Diseño', 'Funcional / Técnico', 'Otro / Sugerencia'],
      labelBuilder: (item) => item,
    );

    if (selectedType == null) return;

    // 2. Detallar el error
    if (!context.mounted) return;

    final confirmDescription = await GlobalModalService.show<bool>(
      title: 'Detalles del Error',
      icon: Ionicons.create_outline,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Por favor describe brevemente qué sucede:',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: textController,
            maxLines: 4,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Ej: Al abrir el reproductor la imagen parpadea...',
              hintStyle: const TextStyle(color: Colors.white30),
              filled: true,
              fillColor: Colors.black26,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: AppColors.primaryBlueMid),
              ),
            ),
          ),
        ],
      ),
      actions: [
        ModalActionButton(
          label: 'Cancelar',
          onPressed: () => Navigator.pop(
            GlobalModalService.navigatorKey.currentContext!,
            false,
          ),
          color: Colors.grey.shade600,
        ),
        ModalActionButton(
          label: 'Siguiente',
          onPressed: () => Navigator.pop(
            GlobalModalService.navigatorKey.currentContext!,
            true,
          ),
          color: AppColors.primaryBlueMid,
        ),
      ],
    );

    if (confirmDescription != true || textController.text.trim().isEmpty) return;

    // 3. Confirmación y envío
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

    final msg = '''*REPORTE DE ERROR - MG MUSIC BETA (TV)*
-------------------------------
*Tipo:* $selectedType
*Descripción:* ${textController.text.trim()}

*DATOS TÉCNICOS:*
• App Versión: ${_appVersion.isEmpty ? 'N/A' : _appVersion}
• Android: $androidVersion
• Dispositivo: $brand $deviceModel (TV)
-------------------------------''';

    final whatsappUrl =
        "https://wa.me/573168060939?text=${Uri.encodeComponent(msg)}";

    await LinkDialog.show(
      context: context,
      title: 'Confirmar Envío',
      icon: Ionicons.logo_whatsapp,
      content:
          'Se enviará tu mensaje junto con información técnica (App, Android y Dispositivo) para ayudarnos a resolver el error.\n\n¿Abrir WhatsApp?',
      url: whatsappUrl,
    );
  }

  void _navigateTo(Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => Scaffold(body: page)),
    );
  }

  void _showWhatsNewDialog() {
    GlobalModalService.show(
      title: _appVersion.isEmpty ? 'Novedades' : 'Novedades v$_appVersion',
      icon: Ionicons.sparkles_outline,
      content: _buildWhatsNewContent(),
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

  Widget _buildWhatsNewContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _aboutSection(
          title: '🚀 Sincronización Total (v1.2.0)',
          body:
              '• Unificación de funciones entre TV y Mobile.\n• Nueva gestión de Copias de Seguridad en TV.\n• Soporte para Reporte de Errores Beta.\n• Colores Dinámicos para canciones de Ado.',
        ),
        const SizedBox(height: 12),
        _aboutSection(
          title: '🎵 Editor de Metadatos',
          body:
              '• Modifica título, artista y carátula de tus canciones.\n• Cambios permanentes en los archivos locales.\n• Organización mejorada de la biblioteca musical.',
        ),
        const SizedBox(height: 12),
        _aboutSection(
          title: '✨ Mejoras de Sistema',
          body:
              '• Detección inteligente de orientación y dispositivo.\n• Pantalla de permisos renovada y responsiva.\n• Optimización de carga y animaciones fluidas.',
        ),
      ],
    );
  }

  void _showDonateDialog() {
    GlobalModalService.show(
      title: 'Donar por PayPal',
      icon: Ionicons.logo_paypal,
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
            'Escanea para donar',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
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
