/// Parses one release entry from CHANGELOG.md (format: docs/release-process.md).
class ChangelogEntry {
  const ChangelogEntry({
    required this.version,
    required this.build,
    required this.date,
    required this.mandatory,
    required this.minSupportedBuild,
    required this.whatsNew,
    required this.fixed,
    required this.notesMarkdown,
  });

  final String version;
  final int build;
  final DateTime date;
  final bool mandatory;
  final int minSupportedBuild;
  final List<String> whatsNew;
  final List<String> fixed;

  /// The GitHub Release body: the two sections, empty ones left out.
  final String notesMarkdown;
}

final _heading = RegExp(r'^## (\d+\.\d+\.\d+) \((\d+)\) [—-] (\d{4})-(\d{2})-(\d{2})\s*$');
const _whatsNew = "### What's new";
const _fixed = '### Fixed';

ChangelogEntry parseChangelogEntry(String changelog, String version) {
  final lines = changelog.replaceAll('\r\n', '\n').split('\n');
  final start = lines.indexWhere((l) => l.startsWith('## $version ') || l.trim() == '## $version');
  if (start < 0) throw FormatException('No CHANGELOG entry for $version');
  final match = _heading.firstMatch(lines[start]);
  if (match == null) {
    throw FormatException('Malformed CHANGELOG heading for $version: "${lines[start]}" (expected "## X.Y.Z (BUILD) — YYYY-MM-DD")');
  }

  var mandatory = false;
  var minSupportedBuild = 1;
  final whatsNew = <String>[];
  final fixed = <String>[];
  List<String>? section;

  for (final raw in lines.skip(start + 1)) {
    if (raw.startsWith('## ')) break;
    final line = raw.trimRight();
    if (line.trim().isEmpty) continue;
    if (line.startsWith('### ')) {
      section = switch (line) {
        _whatsNew => whatsNew,
        _fixed => fixed,
        _ => throw FormatException('Unknown section "$line" in $version (use "$_whatsNew" or "$_fixed")'),
      };
      continue;
    }
    if (section == null) {
      final flag = RegExp(r'^Mandatory:\s*(yes|no)$').firstMatch(line);
      final min = RegExp(r'^Min supported build:\s*(\d+)$').firstMatch(line);
      if (flag != null) {
        mandatory = flag.group(1) == 'yes';
      } else if (min != null) {
        minSupportedBuild = int.parse(min.group(1)!);
      } else {
        throw FormatException('Unexpected line before the first section in $version: "$line"');
      }
      continue;
    }
    if (!line.startsWith('- ') || line.substring(2).trim().isEmpty) {
      throw FormatException('Expected a "- " bullet in $version, found: "$line"');
    }
    section.add(line.substring(2).trim());
  }

  if (whatsNew.isEmpty && fixed.isEmpty) throw FormatException('CHANGELOG entry $version has no bullets');

  String block(String title, List<String> items) => '$title\n${items.map((i) => '- $i\n').join()}';
  final notes = [if (whatsNew.isNotEmpty) block(_whatsNew, whatsNew), if (fixed.isNotEmpty) block(_fixed, fixed)].join('\n');

  return ChangelogEntry(
    version: match.group(1)!,
    build: int.parse(match.group(2)!),
    date: DateTime.utc(int.parse(match.group(3)!), int.parse(match.group(4)!), int.parse(match.group(5)!)),
    mandatory: mandatory,
    minSupportedBuild: minSupportedBuild,
    whatsNew: List.unmodifiable(whatsNew),
    fixed: List.unmodifiable(fixed),
    notesMarkdown: notes,
  );
}

/// Throws [StateError] unless pubspec's `version:` is exactly `<version>+<build>`.
void verifyPubspecVersion(String pubspecYaml, {required String version, required int build}) {
  final match = RegExp(r'^version:\s*(\S+)\s*$', multiLine: true).firstMatch(pubspecYaml);
  final found = match?.group(1);
  final expected = '$version+$build';
  if (found != expected) throw StateError('pubspec.yaml version is "$found", expected "$expected"');
}
