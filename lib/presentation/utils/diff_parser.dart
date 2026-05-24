enum DiffLineType {
  add, // + line
  remove, // - line
  hunk, // @@ -l1,c1 +l2,c2 @@
  metadata, // ---, +++, diff --git, index
  context, // unchanged lines
}

class DiffLine {
  const DiffLine(
    this.content,
    this.type, {
    this.oldLineNo,
    this.newLineNo,
  });

  final String content;
  final DiffLineType type;

  /// 1-based line number in the old (before) file, or null if not applicable.
  final int? oldLineNo;

  /// 1-based line number in the new (after) file, or null if not applicable.
  final int? newLineNo;
}

/// A grouped hunk extracted from a flat [DiffLine] list, suitable for
/// collapsed/expanded rendering and lazy build.
class DiffHunk {
  const DiffHunk({
    required this.header,
    required this.lines,
    required this.oldStart,
    required this.newStart,
    required this.oldCount,
    required this.newCount,
  });

  /// The @@ header line (type == DiffLineType.hunk).
  final DiffLine header;

  /// Content lines within this hunk (add, remove, context — no metadata/hunk).
  final List<DiffLine> lines;

  /// Old-file start line from the @@ header.
  final int oldStart;

  /// New-file start line from the @@ header.
  final int newStart;

  /// Old-file line count from the @@ header.
  final int oldCount;

  /// New-file line count from the @@ header.
  final int newCount;

  /// Number of content lines (excluding the header itself).
  int get lineCount => lines.length;
}

/// Threshold: hunks with more content lines than this default to collapsed.
const int kDefaultCollapseThreshold = 20;

/// Parse unified diff text into typed lines
List<DiffLine> parseDiffLines(String text) {
  final lines = text.split('\n');
  final result = <DiffLine>[];

  for (final line in lines) {
    DiffLineType type;

    if (line.startsWith('+++') || line.startsWith('---')) {
      // Metadata comes before add/remove check
      type = DiffLineType.metadata;
    } else if (line.startsWith('+')) {
      type = DiffLineType.add;
    } else if (line.startsWith('-')) {
      type = DiffLineType.remove;
    } else if (line.startsWith('@@')) {
      type = DiffLineType.hunk;
    } else if (line.startsWith('diff --git') || line.startsWith('index ')) {
      type = DiffLineType.metadata;
    } else {
      type = DiffLineType.context;
    }

    result.add(DiffLine(line, type));
  }

  return result;
}

/// Pure variant: split on line boundaries, treat empty string as [].
List<String> _toLines(String text) {
  if (text.isEmpty) return [];
  final lines = text.split(RegExp(r'\r\n|\r|\n'));
  // A trailing newline produces one empty element — drop it.
  if (lines.isNotEmpty && lines.last.isEmpty) lines.removeLast();
  return lines;
}

const int _lcsCellGuard = 4000000;

