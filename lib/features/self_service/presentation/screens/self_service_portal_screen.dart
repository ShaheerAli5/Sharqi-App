import 'package:flutter/material.dart';

import 'self_service_web_screen.dart';

/// Compatibility wrapper for older navigation call sites.
///
/// The native Kotlin application implements Self Service entirely through the
/// backend portal WebView, so this screen intentionally delegates to that same
/// portal rather than maintaining a separate set of local request forms.
class SelfServicePortalScreen extends StatelessWidget {
  const SelfServicePortalScreen({super.key});

  @override
  Widget build(BuildContext context) => const SelfServiceWebScreen();
}
