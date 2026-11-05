import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../application/update_controller.dart';
import 'update_dialog.dart';
import 'whats_new_sheet.dart';

/// Runs the update check after the app shell appears and on resume, shows the
/// update popup when one is available, and the one-time "What's new" sheet.
class UpdateListener extends ConsumerStatefulWidget {
  const UpdateListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<UpdateListener> createState() => _UpdateListenerState();
}

class _UpdateListenerState extends ConsumerState<UpdateListener> {
  late final AppLifecycleListener _lifecycle;
  bool _dialogOpen = false;

  bool get _updatesConfigured {
    final config = ref.read(appConfigProvider);
    return config.apiBaseUrl != null || config.releasesRepo != null;
  }

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: () {
      if (_updatesConfigured) ref.read(updateControllerProvider.notifier).onResumed();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _afterFirstFrame());
  }

  Future<void> _afterFirstFrame() async {
    if (!mounted) return;
    final controller = ref.read(updateControllerProvider.notifier);
    final justInstalled = controller.consumeJustUpdatedRelease();
    if (justInstalled != null) await showWhatsNewSheet(context, justInstalled);
    if (mounted && _updatesConfigured) await controller.check(UpdateTrigger.launch);
  }

  Future<void> _openDialog() async {
    _dialogOpen = true;
    await showUpdateDialog(context);
    _dialogOpen = false;
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(updateControllerProvider, (previous, next) {
      if (next is UpdateAvailable && !_dialogOpen) _openDialog();
    });
    return widget.child;
  }
}
