import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/anuvaad_colors.dart';
import '../../../core/config/app_config.dart';
import '../../../l10n/app_localizations.dart';
import '../application/update_controller.dart';
import '../domain/update_decision.dart';
import 'release_notes_view.dart';

/// Shows the update popup; it follows the controller through download and install.
Future<void> showUpdateDialog(BuildContext context) =>
    showDialog<void>(context: context, barrierDismissible: false, builder: (_) => const UpdateDialog());

class UpdateDialog extends ConsumerStatefulWidget {
  const UpdateDialog({super.key});

  @override
  ConsumerState<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends ConsumerState<UpdateDialog> {
  UpdateDecision? _decision;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = Theme.of(context).extension<AnuvaadColors>()!;
    final state = ref.watch(updateControllerProvider);
    final controller = ref.read(updateControllerProvider.notifier);
    final decision = _decision = decisionOf(state) ?? _decision;
    if (decision == null) return const SizedBox.shrink();

    final release = decision.release!;
    final mandatory = decision.kind == UpdateKind.mandatory;
    final closable = !mandatory &&
        (state is UpdateAvailable || state is UpdateFailed || state is UpdateNeedsPermission || state is UpdateInstallNotCompleted);
    void close() {
      controller.later();
      Navigator.of(context).pop();
    }

    final website = ref.watch(appConfigProvider).apiBaseUrl;
    final subtitle = Text(
      l10n.updateSubtitle(release.version, formatReleaseDate(context, release.publishedAt), formatMegabytes(decision.asset!.size)),
      style: TextStyle(color: tokens.muted),
    );

    final (String title, List<Widget> content, List<Widget> actions) = switch (state) {
      UpdateAvailable() => (
          l10n.updateAvailableTitle,
          [
            subtitle,
            ReleaseNotesView(notes: release.notes),
            if (mandatory)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(l10n.updateMandatory, style: TextStyle(fontWeight: FontWeight.w700, color: tokens.ink)),
              ),
          ],
          [
            if (!mandatory) TextButton(onPressed: close, child: Text(l10n.updateLater)),
            FilledButton(onPressed: controller.startUpdate, child: Text(l10n.updateNow)),
          ],
        ),
      UpdateDownloading(:final received, :final total) => (
          l10n.updateAvailableTitle,
          [
            subtitle,
            const SizedBox(height: 16),
            LinearProgressIndicator(value: total > 0 ? (received / total).clamp(0.0, 1.0) : null),
            const SizedBox(height: 8),
            Text(l10n.updateDownloading(total > 0 ? (received * 100 / total).round().clamp(0, 100) : 0)),
          ],
          const <Widget>[],
        ),
      UpdateVerifying() => (l10n.updateAvailableTitle, [subtitle, const SizedBox(height: 16), const LinearProgressIndicator(), const SizedBox(height: 8), Text(l10n.updateVerifying)], const <Widget>[]),
      UpdateInstalling() => (l10n.updateAvailableTitle, [subtitle, const SizedBox(height: 16), Text(l10n.updateInstalling)], const <Widget>[]),
      UpdateNeedsPermission() => (
          l10n.updatePermissionTitle,
          [Text(l10n.updatePermissionBody, style: TextStyle(color: tokens.ink, height: 1.4))],
          [
            if (!mandatory) TextButton(onPressed: close, child: Text(l10n.updateLater)),
            FilledButton(onPressed: controller.grantPermissionAndContinue, child: Text(l10n.updateOpenSettings)),
          ],
        ),
      UpdateFailed(:final failure) => (
          l10n.updateAvailableTitle,
          [Text(_failureMessage(l10n, failure), style: TextStyle(color: tokens.ink, height: 1.4))],
          [
            if (!mandatory) TextButton(onPressed: close, child: Text(l10n.updateClose)),
            FilledButton(onPressed: controller.startUpdate, child: Text(l10n.tryAgain)),
          ],
        ),
      UpdateInstallNotCompleted() => (
          l10n.updateNotInstalledTitle,
          [Text(l10n.updateNotInstalledBody, style: TextStyle(color: tokens.ink, height: 1.4))],
          [
            if (!mandatory) TextButton(onPressed: close, child: Text(l10n.updateClose)),
            if (website != null)
              TextButton(
                onPressed: () => launchUrl(
                  website.replace(path: '${website.path}/download'),
                  mode: LaunchMode.externalApplication,
                ),
                child: Text(l10n.updateOpenWebsite),
              ),
            FilledButton(onPressed: controller.startUpdate, child: Text(l10n.tryAgain)),
          ],
        ),
      UpdateIdle() || UpdateChecking() || UpdateUpToDate() => (l10n.updateAvailableTitle, [subtitle], const <Widget>[]),
    };

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && closable) close();
      },
      child: AlertDialog(
        scrollable: true,
        title: Text(title),
        content: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: content),
        actions: actions,
      ),
    );
  }

  static String _failureMessage(AppLocalizations l10n, UpdateFailure failure) => switch (failure) {
        UpdateFailure.checkFailed => l10n.updateFailedCheck,
        UpdateFailure.downloadFailed => l10n.updateFailedDownload,
        UpdateFailure.integrityFailed => l10n.updateFailedIntegrity,
        UpdateFailure.permissionDenied => l10n.updateFailedPermission,
        UpdateFailure.installFailed => l10n.updateFailedInstall,
      };
}
