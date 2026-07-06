import 'package:flutter/material.dart';
import 'package:techno_switch_solar_app/features/help/controllers/help_screen_ui_delegate.dart';
import 'package:url_launcher/url_launcher.dart';

mixin HelpUiDelegateMixin<T extends StatefulWidget> on State<T>
    implements HelpScreenUiDelegate {
  @override
  bool get isMounted => mounted;

  @override
  Future<void> launchPhone(String phoneNumber) async {
    final uri = Uri.parse(
      'tel:${phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '')}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Future<void> launchEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Future<void> launchExternalUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
