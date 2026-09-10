import 'package:flutter/material.dart';
import 'self_service_portal_screen.dart';

class SelfServiceWebScreen extends StatelessWidget {
  final String? initialUrl;

  const SelfServiceWebScreen({
    super.key,
    this.initialUrl,
  });

  @override
  Widget build(BuildContext context) {
    return const SelfServicePortalScreen();
  }
}
