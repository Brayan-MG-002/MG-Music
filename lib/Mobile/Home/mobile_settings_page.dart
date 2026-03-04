// Copyright © 2026 Brayan Medrano - MG Music
// Página de configuración Mobile

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ionicons/ionicons.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:mg_music/Logic/audio_player_manager.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mg_music/services/update_service.dart';
import 'package:mg_music/screens/update_dialog.dart';
import 'package:mg_music/screens/update_loading_dialog.dart';

/// Página de configuración Mobile
class MobileSettingsPage extends StatefulWidget {
  const MobileSettingsPage({super.key});

  @override
  State<MobileSettingsPage> createState() => _MobileSettingsPageState();
}

class _MobileSettingsPageState extends State<MobileSettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        children: [
          const Center(child: _InteractiveLogo()),
          const SizedBox(height: 30),

          _buildSectionTitle('Sistema'),
          _buildSettingItem(
            icon: Ionicons.timer_outline,
            title: 'Temporizador',
            subtitle: 'Configurar apagado automático',
            onTap: () => _showSleepTimerModal(context),
          ),
          _buildSettingItem(
            icon: Ionicons.cloud_download_outline,
            title: 'Actualizar',
            subtitle: 'Buscar nueva versión de la app',
            onTap: () => _checkForUpdatesManual(context),
          ),

          const SizedBox(height: 20),
          _buildSectionTitle('Experiencia Ado'),
          _buildSettingItem(
            icon: Ionicons.play_circle_outline,
            title: 'Inicio de App',
            subtitle: 'Personalizar comportamiento al abrir',
            onTap: () => _showStartupModeModal(context),
          ),
          _buildSettingItem(
            icon: Ionicons.musical_notes,
            title: 'Inspiración',
            subtitle: 'Avisos legales de Ado y demás',
            onTap: () => _navigateTo(context, const _AboutPage()),
          ),

          const SizedBox(height: 20),
          _buildSectionTitle('Contacto y Apoyo'),
          _buildSettingItem(
            icon: Ionicons.logo_facebook,
            title: 'Facebook',
            subtitle: 'Sígueme para novedades',
            onTap: () => _showLinkConfirmationDialog(
              context: context,
              title: 'Ir a Facebook',
              icon: Ionicons.logo_facebook,
              content:
                  'Serás redirigido a mi perfil de Facebook donde se publican todas las novedades y actualizaciones de la app.',
              url: 'https://www.facebook.com/Brayan.MG.002',
            ),
          ),
          _buildSettingItem(
            icon: Ionicons.logo_whatsapp,
            title: 'WhatsApp',
            subtitle: 'Soporte directo',
            onTap: () => _showLinkConfirmationDialog(
              context: context,
              title: 'Abrir WhatsApp',
              icon: Ionicons.logo_whatsapp,
              content:
                  'Usa este chat para reportar errores o enviar sugerencias directamente.',
              url: 'https://wa.me/573168060939',
            ),
          ),
          _buildSettingItem(
            icon: Ionicons.cash_outline,
            title: 'Donar',
            subtitle: 'Apoya con Nequi',
            onTap: () => _showDonateModal(context),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 10),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.blue.shade900,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey)),
      trailing: const Icon(Ionicons.chevron_forward, color: Colors.grey),
      onTap: onTap,
    );
  }

  void _navigateTo(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  Future<void> _launchExternalUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Future<void> _showLinkConfirmationDialog({
    required BuildContext context,
    required String title,
    required IconData icon,
    required String content,
    required String url,
  }) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.grey.shade900,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(color: Colors.blue.shade900, width: 2),
          ),
          title: Row(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            content,
            style: const TextStyle(color: Colors.white70, height: 1.5),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.grey),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade900,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _launchExternalUrl(url);
              },
              child: const Text('Continuar'),
            ),
          ],
        );
      },
    );
  }

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
          builder: (_) => UpdateDialog(versionData: updateInfo['data']),
        );
      } else if (updateInfo['error'] != null) {
        // Error al verificar
        _showUpdateResultSnackBar(
          context,
          updateInfo['error'],
          isSuccess: false,
        );
      } else {
        // No hay actualización
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

  void _showUpdateResultSnackBar(
    BuildContext context,
    String message, {
    required bool isSuccess,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess
            ? Colors.green.shade700
            : Colors.red.shade700,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSleepTimerModal(BuildContext pageContext) {
    showModalBottomSheet(
      context: pageContext,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(
            top: BorderSide(color: Colors.blue.shade900, width: 2),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade700,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Temporizador de Apagado',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildTimerOption(pageContext, context, '15 Minutos', 15),
            _buildTimerOption(pageContext, context, '30 Minutos', 30),
            _buildTimerOption(pageContext, context, '60 Minutos', 60),
            _buildTimerOption(pageContext, context, 'Personalizado', -1),
            _buildTimerOption(pageContext, context, 'Desactivar', 0),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerOption(
    BuildContext pageContext,
    BuildContext modalContext,
    String title,
    int minutes,
  ) {
    return ListTile(
      leading: Icon(
        minutes == 0 ? Ionicons.close_circle_outline : Ionicons.time_outline,
        color: minutes == 0 ? Colors.red : Colors.white,
      ),
      title: Text(
        title,
        style: TextStyle(color: minutes == 0 ? Colors.red : Colors.white),
      ),
      onTap: () {
        Navigator.pop(modalContext);
        if (minutes == -1) {
          _showCustomTimerDialog(pageContext);
        } else {
          AudioPlayerManager().setSleepTimer(minutes);
          if (minutes > 0) {
            ScaffoldMessenger.of(pageContext).showSnackBar(
              SnackBar(
                content: Text('Apagado programado en $minutes minutos'),
                backgroundColor: Colors.blue.shade900,
              ),
            );
          }
        }
      },
    );
  }

  void _showCustomTimerDialog(BuildContext pageContext) {
    final controller = TextEditingController();
    showDialog(
      context: pageContext,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: Colors.blue.shade900, width: 2),
        ),
        title: const Text(
          'Tiempo Personalizado',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          cursorColor: Colors.blue,
          decoration: const InputDecoration(
            hintText: 'Minutos',
            hintStyle: TextStyle(color: Colors.grey),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.blue),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.blue, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              final mins = int.tryParse(controller.text);
              if (mins != null && mins > 0) {
                AudioPlayerManager().setSleepTimer(mins);
                Navigator.pop(context);
                ScaffoldMessenger.of(pageContext).showSnackBar(
                  SnackBar(
                    content: Text('Apagado programado en $mins minutos'),
                    backgroundColor: Colors.blue.shade900,
                  ),
                );
              }
            },
            child: const Text('Iniciar', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  void _showStartupModeModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(
            top: BorderSide(color: Colors.blue.shade900, width: 2),
          ),
        ),
        child: ValueListenableBuilder<String>(
          valueListenable: AudioPlayerManager().startupModeNotifier,
          builder: (context, currentMode, _) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade700,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Inicio de App',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                _buildRadioOption(
                  context,
                  'Prioridad Ado',
                  'Elige una canción aleatoria de Ado al iniciar.',
                  AudioPlayerManager.startupAdo,
                  currentMode,
                ),
                _buildRadioOption(
                  context,
                  'Continuar reproducción',
                  'Carga la última canción y posición.',
                  AudioPlayerManager.startupLast,
                  currentMode,
                ),
                const SizedBox(height: 30),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildRadioOption(
    BuildContext context,
    String title,
    String subtitle,
    String value,
    String groupValue,
  ) {
    final isSelected = value == groupValue;
    return ListTile(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey)),
      leading: Icon(
        isSelected ? Ionicons.radio_button_on : Ionicons.radio_button_off,
        color: isSelected ? Colors.blue.shade900 : Colors.grey,
      ),
      onTap: () {
        AudioPlayerManager().setStartupMode(value);
        Navigator.pop(context);
      },
    );
  }

  void _showDonateModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(
            top: BorderSide(color: Colors.blue.shade900, width: 2),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade700,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Apoya el Proyecto',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.all(10),
              child: Image.asset('assets/MG Studios/MG-D.png'),
            ),
            const SizedBox(height: 20),
            const SelectableText(
              '316 806 0939',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Clipboard.setData(const ClipboardData(text: '3168060939'));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Número copiado al portapapeles'),
                        backgroundColor: Colors.blue.shade900,
                      ),
                    );
                  },
                  icon: const Icon(Ionicons.copy_outline),
                  label: const Text('Copiar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade900,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Tu donación vía Nequi es totalmente opcional, pero me ayudas mucho a continuar con el desarrollo de la app. ¡Gracias por tu apoyo!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

// --- Sub-Páginas (En lugar de Modales) ---

class _AboutPage extends StatelessWidget {
  const _AboutPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Acerca de', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          Center(child: Image.asset('assets/MG-I-T.png', width: 100)),
          const SizedBox(height: 20),
          const Center(
            child: Text(
              'MG Music',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 30),
          _buildSection(
            title: 'Inspiración',
            icon: Ionicons.heart,
            content:
                'Hola, soy Brayan Medrano. Este proyecto es un hobby personal que hice en mis ratos libres, inspirado en mi amor por Ado y su música.\n\nLa idea surgió como una forma de disfrutar su música con algunos detalles especiales que pensé sería cool tener. Decidí compartirlo contigo porque creí que podría gustarte también.',
          ),
          _buildSection(
            title: 'Aviso Legal',
            icon: Ionicons.warning_outline,
            content:
                'MG Music es un proyecto personal de un fan, hecho de forma independiente.\n\nNo tengo relación oficial con Ado ni con su equipo. Esta app respeta todos los derechos de autor y simplemente te ayuda a disfrutar la música local en tu dispositivo.\n\nTodos los nombres, imágenes y referencias relacionadas con Ado pertenecen a sus respectivos dueños. Solo los utilizo con admiración y respeto.',
          ),
          _buildSection(
            title: 'Sobre el Desarrollo',
            icon: Ionicons.code_slash_outline,
            content:
                'Yo solo (Brayan Medrano) desarrollo y mantengo esta app en mis tiempos libres. Es un proyecto que hago porque me apasiona.\n\nNo espero nada a cambio, solo espero que la disfrutes. Si encuentras bugs o tienes ideas, apreciaré tu feedback, pero entiende que actualizaciones pueden tardar por mi tiempo limitado.\n\nNo hay publicidad obligatoria ni cobros. Hice esta app para compartir algo que me gusta, nada más.',
          ),
          const SizedBox(height: 20),
          const Center(
            child: Text(
              'MG Music v1.0.1',
              style: TextStyle(color: Colors.white54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required String content,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade900.withOpacity(0.5),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.blue.shade900.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.blue.shade900, size: 24),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            content,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _InfoPage extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;

  const _InfoPage({
    required this.title,
    required this.content,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(title, style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 80),
            const SizedBox(height: 30),
            SelectableText(
              content,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '(Puedes copiar este texto)',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Logo Interactivo (Adaptado para Móvil) ---

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
    _borderController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
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
    if (_holdTimer != null) return;
    final adoSongs = _audioManager.playlist
        .where((s) => s.artist.toLowerCase().contains('ado'))
        .toList();
    if (adoSongs.isEmpty) return;

    _wobbleController.repeat(reverse: true);
    _holdTimer = Timer(const Duration(milliseconds: 2500), () {
      _resetHold();
      final randomSong = adoSongs[math.Random().nextInt(adoSongs.length)];
      _audioManager.playWithFade(randomSong, _audioManager.playlist);
    });
  }

  void _resetHold() {
    _holdTimer?.cancel();
    _holdTimer = null;
    _wobbleController.stop();
    _wobbleController.reset();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressDown: (_) => _startHold(),
      onLongPressUp: _resetHold,
      onLongPressCancel: _resetHold,
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
                        math.sin(_wobbleController.value * math.pi * 2) * 0.05;
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
          const Text('Versión 1.0.1', style: TextStyle(color: Colors.grey)),
        ],
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
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_LogoBorderPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.glowOpacity != glowOpacity;
}
