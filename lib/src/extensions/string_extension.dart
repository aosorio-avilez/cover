final _ansiAndControlRegExp = RegExp(
  r'\x1B\[[0-?]*[ -/]*[@-~]|[\x00-\x1F\x7F\u061C\u200E\u200F\u202A-\u202E\u2066-\u2069]',
);

extension StringExtension on String {
  /// Sanitizes the string by stripping ANSI escape sequences and control characters.
  String sanitize() {
    if (_hasAnsiOrControlChars(this)) {
      return replaceAll(_ansiAndControlRegExp, '');
    }
    return this;
  }
}

bool _hasAnsiOrControlChars(String s) {
  for (var i = 0; i < s.length; i++) {
    final code = s.codeUnitAt(i);
    // Fast-path for ASCII printable characters (0x20 - 0x7E) which are the most
    // common characters in source file paths and error messages.
    if (code >= 0x20 && code <= 0x7E) continue;

    // 0x00-0x1F (control chars including \x1B) and 0x7F (DEL)
    // Also include Unicode Bidi control characters.
    if (code <= 0x1F ||
        code == 0x7F ||
        code == 0x061C ||
        code == 0x200E ||
        code == 0x200F ||
        (code >= 0x202A && code <= 0x202E) ||
        (code >= 0x2066 && code <= 0x2069)) {
      return true;
    }
  }
  return false;
}
