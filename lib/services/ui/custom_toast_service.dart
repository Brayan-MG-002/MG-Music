// Copyright © 2026 Brayan Medrano - MG Music
// Servicio de Alertas Personalizadas (Toast) con estilo Neon/Ado

import 'dart:async';
import 'dart:collection';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:mg_music/services/ui/global_modal_service.dart';

/// Tipos de alerta para determinar colores e iconos
enum ToastType { info, success, error, warning, ado }

/// Servicio global para mostrar alertas tipo "Toast"
class CustomToastService {
  static final Queue<_ToastRequest> _queue = Queue<_ToastRequest>();

  static final List<_ToastEntry> _activeToasts = [];

  static const int _maxVisibleToasts = 2;

  /// Muestra una alerta personalizada
  static void show(
    BuildContext context, {
    required String message,
    ToastType type = ToastType.ado,
    IconData? icon,
    Duration duration = const Duration(seconds: 3),
  }) {
    final request = _ToastRequest(
      message: message,
      type: type,
      icon: icon ?? _getDefaultIcon(type),
      duration: duration,
      color: _getColor(type),
    );

    _queue.add(request);
    _processQueue();
  }

  /// Procesa la cola y muestra alertas si hay espacio
  static void _processQueue() {
    if (_queue.isEmpty) return;

    if (_activeToasts.length >= _maxVisibleToasts) {
      return;
    }

    final request = _queue.removeFirst();
    _showToast(request);
  }

  /// Construye e inserta la alerta en el overlay
  static void _showToast(_ToastRequest request) {
    final overlayState = GlobalModalService.navigatorKey.currentState?.overlay;

    if (overlayState == null) return;

    late OverlayEntry overlayEntry;
    late _ToastEntry toastEntry;

    overlayEntry = OverlayEntry(
      builder: (context) {
        final index = _activeToasts.indexOf(toastEntry);
        final safeIndex = index >= 0 ? index : 0;

        return _ToastWidget(
          request: request,
          index: safeIndex,
          onDismissed: () {
            _removeToast(toastEntry);
          },
        );
      },
    );

    toastEntry = _ToastEntry(overlayEntry: overlayEntry, request: request);
    _activeToasts.add(toastEntry);

    overlayState.insert(overlayEntry);

    if (_activeToasts.length < _maxVisibleToasts && _queue.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 300), _processQueue);
    }
  }

  /// Elimina una alerta de la lista activa y del overlay
  static void _removeToast(_ToastEntry entry) {
    if (_activeToasts.contains(entry)) {
      entry.overlayEntry.remove();
      _activeToasts.remove(entry);

      for (var toast in _activeToasts) {
        toast.overlayEntry.markNeedsBuild();
      }

      _processQueue();
    }
  }

  // Helpers de estilo
  static IconData _getDefaultIcon(ToastType type) {
    switch (type) {
      case ToastType.success:
        return Ionicons.checkmark_circle;
      case ToastType.error:
        return Ionicons.alert_circle;
      case ToastType.warning:
        return Ionicons.warning;
      case ToastType.info:
        return Ionicons.information_circle;
      case ToastType.ado:
        return Ionicons.musical_notes;
    }
  }

  static Color _getColor(ToastType type) {
    switch (type) {
      case ToastType.success:
        return Colors.greenAccent;
      case ToastType.error:
        return Colors.redAccent;
      case ToastType.warning:
        return Colors.orangeAccent;
      case ToastType.info:
        return Colors.grey.shade300;
      case ToastType.ado:
        return Colors.blue.shade900; // Azul Ado
    }
  }
}

/// Modelo de datos para una solicitud de Toast
class _ToastRequest {
  final String message;
  final ToastType type;
  final IconData icon;
  final Duration duration;
  final Color color;

  _ToastRequest({
    required this.message,
    required this.type,
    required this.icon,
    required this.duration,
    required this.color,
  });
}

/// Referencia a una alerta activa
class _ToastEntry {
  final OverlayEntry overlayEntry;
  final _ToastRequest request;

  _ToastEntry({required this.overlayEntry, required this.request});
}

/// Widget visual de la alerta con animaciones
class _ToastWidget extends StatefulWidget {
  final _ToastRequest request;
  final int index; // 0 es el de más abajo, 1 el de arriba
  final VoidCallback onDismissed;

  const _ToastWidget({
    Key? key,
    required this.request,
    required this.index,
    required this.onDismissed,
  }) : super(key: key);

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  Timer? _timer;

  final double _baseBottomPadding = 80.0;
  final double _itemHeightWithPadding = 85.0;

  @override
  /// Inicializa animaciones y temporizador de cierre
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      reverseDuration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );

    _slideAnimation =
        Tween<Offset>(
          begin: const Offset(0, 1.0), // Empieza más abajo
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Curves.easeOutCubic, // Efecto suave y elástico
            reverseCurve: Curves.easeInCubic,
          ),
        );

    _controller.forward();

    _timer = Timer(widget.request.duration, () {
      _close();
    });
  }

  /// Cierra la alerta con animación
  Future<void> _close() async {
    if (!mounted) return;
    await _controller.reverse();
    if (mounted) {
      widget.onDismissed();
    }
  }

  @override
  /// Libera recursos
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  /// Construye la posición y transiciones de la alerta
  Widget build(BuildContext context) {
    final bottomPosition =
        _baseBottomPadding + (widget.index * _itemHeightWithPadding);

    return Positioned(
      bottom: bottomPosition,
      left: 20,
      right: 20,
      child: Material(
        color: Colors.transparent,
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Center(
              child: ExcludeFocus(
                child: Dismissible(
                  key: UniqueKey(),
                  direction: DismissDirection.horizontal,
                  onDismissed: (_) {
                    _timer
                        ?.cancel(); // Cancelar timer si se desliza manualmente
                    widget.onDismissed();
                  },
                  child: _buildContent(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Construye el contenido visual del toast
  Widget _buildContent() {
    final color = widget.request.color;

    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [color.withOpacity(0.15), Colors.black.withOpacity(0.8)],
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: color.withOpacity(0.6),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 15,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.request.icon, color: color, size: 24),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  widget.request.message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
