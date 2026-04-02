import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ionicons/ionicons.dart';
import 'package:provider/provider.dart';
import 'package:mg_music/services/ui/bottom_modal_service.dart';
import 'package:mg_music/services/ui/theme_service.dart';
import 'package:mg_music/services/ui/responsive_service.dart';
import 'link_dialog.dart';

class DonateModal extends StatelessWidget {
  const DonateModal({super.key});

  static void show(BuildContext context) {
    final mode = Provider.of<ThemeService>(context, listen: false).mode;

    BottomModalService.show(
      context,
      title: 'Apoya el Proyecto',
      subtitle: 'Tu apoyo es voluntario y muy valorado',

      heroContent: Container(
        width: 140.r,
        height: 140.r,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15.r),
        ),
        padding: EdgeInsets.all(8.r),
        child: Image.asset('assets/MG Studios/MG-D.png'),
      ),

      child: SelectableText(
        'PayPal',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.textPrimary(mode),
          fontSize: 18.sp,
          fontWeight: FontWeight.bold,
        ),
      ),

      options: [
        BottomModalOption(
          icon: Ionicons.logo_paypal,
          label: 'Donar en PayPal',
          onTap: () {
            Navigator.pop(context);
            LinkDialog.launchExternalUrl('https://www.paypal.com/donate/?hosted_button_id=Y36JD745Z49UN');
          },
        ),
      ],

      footerText: 'Tu donación vía PayPal es totalmente opcional, pero me ayudas mucho a continuar con el desarrollo de la app. ¡Gracias por tu apoyo!',
    );
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
