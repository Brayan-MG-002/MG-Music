import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mg_music/services/ui/global_modal_service.dart';
import 'package:mg_music/services/ui/theme_service.dart';
import 'package:url_launcher/url_launcher.dart';

class LinkDialog {

  static Future<void> show({
    required BuildContext context,
    required String title,
    required IconData icon,
    required String content,
    required String url,
  }) async {
    final navContext = GlobalModalService.navigatorKey.currentContext!;
    final mode = Provider.of<ThemeService>(navContext, listen: false).mode;

    return GlobalModalService.show(
      title: title,
      message: content,
      icon: icon,
      actions: [
        ModalActionButton(
          label: 'Cancelar',
          onPressed: () => Navigator.of(navContext).pop(),
          color: AppColors.textSecondary(mode),
        ),
        ModalActionButton(
          label: 'Continuar',
          onPressed: () {
            Navigator.of(navContext).pop();
            launchExternalUrl(url);
          },
          color: AppColors.primaryBlueMid,
        ),
      ],
    );
  }


  static Future<void> launchExternalUrl(String urlString) async {
    final Uri uri = Uri.parse(urlString);
    try {
      await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    } catch (_) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        try {
          await launchUrl(uri, mode: LaunchMode.platformDefault);
        } catch (_) {
          try {
            await launchUrl(uri);
          } catch (_) {}
        }
      }
    }
  }
}
