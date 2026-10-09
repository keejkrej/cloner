import 'dart:io';
import 'package:path/path.dart' as p;

class JailSecurityException implements Exception {
  final String message;
  JailSecurityException(this.message);

  @override
  String toString() => 'JailSecurityException: $message';
}

class JailService {
  /// Validates that [targetPath] is strictly inside [workingDir].
  /// Returns the absolute, normalized FileSystemEntity path.
  /// Throws [JailSecurityException] if outside the jail.
  static String resolveAndValidate(String targetPath, String workingDir) {
    if (workingDir.trim().isEmpty) {
      throw JailSecurityException('No working directory selected');
    }

    final normalizedWorkingDir = p.canonicalize(workingDir);

    String resolved;
    if (p.isAbsolute(targetPath)) {
      resolved = p.canonicalize(targetPath);
    } else {
      resolved = p.canonicalize(p.join(normalizedWorkingDir, targetPath));
    }

    // Windows paths are case-insensitive
    final isInside = Platform.isWindows
        ? resolved.toLowerCase().startsWith(normalizedWorkingDir.toLowerCase())
        : resolved.startsWith(normalizedWorkingDir);

    if (!isInside) {
      throw JailSecurityException(
        'Access denied: Path "$targetPath" is outside the working directory jail ("$workingDir").',
      );
    }

    return resolved;
  }

  /// Checks if path is safe without throwing
  static bool isPathSafe(String targetPath, String workingDir) {
    try {
      resolveAndValidate(targetPath, workingDir);
      return true;
    } catch (_) {
      return false;
    }
  }
}
