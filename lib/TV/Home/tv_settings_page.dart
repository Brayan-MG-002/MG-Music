// Copyright © 2026 Brayan Medrano - MG Music
// Página de configuración TV

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ionicons/ionicons.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:mg_music/Logic/audio_player_manager.dart';
import 'package:mg_music/TV/tv_focusable_item.dart';
import 'package:mg_music/services/update_service.dart';
import 'package:mg_music/screens/update_dialog.dart';
import 'package:mg_music/screens/update_loading_dialog.dart';

class TvSettingsPage extends StatefulWidget {
  const TvSettingsPage({super.key});

  @override
  State<TvSettingsPage> createState() => _TvSettingsPageState();
}

class _TvSettingsPageState extends State<TvSettingsPage> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Cabecera (Logo Clickable)
          Center(child: const _InteractiveLogo()),
          const SizedBox(height: 40),

          // 2. Grid de Configuración (2 Columnas)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Columna Izquierda: Sistema y Reproducción
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Sistema'),
                    ValueListenableBuilder<bool>(
                      valueListenable:
                          AudioPlayerManager().showVisualizerNotifier,
                      builder: (context, show, _) {
                        return _buildSwitchTile(
                          context,
                          icon: Ionicons.bar_chart_outline,
                          title: 'Visualizador',
                          subtitle: show ? 'Activado' : 'Desactivado',
                          value: show,
                          onChanged: (val) =>
                              AudioPlayerManager().toggleVisualizer(val),
                        );
                      },
                    ),
                    const SizedBox(height: 15),
                    ValueListenableBuilder<int?>(
                      valueListenable: AudioPlayerManager().sleepTimerNotifier,
                      builder: (context, minutes, _) {
                        final isActive = minutes != null;
                        return _buildSettingTile(
                          context,
                          icon: isActive
                              ? Ionicons.timer
                              : Ionicons.timer_outline,
                          title: 'Temporizador',
                          subtitle: isActive
                              ? '$minutes min restantes'
                              : 'Apagado',
                          isActive: isActive,
                          onTap: () => _showSleepTimerDialog(context),
                        );
                      },
                    ),
                    const SizedBox(height: 15),
                    _buildSettingTile(
                      context,
                      icon: Ionicons.cloud_download_outline,
                      title: 'Actualizar',
                      subtitle: 'Buscar nueva versión',
                      onTap: () => _checkForUpdatesManual(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 30),
              // Columna Derecha: Experiencia Ado
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Experiencia Ado'),
                    ValueListenableBuilder<String>(
                      valueListenable: AudioPlayerManager().startupModeNotifier,
                      builder: (context, mode, _) {
                        final isAdo = mode == AudioPlayerManager.startupAdo;
                        return _buildSettingTile(
                          context,
                          icon: Ionicons.play_circle_outline,
                          title: 'Inicio de App',
                          subtitle: isAdo ? 'Modo Ado' : 'Última sesión',
                          isActive: isAdo, // Highlight if Ado mode is on
                          onTap: () => _showStartupDialog(context),
                        );
                      },
                    ),
                    const SizedBox(height: 15),
                    _buildSettingTile(
                      context,
                      icon: Ionicons.musical_notes,
                      title: 'Inspiración',
                      subtitle: 'Sobre el proyecto',
                      onTap: () => _showAboutDialog(context),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 40),

          // 3. Sección Contacto (Fila Horizontal)
          _buildSectionTitle('Contacto y Apoyo'),
          Row(
            children: [
              Expanded(
                child: _buildSettingTile(
                  context,
                  icon: Ionicons.logo_facebook,
                  title: 'Facebook',
                  subtitle: 'Sígueme',
                  onTap: () => _showInfoDialog(
                    context,
                    'Facebook',
                    'https://www.facebook.com/Brayan.MG.002',
                    Ionicons.logo_facebook,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildSettingTile(
                  context,
                  icon: Ionicons.logo_whatsapp,
                  title: 'WhatsApp',
                  subtitle: 'Soporte',
                  onTap: () => _showInfoDialog(
                    context,
                    'WhatsApp',
                    '+57 316 8060939',
                    Ionicons.logo_whatsapp,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildSettingTile(
                  context,
                  icon: Ionicons.cash_outline,
                  title: 'Donar',
                  subtitle: 'Nequi',
                  onTap: () => _showNequiDialog(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return TvFocusableItem(
      onTap: onTap,
      borderRadius: 12,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.blue.shade900.withOpacity(0.3)
              : Colors.white10,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? Colors.blue : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isActive ? Colors.blue : Colors.white70,
              size: 28,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return TvFocusableItem(
      onTap: () => onChanged(!value),
      borderRadius: 12,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value ? Colors.blue.shade900 : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: value ? Colors.blue : Colors.grey, size: 28),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.blue,
              activeTrackColor: Colors.blue.shade900,
            ),
          ],
        ),
      ),
    );
  }

  void _showStartupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey.shade900,
          title: const Text(
            'Al iniciar la app...',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildRadioOption(
                'Prioridad Ado',
                'Elige una canción aleatoria de Ado.',
                AudioPlayerManager.startupAdo,
              ),
              _buildRadioOption(
                'Continuar reproducción',
                'Carga la última canción y posición.',
                AudioPlayerManager.startupLast,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRadioOption(String title, String subtitle, String value) {
    return ValueListenableBuilder<String>(
      valueListenable: AudioPlayerManager().startupModeNotifier,
      builder: (context, currentMode, _) {
        final isSelected = currentMode == value;
        return TvFocusableItem(
          onTap: () {
            AudioPlayerManager().setStartupMode(value);
            Navigator.pop(context);
          },
          child: ListTile(
            leading: Icon(
              isSelected ? Ionicons.radio_button_on : Ionicons.radio_button_off,
              color: isSelected ? Colors.blue.shade900 : Colors.grey,
            ),
            title: Text(title, style: const TextStyle(color: Colors.white)),
            subtitle: Text(
              subtitle,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        );
      },
    );
  }

  void _showSleepTimerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey.shade900,
          title: const Text(
            'Detener audio en...',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTimerOption(context, '15 Minutos', 15),
              _buildTimerOption(context, '30 Minutos', 30),
              _buildTimerOption(context, '60 Minutos', 60),
              _buildTimerOption(context, 'Personalizar...', -1),
              _buildTimerOption(context, 'Desactivar', 0),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimerOption(BuildContext context, String title, int minutes) {
    return TvFocusableItem(
      onTap: () {
        if (minutes == -1) {
          _showCustomTimerDialog(context);
        } else {
          AudioPlayerManager().setSleepTimer(minutes);
          Navigator.pop(context);
        }
      },
      child: ListTile(
        leading: const Icon(Ionicons.time_outline, color: Colors.white70),
        title: Text(title, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  void _showCustomTimerDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text(
          'Tiempo personalizado (min)',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Ej: 45',
            hintStyle: TextStyle(color: Colors.white54),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.blue),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              final minutes = int.tryParse(controller.text);
              if (minutes != null && minutes > 0) {
                AudioPlayerManager().setSleepTimer(minutes);
                Navigator.pop(context); // Close custom dialog
                Navigator.pop(context); // Close list dialog
              }
            },
            child: const Text('Iniciar', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    final ScrollController scrollController = ScrollController();
    final FocusNode dialogFocusNode = FocusNode();

    showDialog(
      context: context,
      builder: (context) => Focus(
        focusNode: dialogFocusNode,
        autofocus: true,
        onKey: (node, event) {
          // Permitir scroll con las teclas de dirección en TV
          if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            scrollController.animateTo(
              scrollController.offset - 50,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            scrollController.animateTo(
              scrollController.offset + 50,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: AlertDialog(
          backgroundColor: Colors.grey.shade900,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(color: Colors.blue.shade900, width: 2),
          ),
          title: const Text(
            'Sobre MG Music',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          content: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo/Icono
                Center(
                  child: Icon(
                    Ionicons.heart,
                    color: Colors.blue.shade900,
                    size: 80,
                  ),
                ),
                const SizedBox(height: 30),

                // 1. Inspiración
                _buildAboutSection(
                  title: '🎵 Inspiración del Proyecto',
                  content: [
                    const Text(
                      'Esta aplicación nació de mi admiración por la cantante Ado.',
                      style: TextStyle(color: Colors.white, fontSize: 15),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Por eso, notarás detalles especiales cuando reproduzcas sus canciones:',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '• Colores temáticos en azul oscuro\n• Orden preferencial en listas\n• Efectos especiales exclusivos',
                      style: TextStyle(
                        color: Colors.blue.shade200,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),

                // 2. Información Legal
                _buildAboutSection(
                  title: '⚖️ Aviso Legal',
                  content: [
                    const Text(
                      'Esta es una aplicación independiente creada por un fan.',
                      style: TextStyle(color: Colors.white, fontSize: 15),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'No es una app oficial ni pretende hacerse pasar por una. Todo el contenido y diseño está inspirado en mi artista favorita.',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 25),

                // 3. Desarrollo
                _buildAboutSection(
                  title: '💻 Desarrollo',
                  content: [
                    const Text(
                      'Mantengo este proyecto personalmente con dedicación y pasión.',
                      style: TextStyle(color: Colors.white, fontSize: 15),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Puedes ver el progreso del desarrollo en las actualizaciones periódicas que lanzo.',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 25),

                // 4. Apoyo
                _buildAboutSection(
                  title: '❤️ Apoya el Proyecto',
                  content: [
                    const Text(
                      'Las donaciones son totalmente opcionales y me ayudan a seguir mejorando la app.',
                      style: TextStyle(color: Colors.white, fontSize: 15),
                    ),
                    const SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.blue.shade900,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.black.withOpacity(0.3),
                      ),
                      child: Column(
                        children: [
                          SizedBox(
                            width: 120,
                            height: 120,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.shade900),
                              ),
                              padding: const EdgeInsets.all(8),
                              child: Image.asset('assets/MG Studios/MG-D.png'),
                            ),
                          ),
                          const SizedBox(height: 15),
                          const SelectableText(
                            '316 806 0939',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Nequi / Billetera Digital',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.blue.shade200,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '¡Gracias por tu apoyo! Cada contribución cuenta 💙',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar', style: TextStyle(color: Colors.blue)),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget auxiliar para secciones del diálogo about
  Widget _buildAboutSection({
    required String title,
    required List<Widget> content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.blue.shade200,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.blue.shade900.withOpacity(0.3),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(8),
            color: Colors.black.withOpacity(0.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: content,
          ),
        ),
      ],
    );
  }

  void _showInfoDialog(
    BuildContext context,
    String title,
    String content,
    IconData icon,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: Colors.blue.shade900, width: 2),
        ),
        title: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 50),
            const SizedBox(height: 20),
            Text(
              content,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  void _showNequiDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: Colors.blue.shade900, width: 2),
        ),
        title: const Text(
          'Donar con Nequi',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Image.asset('assets/MG Studios/MG-D.png'),
            ),
            const SizedBox(height: 20),
            const Text(
              'Número: 316 806 0939',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '¡Gracias por tu apoyo!',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  /// Verifica manualmente si hay actualizaciones disponibles
  Future<void> _checkForUpdatesManual(BuildContext context) async {
    BuildContext? dialogContext;

    // Mostrar diálogo de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        dialogContext = ctx;
        return const UpdateLoadingDialog();
      },
    );

    // Dar tiempo a que se renderice el diálogo
    await Future.delayed(const Duration(milliseconds: 300));

    try {
      // Buscar actualizaciones (incluye verificación de internet internamente)
      final updateInfo = await UpdateService.checkForUpdate();

      // Cerrar diálogo de carga si aún existe
      if (mounted && dialogContext != null && dialogContext!.mounted) {
        try {
          Navigator.of(dialogContext!).pop();
        } catch (_) {}
      }

      // Esperar a que se cierre el diálogo
      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted) return;

      // Mostrar resultado
      if (updateInfo['hasUpdate']) {
        // Hay actualización disponible
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) =>
              UpdateDialog(versionData: updateInfo['data'], isTv: true),
        );
      } else if (updateInfo['error'] != null) {
        // Error al verificar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${updateInfo['error']}'),
            backgroundColor: Colors.red.shade900,
          ),
        );
      } else {
        // Sin actualizaciones disponibles
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ya tienes la última versión'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Cerrar diálogo en caso de error inesperado
      if (mounted && dialogContext != null && dialogContext!.mounted) {
        try {
          Navigator.of(dialogContext!).pop();
        } catch (_) {}
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error inesperado: $e'),
            backgroundColor: Colors.red.shade900,
          ),
        );
      }
    }
  }
}

class _InteractiveLogo extends StatefulWidget {
  const _InteractiveLogo();

  @override
  State<_InteractiveLogo> createState() => _InteractiveLogoState();
}

class _InteractiveLogoState extends State<_InteractiveLogo>
    with TickerProviderStateMixin {
  late AnimationController _borderController;
  late AnimationController _wobbleController;
  late AnimationController _pulseController;
  Timer? _holdTimer;
  final AudioPlayerManager _audioManager = AudioPlayerManager();
  Color _neonColor = Colors.blue.shade900;

  @override
  void initState() {
    super.initState();
    // Animación del borde (2 segundos para rodear completo)
    _borderController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    // Animación de pulso/neón (se activa al terminar el borde)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _borderController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    });

    // Animación de tambaleo (rápida)
    _wobbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _audioManager.currentSongNotifier.addListener(_checkCurrentSong);
    _checkCurrentSong();
  }

  void _checkCurrentSong() {
    final song = _audioManager.currentSongNotifier.value;
    _updateColor(song?.artwork);
    if (song != null && song.artist.toLowerCase().contains('ado')) {
      _borderController.forward();
    } else {
      _borderController.reverse();
    }
  }

  Future<void> _updateColor(Uint8List? artwork) async {
    if (artwork == null) {
      if (mounted) setState(() => _neonColor = Colors.blue.shade900);
      return;
    }
    try {
      final generator = await PaletteGenerator.fromImageProvider(
        ResizeImage(MemoryImage(artwork), width: 100, height: 100),
        maximumColorCount: 5,
      );
      if (mounted) {
        setState(() {
          _neonColor = generator.dominantColor?.color ?? Colors.blue.shade900;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _neonColor = Colors.blue.shade900);
    }
  }

  @override
  void dispose() {
    _audioManager.currentSongNotifier.removeListener(_checkCurrentSong);
    _borderController.dispose();
    _wobbleController.dispose();
    _pulseController.dispose();
    _holdTimer?.cancel();
    super.dispose();
  }

  void _startHold() {
    if (_holdTimer != null) return; // Evitar reinicios múltiples

    // Verificar si el usuario tiene canciones de Ado
    final adoSongs = _audioManager.playlist
        .where((s) => s.artist.toLowerCase().contains('ado'))
        .toList();

    if (adoSongs.isEmpty) return; // Si no tiene, no hace nada

    // Iniciar tambaleo
    _wobbleController.repeat(reverse: true);

    // Iniciar temporizador de 2.5 segundos
    _holdTimer = Timer(const Duration(milliseconds: 2500), () {
      _resetHold();
      // Reproducir canción aleatoria
      final randomSong = adoSongs[math.Random().nextInt(adoSongs.length)];
      _audioManager.playWithFade(randomSong, _audioManager.playlist);
    });
  }

  void _onPointerDown(PointerDownEvent event) {
    _startHold();
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    final isSelect =
        event.logicalKey == LogicalKeyboardKey.select ||
        event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.space;

    if (isSelect) {
      if (event is KeyDownEvent) {
        _startHold();
        return KeyEventResult.handled;
      } else if (event is KeyUpEvent) {
        _resetHold();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  void _resetHold() {
    _holdTimer?.cancel();
    _holdTimer = null;
    _wobbleController.stop();
    _wobbleController.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _onPointerDown,
      onPointerUp: (_) => _resetHold(),
      onPointerCancel: (_) => _resetHold(),
      child: TvFocusableItem(
        onTap: () {},
        onKeyEvent: _onKeyEvent,
        borderRadius: 20,
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            children: [
              TweenAnimationBuilder<Color?>(
                duration: const Duration(milliseconds: 1000),
                curve: Curves.linear,
                tween: ColorTween(begin: Colors.blue.shade900, end: _neonColor),
                builder: (context, animatedColor, _) {
                  return AnimatedBuilder(
                    animation: Listenable.merge([
                      _borderController,
                      _wobbleController,
                      _pulseController,
                    ]),
                    builder: (context, child) {
                      double rotation = 0;
                      if (_wobbleController.isAnimating) {
                        rotation =
                            math.sin(_wobbleController.value * math.pi * 2) *
                            0.05;
                      }

                      double scale = 1.0;
                      if (_pulseController.isAnimating) {
                        scale = 1.0 + (_pulseController.value * 0.1);
                      }

                      return Transform.rotate(
                        angle: rotation,
                        child: CustomPaint(
                          foregroundPainter: _LogoBorderPainter(
                            progress: _borderController.value,
                            color: animatedColor ?? Colors.blue.shade900,
                            glowOpacity: _pulseController.value,
                          ),
                          child: Transform.scale(
                            scale: scale,
                            child: Image.asset('assets/MG-I-T.png', width: 120),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 10),
              const Text(
                'MG Music',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text('Versión 1.0.0', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoBorderPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double glowOpacity;

  _LogoBorderPainter({
    required this.progress,
    required this.color,
    this.glowOpacity = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) + 15;

    if (glowOpacity > 0) {
      final glowPaint = Paint()
        ..color = color.withOpacity(glowOpacity * 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0 + (glowOpacity * 2.0)
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        glowPaint,
      );
    }

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    // Dibuja el arco desde arriba (-pi/2)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_LogoBorderPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.glowOpacity != glowOpacity;
  }
}
