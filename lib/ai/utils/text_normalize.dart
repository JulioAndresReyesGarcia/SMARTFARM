/// Normaliza texto para comparación (minúsculas, sin tildes).
String normalizeForMatch(String input) {
  var s = input.toLowerCase().trim();
  const accents = {
    'á': 'a', 'à': 'a', 'ä': 'a', 'â': 'a',
    'é': 'e', 'è': 'e', 'ë': 'e', 'ê': 'e',
    'í': 'i', 'ì': 'i', 'ï': 'i', 'î': 'i',
    'ó': 'o', 'ò': 'o', 'ö': 'o', 'ô': 'o',
    'ú': 'u', 'ù': 'u', 'ü': 'u', 'û': 'u',
    'ñ': 'n',
  };
  for (final e in accents.entries) {
    s = s.replaceAll(e.key, e.value);
  }
  return s;
}

bool textContainsAny(String haystack, List<String> needles) {
  final h = normalizeForMatch(haystack);
  for (final n in needles) {
    if (h.contains(normalizeForMatch(n))) return true;
  }
  return false;
}
