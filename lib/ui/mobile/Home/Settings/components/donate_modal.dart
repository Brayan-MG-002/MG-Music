import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ionicons/ionicons.dart';
import 'package:provider/provider.dart';
import 'package:mg_music/services/ui/bottom_modal_service.dart';
import 'package:mg_music/services/ui/custom_toast_service.dart';
import 'package:mg_music/services/ui/theme_service.dart';

class DonateModal extends StatelessWidget {
  const DonateModal({super.key});

  /// Abre el modal de donación con imagen, número y acción de copiar
  static void show(BuildContext context) {
    final mode = Provider.of<ThemeService>(context, listen: false).mode;

    BottomModalService.show(
      context,
      title: 'Apoya el Proyecto',
      subtitle: 'Tu apoyo es voluntario y muy valorado',

      heroContent: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(10),
        child: Image.asset('assets/MG Studios/MG-D.png'),
      ),

      child: SelectableText(
        '316 806 0939',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.textPrimary(mode),
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),

      options: [
        BottomModalOption(
          icon: Ionicons.copy_outline,
          label: 'Copiar Número',
          onTap: () {
            Clipboard.setData(const ClipboardData(text: '3168060939'));
            CustomToastService.show(
              context,
              message: 'Número copiado al portapapeles',
              type: ToastType.success,
            );
          },
        ),
      ],

      footerText:
          'Tu donación vía Nequi es totalmente opcional, pero me ayudas mucho a continuar con el desarrollo de la app. ¡Gracias por tu apoyo!',
    );
  }

  @override
  /// Contenido vacío (controlado por el modal)
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