/// Compute a unified diff as [DiffLine] list using LCS-based line comparison.
///
/// Returns metadata-only placeholder when both [before] and [after] are empty,
/// /dev/null headers for new/deleted files, and proper hunks with 3-line context
/// for normal diffs. Falls back to degenerative whole-file diff when
/// before.lines × after.lines exceeds [_lcsCellGuard].
List<DiffLine> computeDiffLines(String before, String after, String filename) {
  final bLines = _toLines(before);
  final aLines = _toLines(after);

  // Both empty — no content available from server
  if (bLines.isEmpty && aLines.isEmpty) {
    return [
      DiffLine('--- $filename', DiffLineType.metadata),
      DiffLine('+++ $filename', DiffLineType.metadata),
      const DiffLine('@@', DiffLineType.hunk),
    ];
  }

  // New file — before is empty
  if (bLines.isEmpty) {
    return [
      const DiffLine('--- /dev/null', DiffLineType.metadata),
      DiffLine('+++ $filename', DiffLineType.metadata),
      DiffLine('@@ -0,0 +1,${aLines.length} @@', DiffLineType.hunk),
      for (final line in aLines) DiffLine('+$line', DiffLineType.add),
    ];
  }

  // Deleted file — after is empty
  if (aLines.isEmpty) {
    return [
      DiffLine('--- $filename', DiffLineType.metadata),
      const DiffLine('+++ /dev/null', DiffLineType.metadata),
      DiffLine('@@ -1,${bLines.length} +0,0 @@', DiffLineType.hunk),
      for (final line in bLines) DiffLine('-$line', DiffLineType.remove),
    ];
  }

  // Guard: O(n*m) memory for large files — fall back to whole-file diff
  if (bLines.length * aLines.length > _lcsCellGuard) {
    return _degenerateDiff(bLines, aLines, filename);
  }

  // Build LCS DP table
  final m = bLines.length;
  final n = aLines.length;
  final dp = List.generate(m + 1, (_) => List.filled(n + 1, 0));
  for (var i = 1; i <= m; i++) {
    for (var j = 1; j <= n; j++) {
      if (bLines[i - 1] == aLines[j - 1]) {
        dp[i][j] = dp[i - 1][j - 1] + 1;
      } else {
        dp[i][j] = dp[i - 1][j] > dp[i][j - 1] ? dp[i - 1][j] : dp[i][j - 1];
      }
    }
  }

  // Backtrack to produce edit script: (op, lineIndex)
  // op: '=' context, '-' remove, '+' add
  final edits = <(String, int, int)>[]; // (op, bIdx, aIdx)
  var i = m, j = n;
  while (i > 0 || j > 0) {
    if (i > 0 && j > 0 && bLines[i - 1] == aLines[j - 1]) {
      edits.add(('=', i - 1, j - 1));
      i--;
      j--;
    } else if (j > 0 && (i == 0 || dp[i][j - 1] >= dp[i - 1][j])) {
      edits.add(('+', i, j - 1));
      j--;
    } else {
      edits.add(('-', i - 1, j));
      i--;
    }
  }
  final reversedEdits = edits.reversed.toList();

  // Group edits into hunks with 3-line context
  return _buildHunks(reversedEdits, bLines, aLines, filename);
}

/// Degenerative whole-file diff for large files that exceed the LCS cell guard.
List<DiffLine> _degenerateDiff(
  List<String> bLines,
  List<String> aLines,
  String filename,
) {
  return [
    DiffLine('--- $filename', DiffLineType.metadata),
    DiffLine('+++ $filename', DiffLineType.metadata),
    DiffLine(
      '@@ -1,${bLines.length} +1,${aLines.length} @@',
      DiffLineType.hunk,
    ),
    for (final line in bLines) DiffLine('-$line', DiffLineType.remove),
    for (final line in aLines) DiffLine('+$line', DiffLineType.add),
  ];
}

/// Group edit script into hunks with 3-line context windows.
List<DiffLine> _buildHunks(
  List<(String, int, int)> edits,
  List<String> bLines,
  List<String> aLines,
  String filename,
) {
  const contextLines = 3;

  // Find change boundaries — indices where op differs from previous
  final changeRanges = <(int, int)>[]; // (start, end) inclusive in edits
  var inChange = false;
  var changeStart = 0;
  for (var k = 0; k < edits.length; k++) {
    final isChange = edits[k].$1 != '=';
    if (isChange && !inChange) {
      changeStart = k;
      inChange = true;
    } else if (!isChange && inChange) {
      changeRanges.add((changeStart, k - 1));
      inChange = false;
    }
  }
  if (inChange) changeRanges.add((changeStart, edits.length - 1));

  if (changeRanges.isEmpty) {
    // Identical content — single context hunk
    final count = bLines.length;
    return [
      DiffLine('--- $filename', DiffLineType.metadata),
      DiffLine('+++ $filename', DiffLineType.metadata),
      DiffLine('@@ -1,$count +1,$count @@', DiffLineType.hunk),
      for (final line in bLines) DiffLine(' $line', DiffLineType.context),
    ];
  }

  // Merge overlapping hunks (context windows that touch or overlap)
  final mergedRanges = <(int, int)>[];
  for (final range in changeRanges) {
    final start = range.$1 > contextLines ? range.$1 - contextLines : 0;
    final end = range.$2 + contextLines < edits.length - 1
        ? range.$2 + contextLines
        : edits.length - 1;
    if (mergedRanges.isEmpty || start > mergedRanges.last.$2 + 1) {
      mergedRanges.add((start, end));
    } else {
      mergedRanges[mergedRanges.length - 1] = (mergedRanges.last.$1, end);
    }
  }

  final result = <DiffLine>[
    DiffLine('--- $filename', DiffLineType.metadata),
    DiffLine('+++ $filename', DiffLineType.metadata),
  ];

  for (final range in mergedRanges) {
    var bStart = 1;
    var aStart = 1;
    var bCount = 0;
    var aCount = 0;

    // Count lines in this hunk for the @@ header
    for (var k = range.$1; k <= range.$2; k++) {
      final op = edits[k].$1;
      if (op == '=' || op == '-') bCount++;
      if (op == '=' || op == '+') aCount++;
    }

    // Find starting line numbers (1-based) from the edit indices
    for (var k = 0; k < range.$1; k++) {
      final op = edits[k].$1;
      if (op == '=' || op == '-') bStart++;
      if (op == '=' || op == '+') aStart++;
    }

    // Handle edge case: hunk starts at beginning
    if (range.$1 == 0) {
      bStart = 1;
      aStart = 1;
    }

    result.add(
      DiffLine('@@ -$bStart,$bCount +$aStart,$aCount @@', DiffLineType.hunk),
    );

    for (var k = range.$1; k <= range.$2; k++) {
      final (op, bIdx, aIdx) = edits[k];
      switch (op) {
        case '=':
          result.add(DiffLine(' ${bLines[bIdx]}', DiffLineType.context));
        case '-':
          result.add(DiffLine('-${bLines[bIdx]}', DiffLineType.remove));
        case '+':
          result.add(DiffLine('+${aLines[aIdx]}', DiffLineType.add));
      }
    }
  }

  return result;
}

