/// 'A', 'A or B', 'A, B or C' — [lastSeparator] comes from the l10n `listOr` / `listAnd` strings.
String joinList(List<String> items, {required String lastSeparator}) {
  if (items.length < 2) return items.isEmpty ? '' : items.first;
  return '${items.sublist(0, items.length - 1).join(', ')}$lastSeparator${items.last}';
}
