// Copyright © 2026 Brayan Medrano - MG Music
// Servicio centralizado para la gestión de diálogos y modales en toda la aplicación, con una estética premium inspirada en Ado y soporte para navegación remota/TV.

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ionicons/ionicons.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:mg_music/ui/tv/tv_focusable_item.dart';
import 'package:mg_music/services/audio/audio_player_manager.dart';
import 'package:mg_music/services/ui/custom_toast_service.dart';
import 'package:mg_music/services/ui/responsive_service.dart';
import 'package:mg_music/services/ui/theme_service.dart';

class GlobalModalService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static Future<T?> show<T>({
    required String title,
    String? message,
    IconData? icon,
    Widget? content,
    List<Widget>? actions,
    bool dismissible = true,
    Duration? unlockDelay,
    Color? primaryColor,
    FocusNode? initialFocus,
  }) {
    final context = navigatorKey.currentContext;
    if (context == null) return Future.value(null);

    final isDismissible = unlockDelay != null ? false : dismissible;

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
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeInBack,
        );

        return Stack(
          children: [
            Positioned.fill(
              child: FadeTransition(
                opacity: animation,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
            FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: curvedAnimation, child: child),
            ),
          ],
        );
      },
    );
  }

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
        height: 200.h,
        child: ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 375),
              child: SlideAnimation(
                verticalOffset: 50.0.h,
                child: FadeInAnimation(
                  child: Container(
                    margin: EdgeInsets.only(bottom: 10.h),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryBlueMid.withOpacity(0.3),
                          AppColors.background(mode),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: AppColors.themeBorder(mode).withOpacity(0.5),
                      ),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 0),
                      visualDensity: VisualDensity.compact,
                      title: Text(
                        labelBuilder(item),
                        style: TextStyle(color: AppColors.textPrimary(mode), fontSize: 13.sp),
                      ),
                      onTap: () => Navigator.of(context).pop(item),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        size: 11.r,
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
            strokeWidth: 3.w,
            valueColor: AlwaysStoppedAnimation<Color>(
              color ?? AppColors.primaryBlueMid,
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary(mode),
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
      actions: [],
    );
  }

  static Future<String?> showAssetPicker({
    required String title,
    required List<String> assets,
    IconData? icon,
  }) {
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

    return result ?? false;
  }

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
      actions: [],
      content: Container(
        constraints: BoxConstraints(maxHeight: 350.h),
        child: ListView.builder(
          shrinkWrap: true,
          physics: const BouncingScrollPhysics(),
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
                borderRadius: BorderRadius.circular(10.r),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryBlueMid.withOpacity(0.4)
                        : AppColors.background(mode).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.themeBorder(mode)
                          : Colors.transparent,
                      width: 1.w,
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
                            fontSize: 13.sp,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: AppColors.primaryBlueMid,
                          size: 14.r,
                        ),
                    ],
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

  static void showSleepTimerDialog(BuildContext context) {
    final mode = Provider.of<ThemeService>(context, listen: false).mode;
    final options = [
      ('Al terminar canción', -1, Ionicons.musical_note_outline),
      ('5 Minutos', 5, Ionicons.time_outline),
      ('10 Minutos', 10, Ionicons.time_outline),
      ('15 Minutos', 15, Ionicons.time_outline),
      ('30 Minutos', 30, Ionicons.time_outline),
      ('45 Minutos', 45, Ionicons.time_outline),
      ('60 Minutos', 60, Ionicons.time_outline),
      ('Desactivar', 0, Ionicons.close_circle_outline),
    ];

    show(
      title: 'Temporizador de Apagado',
      icon: Ionicons.timer_outline,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: options.map((opt) {
          final isDelete = opt.$2 == 0;
          final isEndSong = opt.$2 == -1;

          return Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: TvFocusableItem(
              onTap: () {
                if (isEndSong) {
                  AudioPlayerManager().setSleepAtEndOfSong();
                } else {
                  AudioPlayerManager().setSleepTimer(opt.$2);
                }
                Navigator.pop(context);

                String msg = isDelete
                    ? 'Temporizador desactivado'
                    : (isEndSong
                        ? 'Se pausará al terminar la canción'
                        : 'Apagado en ${opt.$1}');

                CustomToastService.show(
                  context,
                  message: msg,
                  type: isDelete ? ToastType.warning : ToastType.ado,
                  icon: opt.$3,
                );
              },
              borderRadius: 12.r,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                child: Row(
                  children: [
                    Icon(
                      opt.$3,
                      color:
                          isDelete ? Colors.redAccent : AppColors.primaryBlueMid,
                      size: 22.r,
                    ),
                    SizedBox(width: 16.w),
                    Text(
                      opt.$1,
                      style: TextStyle(
                        color:
                            isDelete
                                ? Colors.redAccent
                                : AppColors.textPrimary(mode),
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
      actions: [
        ModalActionButton(
          label: 'Cerrar',
          onPressed: () => Navigator.pop(context),
          color: Colors.grey,
        ),
      ],
    );
  }
}

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
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
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
                  horizontal: 20.w,
                ),
                constraints: BoxConstraints(
                  maxHeight: size.height * 0.7,
                  maxWidth: 500.w,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background(mode),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: primaryColor, width: 1.2.w),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.4),
                      blurRadius: 15.r,
                      spreadRadius: 1.r,
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
                borderRadius: BorderRadius.circular(20.r),
                child: AnimationLimiter(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(16.r),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: AnimationConfiguration.toStaggeredList(
                        duration: const Duration(milliseconds: 500),
                        delay: const Duration(milliseconds: 100),
                        childAnimationBuilder: (widget) => SlideAnimation(
                          verticalOffset: 50.0.h,
                          child: FadeInAnimation(child: widget),
                        ),
                        children: [
                          if (widget.icon != null) ...[
                            Icon(widget.icon, size: 28.r, color: primaryColor),
                            SizedBox(height: 10.h),
                          ],

                          Text(
                            widget.title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textPrimary(mode),
                              fontSize: MediaQuery.of(context).size.height < 700 ? 16.sp : 18.sp,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 10.h),

                          if (widget.message != null) ...[
                            Text(
                              widget.message!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textSecondary(mode),
                                fontSize: 14.sp,
                              ),
                            ),
                            SizedBox(height: 12.h),
                          ],

                          if (widget.content != null) ...[
                            DefaultTextStyle(
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: AppColors.textSecondary(mode),
                                fontFamily: 'CircularStd',
                              ),
                              child: widget.content!,
                            ),
                            SizedBox(height: 12.h),
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
      borderRadius: 30.r,
      selectedColor: Colors.transparent,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 2.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [effectiveColor, AppColors.background(mode)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(30.r),
          border: Border.all(color: effectiveColor, width: 1.w),
          boxShadow: [
            BoxShadow(
              color: effectiveColor.withOpacity(0.5),
              blurRadius: 10.r,
              spreadRadius: 1.r,
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Text(
            label,
            style: TextStyle(
              color: effectiveTextColor,
              fontWeight: FontWeight.bold,
              fontSize: 13.sp,
            ),
          ),
        ),
      ),
    );
  }
}

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
      height: 120.h,
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
              margin: EdgeInsets.only(right: 12.w, top: 4.h, bottom: 4.h),
              padding: EdgeInsets.all(6.r),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.blue.shade900.withOpacity(0.3)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(15.r),
                border: Border.all(
                  color: isSelected ? Colors.cyanAccent : Colors.transparent,
                  width: 2.w,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.cyanAccent.withOpacity(0.3),
                          blurRadius: 10.r,
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