/// Heuristic detection of unified diff format
/// Checks first 20 lines for diff markers
bool isDiffFormat(String text) {
  final lines = text.split('\n');
  var markerCount = 0;

  for (final line in lines.take(20)) {
    if (line.startsWith('diff --git') ||
        line.startsWith('--- ') ||
        line.startsWith('+++ ') ||
        line.startsWith('@@ ')) {
      markerCount++;
      if (markerCount >= 2) {
        return true;
      }
    }
  }

  return false;
}

// ---------------------------------------------------------------------------
// Hunk grouping: split a flat DiffLine list into DiffHunk objects
// ---------------------------------------------------------------------------

/// Regex to extract old/new start and count from @@ headers like:
/// `@@ -1,3 +1,4 @@` or `@@ -0,0 +1,5 @@`
final _hunkHeaderRe = RegExp(r'@@ -(\d+),(\d+) \+(\d+),(\d+) @@');

/// Group flat [DiffLine] list into [DiffHunk] objects.
///
/// Metadata lines (---, +++, diff --git, index) before the first hunk header
/// are dropped — the viewer renders them separately. Each hunk contains its
/// header line and the content lines until the next hunk or end-of-list.
List<DiffHunk> groupIntoHunks(List<DiffLine> lines) {
  final hunks = <DiffHunk>[];
  DiffLine? currentHeader;
  var currentOldStart = 0;
  var currentNewStart = 0;
  var currentOldCount = 0;
  var currentNewCount = 0;
  var currentLines = <DiffLine>[];

  for (final line in lines) {
    if (line.type == DiffLineType.hunk) {
      // Flush previous hunk
      if (currentHeader != null) {
        hunks.add(DiffHunk(
          header: currentHeader,
          lines: List.of(currentLines),
          oldStart: currentOldStart,
          newStart: currentNewStart,
          oldCount: currentOldCount,
          newCount: currentNewCount,
        ));
      }
      currentHeader = line;
      currentLines = <DiffLine>[];
      // Parse @@ header for start/count values
      final match = _hunkHeaderRe.firstMatch(line.content);
      if (match != null) {
        currentOldStart = int.parse(match[1]!);
        currentOldCount = int.parse(match[2]!);
        currentNewStart = int.parse(match[3]!);
        currentNewCount = int.parse(match[4]!);
      }
    } else if (line.type != DiffLineType.metadata && currentHeader != null) {
      currentLines.add(line);
    }
  }

  // Flush last hunk
  if (currentHeader != null) {
    hunks.add(DiffHunk(
      header: currentHeader,
      lines: List.of(currentLines),
      oldStart: currentOldStart,
      newStart: currentNewStart,
      oldCount: currentOldCount,
      newCount: currentNewCount,
    ));
  }

  return hunks;
}

