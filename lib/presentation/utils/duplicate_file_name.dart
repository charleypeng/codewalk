/// Builds a copy name that does not collide with [existingNames].
///
/// Follows the convention issue #105 asked for: `name copy.ext`, then
/// `name copy 2.ext`, `name copy 3.ext` and so on, so duplicating never
/// silently overwrites a file that is already there.
///
/// A leading dot is treated as part of the name rather than an extension, so
/// `.gitignore` duplicates to `.gitignore copy` instead of ` copy.gitignore`.
String duplicateFileName(String originalName, Set<String> existingNames) {
  final dotIndex = originalName.lastIndexOf('.');
  final hasExtension = dotIndex > 0;
  final stem = hasExtension
      ? originalName.substring(0, dotIndex)
      : originalName;
  final extension = hasExtension ? originalName.substring(dotIndex) : '';

  var candidate = '$stem copy$extension';
  var counter = 2;
  while (existingNames.contains(candidate)) {
    candidate = '$stem copy $counter$extension';
    counter += 1;
  }
  return candidate;
}
