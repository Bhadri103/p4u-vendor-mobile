/// Capitalizes the first character of every word while preserving the rest of
/// the stored business name, including intentional acronyms and brand casing.
String titleCaseWords(Object? value) {
  final text = value?.toString().trim() ?? '';
  if (text.isEmpty) return '';
  return text
      .split(RegExp(r'\s+'))
      .map((word) => word.isEmpty
          ? word
          : '${word.substring(0, 1).toUpperCase()}${word.substring(1)}')
      .join(' ');
}
