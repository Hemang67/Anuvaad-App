import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/bootstrap.dart';
import '../../../app/routes.dart';
import '../../../app/theme/anuvaad_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../application/history_providers.dart';
import 'conversation_tile.dart';

/// Saved conversations (spec §5-12): search, newest first, tap to review.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = Theme.of(context).extension<AnuvaadColors>()!;
    final registry = ref.watch(languageRegistryProvider);
    String name(String code) => registry.byCode(code)?.displayName ?? code;
    final historyOn = ref.watch(saveHistoryProvider);
    final results = ref.watch(historySearchProvider(_query));

    return Scaffold(
      key: const Key('history-screen'),
      appBar: AppBar(title: Text(l10n.historyTitle)),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                key: const Key('history-search'),
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: l10n.historySearchHint,
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: tokens.card,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: tokens.line)),
                  enabledBorder:
                      OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: tokens.line)),
                ),
              ),
            ),
            Expanded(
              child: results.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => _Message(title: l10n.historyEmpty),
                data: (conversations) {
                  if (conversations.isEmpty) {
                    if (_query.trim().isNotEmpty) return _Message(title: l10n.historyNoMatch(_query.trim()));
                    if (!historyOn) {
                      return _Message(
                        title: l10n.historyOffTitle,
                        body: l10n.historyOffBody,
                        action: FilledButton(onPressed: () => context.go(Routes.settings), child: Text(l10n.historyTurnOn)),
                      );
                    }
                    return _Message(title: l10n.historyEmpty);
                  }
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    children: [
                      for (final c in conversations)
                        ConversationTile(
                          key: Key('history-${c.id}'),
                          conversation: c,
                          languageName: name,
                          onTap: () => context.push(Routes.historyDetail(c.id)),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.title, this.body, this.action});

  final String title;
  final String? body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AnuvaadColors>()!;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 40, color: tokens.blue),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: tokens.ink),
            ),
            if (body case final body?) ...[
              const SizedBox(height: 8),
              Text(body, textAlign: TextAlign.center, style: TextStyle(color: tokens.muted, height: 1.4)),
            ],
            if (action case final action?) ...[const SizedBox(height: 16), action],
          ],
        ),
      ),
    );
  }
}