/// Annotate a flat [DiffLine] list with 1-based line numbers.
///
/// Walks the list tracking old/new line counters:
/// - `context` lines increment both counters
/// - `remove` lines increment only the old counter
/// - `add` lines increment only the new counter
/// - `hunk` and `metadata` lines get no line numbers
List<DiffLine> annotateLineNumbers(List<DiffLine> lines) {
  // Extract starting line numbers from the first @@ header
  var oldLine = 0;
  var newLine = 0;
  var foundFirstHunk = false;

  return lines.map((line) {
    if (line.type == DiffLineType.hunk && !foundFirstHunk) {
      final match = _hunkHeaderRe.firstMatch(line.content);
      if (match != null) {
        oldLine = int.parse(match[1]!);
        newLine = int.parse(match[3]!);
      } else {
        // Malformed hunk header — start from line 1 as fallback
        oldLine = 1;
        newLine = 1;
      }
      foundFirstHunk = true;
      return line;
    }

    if (line.type == DiffLineType.hunk) {
      // Subsequent hunk headers — re-sync line numbers
      final match = _hunkHeaderRe.firstMatch(line.content);
      if (match != null) {
        oldLine = int.parse(match[1]!);
        newLine = int.parse(match[3]!);
      }
      // If regex fails on subsequent hunk, keep current counters
      return line;
    }

    if (line.type == DiffLineType.metadata) {
      return line;
    }

    // Track line numbers for content lines
    int? oldNo;
    int? newNo;

    switch (line.type) {
      case DiffLineType.context:
        oldNo = oldLine;
        newNo = newLine;
        oldLine++;
        newLine++;
      case DiffLineType.remove:
        oldNo = oldLine;
        oldLine++;
      case DiffLineType.add:
        newNo = newLine;
        newLine++;
      case DiffLineType.hunk:
      case DiffLineType.metadata:
        break;
    }

    return DiffLine(line.content, line.type,
        oldLineNo: oldNo, newLineNo: newNo);
  }).toList();
}

// ---------------------------------------------------------------------------
// Language resolution for syntax highlighting (mirrors chat_page_file_viewer)
// ---------------------------------------------------------------------------

/// Resolve a highlight.js language identifier from a file path.
///
/// This is a standalone utility so that [SessionDiffViewer] can apply
/// syntax-aware styling without importing chat_page.dart.
String resolveDiffHighlightLanguage(String path) {
  final normalizedPath = path.toLowerCase();
  final lastSlash = normalizedPath.lastIndexOf('/');
  final fileName =
      lastSlash >= 0 ? normalizedPath.substring(lastSlash + 1) : normalizedPath;
  final dotIndex = fileName.lastIndexOf('.');
  final extension = dotIndex >= 0 ? fileName.substring(dotIndex + 1) : '';

  switch (fileName) {
    case 'dockerfile':
      return 'dockerfile';
    case 'makefile':
      return 'makefile';
    case '.bashrc':
    case '.bash_profile':
    case '.bash_aliases':
    case '.zshrc':
    case '.zprofile':
    case '.zshenv':
    case '.profile':
      return 'bash';
  }

  return switch (extension) {
    'dart' => 'dart',
    'js' || 'mjs' || 'cjs' || 'jsx' => 'javascript',
    'ts' || 'mts' || 'cts' || 'tsx' => 'typescript',
    'json' => 'json',
    'yaml' || 'yml' => 'yaml',
    'md' || 'mdx' => 'markdown',
    'sh' || 'ash' || 'bash' || 'zsh' => 'bash',
    'py' => 'python',
    'go' => 'go',
    'rs' => 'rust',
    'java' => 'java',
    'kt' || 'kts' => 'kotlin',
    'swift' => 'swift',
    'php' => 'php',
    'rb' => 'ruby',
    'sql' => 'sql',
    'html' || 'htm' || 'xml' || 'svg' => 'xml',
    'css' => 'css',
    'scss' => 'scss',
    'less' => 'less',
    'toml' || 'ini' || 'cfg' || 'conf' || 'properties' => 'ini',
    'vue' => 'vue',
    _ => 'plaintext',
  };
}
