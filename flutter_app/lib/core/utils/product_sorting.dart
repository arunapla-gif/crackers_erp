const List<String> preferredSubCategoryOrder = [
  '400 COUNT',
  '400 COUNT (CORE & CELLOPHANE)',
  '600 COUNT',
  '700 COUNT',
  '800 COUNT',
];

int compareSubCategories(String a, String b) {
  final idxA = preferredSubCategoryOrder.indexOf(a.toUpperCase());
  final idxB = preferredSubCategoryOrder.indexOf(b.toUpperCase());
  if (idxA != -1 && idxB != -1) return idxA.compareTo(idxB);
  if (idxA != -1) return -1;
  if (idxB != -1) return 1;
  return a.toLowerCase().compareTo(b.toLowerCase());
}

final RegExp _firstIntRegex = RegExp(r'\d+');

int extractFirstInt(String value) {
  final match = _firstIntRegex.firstMatch(value);
  return match != null ? (int.tryParse(match.group(0)!) ?? 0) : 0;
}

int compareProductNamesByNumericOrder(String a, String b) {
  final numA = extractFirstInt(a);
  final numB = extractFirstInt(b);
  if (numA != numB) return numA.compareTo(numB);
  return a.toLowerCase().compareTo(b.toLowerCase());
}

int naturalCompareStrings(String a, String b) {
  final tokenRegex = RegExp(r'(\d+|\D+)');
  final tokensA = tokenRegex.allMatches(a.toLowerCase()).map((m) => m.group(0)!).toList();
  final tokensB = tokenRegex.allMatches(b.toLowerCase()).map((m) => m.group(0)!).toList();
  final len = tokensA.length < tokensB.length ? tokensA.length : tokensB.length;
  for (var i = 0; i < len; i++) {
    final ta = tokensA[i];
    final tb = tokensB[i];
    final na = int.tryParse(ta);
    final nb = int.tryParse(tb);
    if (na != null && nb != null) {
      final cmp = na.compareTo(nb);
      if (cmp != 0) return cmp;
    } else {
      final cmp = ta.compareTo(tb);
      if (cmp != 0) return cmp;
    }
  }
  return tokensA.length.compareTo(tokensB.length);
}
