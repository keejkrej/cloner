import 'dart:convert';

class VariableInterpolator {
  /// Interpolates {{variable.path}} syntax with context values
  static String interpolate(String template, Map<String, dynamic> context) {
    final pattern = RegExp(r'\{\{([a-zA-Z0-9_\.]+)\}\}');
    return template.replaceAllMapped(pattern, (match) {
      final keyPath = match.group(1);
      if (keyPath == null) return match.group(0)!;

      final val = _resolvePath(keyPath, context);
      if (val == null) {
        return '';
      }
      if (val is String) {
        return val;
      }
      return jsonEncode(val);
    });
  }

  static dynamic _resolvePath(String path, Map<String, dynamic> context) {
    final parts = path.split('.');
    dynamic current = context;

    for (final part in parts) {
      if (current is Map) {
        current = current[part];
      } else {
        return null;
      }
      if (current == null) return null;
    }
    return current;
  }

  /// Recursively interpolates any strings inside a Map
  static Map<String, dynamic> interpolateMap(
    Map<String, dynamic> map,
    Map<String, dynamic> context,
  ) {
    final result = <String, dynamic>{};
    for (final entry in map.entries) {
      if (entry.value is String) {
        result[entry.key] = interpolate(entry.value as String, context);
      } else if (entry.value is Map<String, dynamic>) {
        result[entry.key] = interpolateMap(entry.value as Map<String, dynamic>, context);
      } else if (entry.value is List) {
        result[entry.key] = entry.value.map((item) {
          if (item is String) {
            return interpolate(item, context);
          } else if (item is Map<String, dynamic>) {
            return interpolateMap(item, context);
          }
          return item;
        }).toList();
      } else {
        result[entry.key] = entry.value;
      }
    }
    return result;
  }
}
