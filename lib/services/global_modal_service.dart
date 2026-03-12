// Copyright © 2026 Brayan Medrano - MG Music
// Servicio de Modal Global con diseño estilo Ado

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mg_music/services/theme_service.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:ionicons/ionicons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mg_music/TV/tv_focusable_item.dart';

/// Servicio para mostrar modales globales desde cualquier parte de la app
class GlobalModalService {
  // Key global para acceder al contexto de navegación sin necesidad de pasarlo
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Muestra el modal genérico
  static Future<T?> show<T>({
    required String title,
    String? message,
    IconData? icon,
    Widget? content, // Para inputs, listas personalizadas, etc.
    List<Widget>? actions, // Botones
    bool dismissible = true,
    Duration? unlockDelay, // Tiempo de espera para desbloquear botones
    Color? primaryColor,
    FocusNode? initialFocus, // Nodo de foco inicial (TV / teclado)
  }) {
    final context = navigatorKey.currentContext;
    if (context == null) return Future.value(null);

    // Si hay un temporizador de desbloqueo, forzamos a que NO se pueda cerrar tocando afuera
    final isDismissible = unlockDelay != null ? false : dismissible;

    // Usamos showGeneralDialog para personalizar la animación de entrada y SALIDA
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: isDismissible,
      barrierLabel: 'Cerrar',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return _UniversalModal(
          title: title,
          message: message,
          icon: icon,
          content: content,
          actions: actions,
          unlockDelay: unlockDelay,
          dismissible: dismissible,
          primaryColor: primaryColor,
          initialFocus: initialFocus,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        // Curva personalizada: Rebote al entrar (easeOutBack), Suave al salir (easeInBack)
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeInBack,
        );

        return Stack(
          children: [
            // 1. Fondo desenfocado (Fade) - Se anima separado para no escalar el blur
            Positioned.fill(
              child: FadeTransition(
                opacity: animation,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
            // 2. El Modal (Scale + Fade)
            FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: curvedAnimation, child: child),
            ),
          ],
        );
      },
    );
  }

  /// Helper para mostrar una lista seleccionable
  static Future<T?> showList<T>({
    required String title,
    required List<T> items,
    required String Function(T) labelBuilder,
    IconData? icon,
  }) {
    final mode = Provider.of<ThemeService>(
      navigatorKey.currentContext!,
      listen: false,
    ).mode;

    return show<T>(
      title: title,
      icon: icon,
      content: SizedBox(
        height: 200, // Altura controlada para la lista
        child: ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 375),
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryBlueMid.withOpacity(0.3),
                          AppColors.background(mode),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.themeBorder(mode).withOpacity(0.5),
                      ),
                    ),
                    child: ListTile(
                      title: Text(
                        labelBuilder(item),
                        style: TextStyle(color: AppColors.textPrimary(mode)),
                      ),
                      onTap: () => Navigator.of(context).pop(item),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: AppColors.textSecondary(mode),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Muestra un modal de carga (spinner)
  static Future<void> showLoading({
    String message = "Cargando...",
    Color? color,
  }) {
    final mode = Provider.of<ThemeService>(
      navigatorKey.currentContext!,
      listen: false,
    ).mode;

    return show(
      title: "Procesando",
      dismissible: false,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 20),
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              color ?? AppColors.primaryBlueMid,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary(mode)),
          ),
        ],
      ),
      actions: [], // Sin botones
    );
  }

  /// Selector de Assets (Imágenes) con scroll horizontal y estado de selección
  static Future<String?> showAssetPicker({
    required String title,
    required List<String> assets,
    IconData? icon,
  }) {
    // Usamos un ValueNotifier para gestionar la selección localmente
    final ValueNotifier<String?> selectedAssetNotifier = ValueNotifier(null);

    return show<String>(
      title: title,
      icon: icon,
      dismissible: true,
      content: AssetPickerSelector(
        assets: assets,
        selectedNotifier: selectedAssetNotifier,
      ),
      actions: [
        ModalActionButton(
          label: "Cancelar",
          onPressed: () => Navigator.of(navigatorKey.currentContext!).pop(),
          color: Colors.grey.shade600,
        ),
        // El botón de confirmar escucha los cambios en la selección
        ValueListenableBuilder<String?>(
          valueListenable: selectedAssetNotifier,
          builder: (context, selected, _) {
            return ModalActionButton(
              label: "Seleccionar",
              onPressed: selected != null
                  ? () => Navigator.of(context).pop(selected)
                  : null,
              color: AppColors.primaryBlueMid,
              isDisabled: selected == null,
            );
          },
        ),
      ],
    );
  }

  /// Muestra un diálogo de confirmación simple que devuelve un booleano.
  /// Retorna `true` si se confirma, `false` si se cancela o cierra.
  static Future<bool> showConfirmation({
    required String title,
    String? message,
    IconData icon = Ionicons.help_circle_outline,
    String confirmText = 'Confirmar',
    String cancelText = 'Cancelar',
    Color? confirmButtonColor,
  }) async {
    final result = await show<bool>(
      title: title,
      message: message,
      icon: icon,
      actions: [
        ModalActionButton(
          label: cancelText,
          onPressed: () =>
              Navigator.of(navigatorKey.currentContext!).pop(false),
          color: Colors.grey.shade600,
        ),
        ModalActionButton(
          label: confirmText,
          onPressed: () => Navigator.of(navigatorKey.currentContext!).pop(true),
          color: confirmButtonColor ?? AppColors.primaryBlueMid,
        ),
      ],
    );

    // Si el usuario cierra el diálogo tocando fuera (dismiss), el resultado es null.
    // Lo tratamos como una cancelación (false).
    return result ?? false;
  }

  /// Muestra una lista de selección vertical optimizada
  /// - [selectedItem]: Elemento actualmente seleccionado para resaltarlo
  /// - Sin botones de acción (se cierra al seleccionar)
  /// - Altura adaptable (shrinkWrap)
  static Future<T?> showSelectionList<T>({
    required String title,
    required List<T> items,
    required String Function(T) labelBuilder,
    T? selectedItem,
    IconData? icon,
  }) {
    final mode = Provider.of<ThemeService>(
      navigatorKey.currentContext!,
      listen: false,
    ).mode;

    return show<T>(
      title: title,
      icon: icon,
      actions: [], // Pasamos lista vacía para indicar "sin botones"
      content: ListView.builder(
        shrinkWrap: true,
        physics:
            const NeverScrollableScrollPhysics(), // El scroll lo maneja el modal
        itemCount: items.length,
        padding: EdgeInsets.zero,
        itemBuilder: (context, index) {
          final item = items[index];
          final isSelected = item == selectedItem;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () =>
                    Navigator.of(navigatorKey.currentContext!).pop(item),
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryBlueMid.withOpacity(0.4)
                        : AppColors.background(mode).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.themeBorder(mode)
                          : Colors.transparent,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          labelBuilder(item),
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.textPrimary(mode)
                                : AppColors.textSecondary(mode),
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: AppColors.primaryBlueMid,
                          size: 18,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Muestra un modal con tres rodillos deslizantes (horas, minutos, segundos)
  /// al estilo alarma. Devuelve la [Duration] elegida o null si cancela.
  ///
  /// Uso:
  /// ```dart
  /// final d = await GlobalModalService.showDurationPicker(title: 'Tiempo');
  /// if (d != null) doSomething(d);
  /// ```
  static Future<Duration?> showDurationPicker({
    required String title,
    Duration initialValue = const Duration(minutes: 30),
    IconData icon = Ionicons.timer_outline,
  }) {
    int selH = initialValue.inHours.clamp(0, 23);
    int selM = initialValue.inMinutes.remainder(60).clamp(0, 59);
    int selS = initialValue.inSeconds.remainder(60).clamp(0, 59);

    final hCtrl = FixedExtentScrollController(initialItem: selH);
    final mCtrl = FixedExtentScrollController(initialItem: selM);
    final sCtrl = FixedExtentScrollController(initialItem: selS);

    return show<Duration>(
      title: title,
      icon: icon,
      dismissible: true,
      content: _DurationPickerContent(
        hCtrl: hCtrl,
        mCtrl: mCtrl,
        sCtrl: sCtrl,
        onChanged: (h, m, s) {
          selH = h;
          selM = m;
          selS = s;
        },
      ),
      actions: [
        ModalActionButton(
          label: 'Cancelar',
          color: Colors.grey.shade600,
          onPressed: () => Navigator.of(navigatorKey.currentContext!).pop(),
        ),
        ModalActionButton(
          label: 'Aplicar',
          color: AppColors.primaryBlueMid,
          onPressed: () {
            final result = Duration(hours: selH, minutes: selM, seconds: selS);
            Navigator.of(navigatorKey.currentContext!).pop(result);
          },
        ),
      ],
    );
  }

  /// Muestra un modal de error de reproducción con opción de reportar vía WhatsApp.
  ///
  /// - [error]: El objeto de error o excepción capturado.
  /// - [errorCode]: Código corto identificador del error (ej: "AUDIO_001").
  static Future<void> showAudioError({
    required Object error,
    String errorCode = 'AUDIO_ERR',
  }) async {
    final errorDescription = error.toString();

    // 1. Modal principal de error
    await show(
      title: 'Error de Reproducción',
      icon: Ionicons.musical_note,
      primaryColor: Colors.redAccent.shade700,
      message:
          'Ha ocurrido un error. Inténtalo nuevamente. Si el error persiste, da click en reportar.',
      actions: [
        ModalActionButton(
          label: 'Cerrar',
          onPressed: () => Navigator.of(navigatorKey.currentContext!).pop(),
          color: Colors.grey.shade700,
        ),
        ModalActionButton(
          label: 'Reportar',
          onPressed: () async {
            Navigator.of(navigatorKey.currentContext!).pop();
            await _showReportConfirmation(
              errorCode: errorCode,
              errorDescription: errorDescription,
            );
          },
          color: Colors.green.shade700,
        ),
      ],
    );
  }

  /// Solicita confirmación antes de abrir WhatsApp con el reporte
  static Future<void> _showReportConfirmation({
    required String errorCode,
    required String errorDescription,
  }) async {
    await show(
      title: 'Reportar al Desarrollador',
      icon: Ionicons.logo_whatsapp,
      primaryColor: Colors.green.shade700,
      message:
          'Se abrirá WhatsApp con el reporte de este error.\n\n'
          '⚠️ Por favor, solo da click en enviar y no modifiques el mensaje para que el error adjunto automáticamente sea el correcto.',
      actions: [
        ModalActionButton(
          label: 'Cancelar',
          onPressed: () => Navigator.of(navigatorKey.currentContext!).pop(),
          color: Colors.grey.shade700,
        ),
        ModalActionButton(
          label: 'Reportar',
          onPressed: () async {
            Navigator.of(navigatorKey.currentContext!).pop();
            await _sendErrorViaWhatsApp(
              errorCode: errorCode,
              errorDescription: errorDescription,
            );
          },
          color: Colors.green.shade700,
        ),
      ],
    );
  }

  /// Construye el mensaje y abre WhatsApp
  static Future<void> _sendErrorViaWhatsApp({
    required String errorCode,
    required String errorDescription,
  }) async {
    final message =
        '🚨 Reporte de Error — MG Music\n'
        '─────────────────────────\n'
        'Código: $errorCode\n'
        'Descripción: $errorDescription';

    final url = Uri.parse(
      'https://wa.me/573168060939?text=${Uri.encodeComponent(message)}',
    );
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }
}

/// Widget interno que renderiza el diseño del modal
class _UniversalModal extends StatefulWidget {
  final String title;
  final String? message;
  final IconData? icon;
  final Widget? content;
  final List<Widget>? actions;
  final Duration? unlockDelay;
  final bool dismissible;
  final Color? primaryColor;
  final FocusNode? initialFocus;

  const _UniversalModal({
    required this.title,
    this.message,
    this.icon,
    this.content,
    this.actions,
    this.unlockDelay,
    this.dismissible = true,
    this.primaryColor,
    this.initialFocus,
  });

  @override
  State<_UniversalModal> createState() => _UniversalModalState();
}

class _UniversalModalState extends State<_UniversalModal> {
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _isLocked = false;

  @override
  /// Inicializa temporizador de bloqueo y foco inicial
  void initState() {
    super.initState();
    if (widget.unlockDelay != null) {
      _isLocked = true;
      _remainingSeconds = widget.unlockDelay!.inSeconds;
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _remainingSeconds--;
            if (_remainingSeconds <= 0) {
              _isLocked = false;
              _timer?.cancel();
            }
          });
        }
      });
    }
    if (widget.initialFocus != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.initialFocus!.requestFocus();
        }
      });
    }
  }

  @override
  /// Libera temporizador
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  /// Construye el modal universal con animaciones y acciones
  Widget build(BuildContext context) {
    final mode = context.watch<ThemeService>().mode;
    final size = MediaQuery.of(context).size;
    final primaryColor = widget.primaryColor ?? AppColors.primaryBlueMid;
    final verticalMargin = size.height * 0.20;

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: () {
          if (widget.dismissible && !_isLocked) {
            Navigator.of(context).pop();
          }
        },
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              margin: EdgeInsets.symmetric(
                vertical: verticalMargin,
                horizontal: 20,
              ),
              constraints: BoxConstraints(
                maxHeight: size.height * 0.6,
                maxWidth: 500,
              ),
              decoration: BoxDecoration(
                color: AppColors.background(mode),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: primaryColor, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primaryColor.withOpacity(0.3),
                    AppColors.background(mode),
                  ],
                  stops: const [0.0, 0.7],
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: AnimationLimiter(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: AnimationConfiguration.toStaggeredList(
                        duration: const Duration(milliseconds: 500),
                        delay: const Duration(milliseconds: 100),
                        childAnimationBuilder: (widget) => SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(child: widget),
                        ),
                        children: [
                          // 1. Icono Principal
                          if (widget.icon != null) ...[
                            Icon(widget.icon, size: 48, color: primaryColor),
                            const SizedBox(height: 16),
                          ],

                          Text(
                            widget.title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textPrimary(mode),
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 16),

                          if (widget.message != null) ...[
                            Text(
                              widget.message!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textSecondary(mode),
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],

                          if (widget.content != null) ...[
                            widget.content!,
                            const SizedBox(height: 20),
                          ],

                          if (widget.actions != null) ...[
                            if (widget.actions!.isNotEmpty)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (_isLocked)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 15),
                                      child: Text(
                                        "Espere $_remainingSeconds s...",
                                        style: TextStyle(
                                          color: AppColors.primaryBlueMid,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ...widget.actions!.map((action) {
                                    return IgnorePointer(
                                      ignoring: _isLocked,
                                      child: Opacity(
                                        opacity: _isLocked ? 0.5 : 1.0,
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            left: 10,
                                          ),
                                          child: action,
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                          ] else ...[
                            Center(
                              child: ModalActionButton(
                                label: _isLocked
                                    ? "$_remainingSeconds"
                                    : "Cerrar",
                                onPressed: () => Navigator.pop(context),
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Botón estandarizado para los modales con estilo degradado
class ModalActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final bool isDisabled;
  final FocusNode? focusNode;

  const ModalActionButton({
    required this.label,
    required this.onPressed,
    required this.color,
    this.isDisabled = false,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final mode = context.watch<ThemeService>().mode;
    final effectiveColor = isDisabled ? AppColors.themeBorder(mode) : color;
    final effectiveTextColor = isDisabled
        ? AppColors.textSecondary(mode)
        : Colors.white;

    return TvFocusableItem(
      focusNode: focusNode,
      onTap: isDisabled ? null : onPressed,
      borderRadius: 30,
      selectedColor: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [effectiveColor, AppColors.background(mode)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: effectiveColor),
          boxShadow: [
            BoxShadow(
              color: effectiveColor.withOpacity(0.5),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Text(
            label,
            style: TextStyle(
              color: effectiveTextColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget reutilizable para el selector de assets (Público para usar en modales combinados)
class AssetPickerSelector extends StatefulWidget {
  final List<String> assets;
  final ValueNotifier<String?> selectedNotifier;

  const AssetPickerSelector({
    super.key,
    required this.assets,
    required this.selectedNotifier,
  });

  @override
  State<AssetPickerSelector> createState() => _AssetPickerSelectorState();
}

class _AssetPickerSelectorState extends State<AssetPickerSelector> {
  String? _selectedAsset;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140, // Altura suficiente para imagen + borde
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.assets.length,
        itemBuilder: (context, index) {
          final asset = widget.assets[index];
          final isSelected = _selectedAsset == asset;

          return TvFocusableItem(
            onTap: () {
              setState(() => _selectedAsset = asset);
              widget.selectedNotifier.value = asset;
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 15, top: 5, bottom: 5),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.blue.shade900.withOpacity(0.3)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: isSelected ? Colors.cyanAccent : Colors.transparent,
                  width: 2,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.cyanAccent.withOpacity(0.3),
                          blurRadius: 10,
                        ),
                      ]
                    : [],
              ),
              child: Image.asset(asset, fit: BoxFit.contain),
            ),
          );
        },
      ),
    );
  }
}

/// Widget interno para showDurationPicker — tres rodillos tipo alarma
class _DurationPickerContent extends StatefulWidget {
  final FixedExtentScrollController hCtrl;
  final FixedExtentScrollController mCtrl;
  final FixedExtentScrollController sCtrl;
  final void Function(int h, int m, int s) onChanged;

  const _DurationPickerContent({
    required this.hCtrl,
    required this.mCtrl,
    required this.sCtrl,
    required this.onChanged,
  });

  @override
  State<_DurationPickerContent> createState() => _DurationPickerContentState();
}

class _DurationPickerContentState extends State<_DurationPickerContent> {
  int _h = 0;
  int _m = 30;
  int _s = 0;

  @override
  void initState() {
    super.initState();
    _h = widget.hCtrl.initialItem;
    _m = widget.mCtrl.initialItem;
    _s = widget.sCtrl.initialItem;
  }

  void _notify() => widget.onChanged(_h, _m, _s);

  Widget _buildWheel({
    required FixedExtentScrollController ctrl,
    required int itemCount,
    required String label,
    required void Function(int) onSelected,
  }) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.blue.shade300,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 150,
            child: ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black,
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black,
                ],
                stops: const [0.0, 0.25, 0.75, 1.0],
              ).createShader(bounds),
              blendMode: BlendMode.dstOut,
              child: ListWheelScrollView.useDelegate(
                controller: ctrl,
                itemExtent: 40,
                perspective: 0.003,
                diameterRatio: 1.4,
                physics: const FixedExtentScrollPhysics(),
                onSelectedItemChanged: (i) {
                  onSelected(i);
                  _notify();
                },
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: itemCount,
                  builder: (context, index) {
                    final isSelected =
                        ctrl.hasClients && ctrl.selectedItem == index;
                    return Center(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 150),
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white30,
                          fontSize: isSelected ? 28 : 20,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        child: Text(index.toString().padLeft(2, '0')),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade900.withOpacity(0.4)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        children: [
          _buildWheel(
            ctrl: widget.hCtrl,
            itemCount: 24,
            label: 'HORAS',
            onSelected: (v) => _h = v,
          ),
          _buildSeparator(),
          _buildWheel(
            ctrl: widget.mCtrl,
            itemCount: 60,
            label: 'MINUTOS',
            onSelected: (v) => _m = v,
          ),
          _buildSeparator(),
          _buildWheel(
            ctrl: widget.sCtrl,
            itemCount: 60,
            label: 'SEGS',
            onSelected: (v) => _s = v,
          ),
        ],
      ),
    );
  }

  Widget _buildSeparator() => Padding(
    padding: const EdgeInsets.only(top: 26),
    child: Text(
      ':',
      style: TextStyle(
        color: Colors.blue.shade300,
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}
