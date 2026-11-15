/// Utilities for offline English-to-Tamil phonetic transliteration and bilingual
/// name management in Crackers ERP.
class TamilTransliteration {
  /// Common Tamil/Indian factory names mapped to their standard Tamil spellings.
  static const Map<String, String> commonNames = {
    'muthu': 'முத்து',
    'kaliappan': 'காளியப்பன்',
    'murugan': 'முருகன்',
    'kumar': 'குமார்',
    'selvi': 'செல்வி',
    'suresh': 'சுரேஷ்',
    'karthik': 'கார்த்திக்',
    'karthikeyan': 'கார்த்திகேயன்',
    'ramasamy': 'ராமசாமி',
    'ramaswamy': 'ராமசுவாமி',
    'lakshmi': 'லட்சுமி',
    'laxmi': 'லட்சுமி',
    'anbu': 'அன்பு',
    'marimuthu': 'மாரிமுத்து',
    'ganesh': 'கணேஷ்',
    'pandian': 'பாண்டியன்',
    'arumugam': 'ஆறுமுகம்',
    'vijay': 'விஜய்',
    'ajith': 'அஜித்',
    'devi': 'தேவி',
    'pooja': 'பூஜா',
    'kannan': 'கண்ணன்',
    'palani': 'பழனி',
    'pazhani': 'பழனி',
    'senthil': 'செந்தில்',
    'manikandan': 'மணிகண்டன்',
    'mani': 'மணி',
    'raja': 'ராஜா',
    'rajesh': 'ராஜேஷ்',
    'praveen': 'பிரவீன்',
    'dhanapal': 'தனபால்',
    'tanapal': 'தனபால்',
    'velu': 'வேலு',
    'vel': 'வேல்',
    'saravanan': 'சரவணன்',
    'babu': 'பாபு',
    'shankar': 'சங்கர்',
    'sankar': 'சங்கர்',
    'krishnan': 'கிருஷ்ணன்',
    'krishna': 'கிருஷ்ணா',
    'perumal': 'பெருமாள்',
    'subramanian': 'சுப்பிரமணியன்',
    'balan': 'பாலன்',
    'chithra': 'சித்ரா',
    'chitra': 'சித்ரா',
    'radha': 'ராதா',
    'geetha': 'கீதா',
    'gita': 'கீதா',
    'meena': 'மீனா',
    'malar': 'மலர்',
    'kavitha': 'கவிதா',
    'shanthi': 'சாந்தி',
    'santhi': 'சாந்தி',
    'revathi': 'ரேவதி',
    'vasanth': 'வசந்த்',
    'dinesh': 'தினேஷ்',
    'vignesh': 'விக்னேஷ்',
    'mahesh': 'மகேஷ்',
    'ramesh': 'ரமேஷ்',
    'selvam': 'செல்வம்',
    'ponraj': 'பொன்ராஜ்',
    'eswaran': 'ஈஸ்வரன்',
    'easwaran': 'ஈஸ்வரன்',
    'iswaran': 'ஈஸ்வரன்',
    'ayyappan': 'அய்யப்பன்',
    'iyappan': 'அய்யப்பன்',
    'arun': 'அருண்',
    'mohan': 'மோகன்',
    'madhavan': 'மாதவன்',
    'sundar': 'சுந்தர்',
    'nagaraj': 'நாகராஜ்',
    'govind': 'கோவிந்த்',
    'govindarajan': 'கோவிந்தராஜன்',
    'kamal': 'கமல்',
    'hari': 'ஹரி',
    'siva': 'சிவா',
    'shiva': 'சிவா',
    'sakthi': 'சக்தி',
    'shakthi': 'சக்தி',
    'muthuraj': 'முத்துராஜ்',
    'veera': 'வீரா',
    'veeran': 'வீரன்',
    'deepa': 'தீபா',
    'sudha': 'சுதா',
    'usha': 'உஷா',
    'kalai': 'கலை',
    'elango': 'இளங்கோ',
    'thangaraj': 'தங்கராஜ்',
    'muniyandi': 'முனியாண்டி',
    'karpagam': 'கற்பகம்',
    'muniasamy': 'முனியாசாமி',
    'karuppasamy': 'கருப்பசாமி',
    'madasamy': 'மாடசாமி',
    'guruvammal': 'குருவம்மாள்',
    'pechiammal': 'பேச்சியம்மாள்',
    'mariammal': 'மாரியம்மாள்',
    'subbulakshmi': 'சுப்புலட்சுமி',
    'priya': 'பிரியா',
    'prakash': 'பிரகாஷ்',
    'anand': 'ஆனந்த்',
    'anitha': 'அனிதா',
    'swetha': 'ஸ்வேதா',
    'sneha': 'சினேகா',
    'nisha': 'நிஷா',
    'karthika': 'கார்த்திகா',
    'pavithra': 'பவித்ரா',
    'ramya': 'ரம்யா',
    'soundarya': 'சௌந்தர்யா',
    'deepak': 'தீபக்',
    'prabhu': 'பிரபு',
    'arvind': 'அரவிந்த்',
    'siddharth': 'சித்தார்த்',
    'vijayan': 'விஜயன்',
    'surya': 'சூர்யா',
    'suriyan': 'சூரியன்',
    'balaji': 'பாலாஜி',
    'natarajan': 'நடராஜன்',
    'kanagaraj': 'கனகராஜ்',
    'venkatesh': 'வெங்கடேஷ்',
    'alagesan': 'அழகேசன்',
    'alaguraj': 'அழகுராஜ்',
    'selvaraj': 'செல்வராஜ்',
    'durai': 'துரை',
    'annadurai': 'அண்ணாதுரை',
    'kamala': 'கமலா',
    'kala': 'கலா',
    'baskaran': 'பாஸ்கரன்',
    'bhaskar': 'பாஸ்கர்',
    'ravichandran': 'ரவிச்சந்திரன்',
    'ravi': 'ரவி',
    'sathish': 'சதீஷ்',
    'satheesh': 'சதீஷ்',
    'sangeetha': 'சங்கீதா',
  };

  /// Common compound suffixes in Tamil personal names.
  static const List<MapEntry<String, String>> commonSuffixes = [
    MapEntry('kumar', 'குமார்'),
    MapEntry('kumaran', 'குமரன்'),
    MapEntry('raj', 'ராஜ்'),
    MapEntry('rajan', 'ராஜன்'),
    MapEntry('samy', 'சாமி'),
    MapEntry('swamy', 'சுவாமி'),
    MapEntry('vel', 'வேல்'),
    MapEntry('velu', 'வேலு'),
    MapEntry('murugan', 'முருகன்'),
    MapEntry('ammal', 'அம்மாள்'),
    MapEntry('lakshmi', 'லட்சுமி'),
    MapEntry('kannan', 'கண்ணன்'),
    MapEntry('mani', 'மணி'),
    MapEntry('selvan', 'செல்வன்'),
    MapEntry('selvi', 'செல்வி'),
    MapEntry('nathan', 'நாதன்'),
    MapEntry('pandian', 'பாண்டியன்'),
    MapEntry('moorthy', 'மூர்த்தி'),
    MapEntry('murthy', 'மூர்த்தி'),
    MapEntry('prasad', 'பிரசாத்'),
    MapEntry('lingam', 'லிங்கம்'),
  ];

  static const Map<String, String> independentVowels = {
    'aa': 'ஆ', 'a': 'அ',
    'ee': 'ஈ', 'ii': 'ஈ', 'i': 'இ',
    'oo': 'ஊ', 'uu': 'ஊ', 'u': 'உ',
    'ea': 'ஏ', 'ae': 'ஏ', 'e': 'எ',
    'ai': 'ஐ',
    'oa': 'ஓ', 'o': 'ஒ',
    'au': 'ஔ', 'ou': 'ஔ',
  };

  static const Map<String, String> vowelSigns = {
    'aa': '\u0BBE', 'a': '',
    'ee': '\u0BC0', 'ii': '\u0BC0', 'i': '\u0BBF',
    'oo': '\u0BC2', 'uu': '\u0BC2', 'u': '\u0BC1',
    'ea': '\u0BC7', 'ae': '\u0BC7', 'e': '\u0BC6',
    'ai': '\u0BC8',
    'oa': '\u0BCB', 'o': '\u0BCA',
    'au': '\u0BCC', 'ou': '\u0BCC',
  };

  static const String virama = '\u0BCD';

  static const List<MapEntry<String, String>> consonantRules = [
    MapEntry('shree', 'ஸ்ரீ'),
    MapEntry('sri', 'ஸ்ரீ'),
    MapEntry('ksh', 'க்ஷ'),
    MapEntry('thth', 'த்த'),
    MapEntry('chch', 'ச்ச'),
    MapEntry('kkh', 'க்க'),
    MapEntry('nth', 'ந்த'),
    MapEntry('nch', 'ஞ்ச'),
    MapEntry('nj', 'ஞ'),
    MapEntry('ng', 'ங'),
    MapEntry('gn', 'ஞ'),
    MapEntry('nd', 'ண்ட'),
    MapEntry('nt', 'ண்ட'),
    MapEntry('mb', 'ம்ப'),
    MapEntry('mp', 'ம்ப'),
    MapEntry('th', 'த'),
    MapEntry('dh', 'த'),
    MapEntry('zh', 'ழ'),
    MapEntry('sh', 'ஷ'),
    MapEntry('ch', 'ச'),
    MapEntry('kh', 'க'),
    MapEntry('gh', 'க'),
    MapEntry('ph', 'ப'),
    MapEntry('bh', 'ப'),
    MapEntry('tt', 'ட்ட'),
    MapEntry('dd', 'ட்ட'),
    MapEntry('pp', 'ப்ப'),
    MapEntry('bb', 'ப்ப'),
    MapEntry('kk', 'க்க'),
    MapEntry('gg', 'க்க'),
    MapEntry('ss', 'ஸ்'),
    MapEntry('jj', 'ஜ்'),
    MapEntry('mm', 'ம்ம'),
    MapEntry('nn', 'ண்ண'),
    MapEntry('ll', 'ல்ல'),
    MapEntry('rr', 'ற்ற'),
    MapEntry('k', 'க'),
    MapEntry('g', 'க'),
    MapEntry('c', 'க'),
    MapEntry('s', 'ச'),
    MapEntry('j', 'ஜ'),
    MapEntry('t', 'ட'),
    MapEntry('d', 'ட'),
    MapEntry('p', 'ப'),
    MapEntry('b', 'ப'),
    MapEntry('m', 'ம'),
    MapEntry('y', 'ய'),
    MapEntry('r', 'ர'),
    MapEntry('l', 'ல'),
    MapEntry('v', 'வ'),
    MapEntry('w', 'வ'),
    MapEntry('h', 'ஹ'),
    MapEntry('z', 'ஸ'),
    MapEntry('f', 'ப'),
    MapEntry('n', 'ந'),
  ];

  /// Transliterates a single English word into Tamil script.
  static String transliterateWord(String raw) {
    if (raw.trim().isEmpty) return '';
    final lower = raw.trim().toLowerCase();

    // 1. Direct dictionary match
    if (commonNames.containsKey(lower)) {
      return commonNames[lower]!;
    }

    // 2. Compound suffix match (e.g. muthukumar -> muthu + kumar)
    for (final suffix in commonSuffixes) {
      if (lower.length > suffix.key.length + 2 && lower.endsWith(suffix.key)) {
        final prefix = lower.substring(0, lower.length - suffix.key.length);
        final prefixTamil = transliterateWord(prefix);
        return '$prefixTamil${suffix.value}';
      }
    }

    final buffer = StringBuffer();
    int i = 0;
    bool afterConsonant = false;

    while (i < lower.length) {
      if (!afterConsonant) {
        String? matchedVowel;
        int vLen = 0;
        for (final v in [
          'aa', 'ee', 'ii', 'oo', 'uu', 'ea', 'ae', 'ai', 'oa', 'au', 'ou',
          'a', 'e', 'i', 'o', 'u'
        ]) {
          if (lower.startsWith(v, i)) {
            matchedVowel = v;
            vLen = v.length;
            break;
          }
        }
        if (matchedVowel != null) {
          buffer.write(independentVowels[matchedVowel] ?? '');
          i += vLen;
          afterConsonant = false;
          continue;
        }
      }

      MapEntry<String, String>? matchedConsonant;
      for (final rule in consonantRules) {
        if (lower.startsWith(rule.key, i)) {
          matchedConsonant = rule;
          break;
        }
      }

      if (matchedConsonant != null) {
        final cKey = matchedConsonant.key;
        String cGlyph = matchedConsonant.value;
        i += cKey.length;

        // Tamil nasal rules for 'n'
        if (cKey == 'n') {
          if (i == lower.length) {
            cGlyph = 'ன';
          } else if (i > 1 &&
              (lower[i - 2] == 'a' ||
                  lower[i - 2] == 'u' ||
                  lower[i - 2] == 'i')) {
            cGlyph = 'ன';
          }
        }

        String? nextVowel;
        int vLen = 0;
        for (final v in [
          'aa', 'ee', 'ii', 'oo', 'uu', 'ea', 'ae', 'ai', 'oa', 'au', 'ou',
          'a', 'e', 'i', 'o', 'u'
        ]) {
          if (lower.startsWith(v, i)) {
            nextVowel = v;
            vLen = v.length;
            break;
          }
        }

        if (nextVowel != null) {
          if (cGlyph == 'ஸ்ரீ') {
            buffer.write(cGlyph);
          } else if (cGlyph.endsWith('்')) {
            buffer.write(cGlyph);
            final sign = vowelSigns[nextVowel] ?? '';
            buffer.write(sign);
          } else {
            final lastChar = cGlyph[cGlyph.length - 1];
            final prefix = cGlyph.substring(0, cGlyph.length - 1);
            final sign = vowelSigns[nextVowel] ?? '';
            buffer.write('$prefix$lastChar$sign');
          }
          i += vLen;
          afterConsonant = false;
        } else {
          if (cGlyph == 'ஸ்ரீ') {
            buffer.write(cGlyph);
          } else if (cGlyph.endsWith('்')) {
            buffer.write(cGlyph);
          } else {
            buffer.write('$cGlyph$virama');
          }
          afterConsonant = true;
        }
        continue;
      }

      // Preserve spaces, dots, hyphens, and other characters
      buffer.write(lower[i]);
      i++;
      afterConsonant = false;
    }

    return buffer.toString();
  }

  /// Transliterates an English name (multi-word supported) into Tamil script.
  static String transliterate(String text) {
    if (text.trim().isEmpty) return '';
    final words = text.split(RegExp(r'\s+'));
    final results = <String>[];
    for (final w in words) {
      if (w.isEmpty) continue;
      results.add(transliterateWord(w));
    }
    return results.join(' ');
  }

  /// Parses an existing stored name into (english, tamil) parts.
  ///
  /// Examples:
  /// - `Muthu (முத்து)` -> `('Muthu', 'முத்து')`
  /// - `Muthu / முத்து` -> `('Muthu', 'முத்து')`
  /// - `Muthu - முத்து` -> `('Muthu', 'முத்து')`
  /// - `Muthu` -> `('Muthu', '')`
  static ({String english, String tamil}) parseBilingualName(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return (english: '', tamil: '');

    // Parentheses pattern: English (Tamil)
    final parenMatch = RegExp(r'^(.+?)\s*\((.+?)\)$').firstMatch(trimmed);
    if (parenMatch != null) {
      final p1 = parenMatch.group(1)?.trim() ?? '';
      final p2 = parenMatch.group(2)?.trim() ?? '';
      if (_containsTamil(p2)) return (english: p1, tamil: p2);
      if (_containsTamil(p1)) return (english: p2, tamil: p1);
      return (english: p1, tamil: p2);
    }

    // Slash pattern: English / Tamil
    if (trimmed.contains('/')) {
      final parts = trimmed.split('/');
      if (parts.length >= 2) {
        final p1 = parts[0].trim();
        final p2 = parts[1].trim();
        if (_containsTamil(p2)) return (english: p1, tamil: p2);
        if (_containsTamil(p1)) return (english: p2, tamil: p1);
        return (english: p1, tamil: p2);
      }
    }

    // Hyphen pattern: English - Tamil
    if (trimmed.contains(' - ')) {
      final parts = trimmed.split(' - ');
      if (parts.length >= 2) {
        final p1 = parts[0].trim();
        final p2 = parts[1].trim();
        if (_containsTamil(p2)) return (english: p1, tamil: p2);
        if (_containsTamil(p1)) return (english: p2, tamil: p1);
        return (english: p1, tamil: p2);
      }
    }

    // Raw string: if it contains Tamil, treat as is, otherwise English
    if (_containsTamil(trimmed)) {
      return (english: '', tamil: trimmed);
    }
    return (english: trimmed, tamil: '');
  }

  /// Formats the employee name for storage and display.
  /// If [bilingual] is true and [tamil] is non-empty, produces `English (Tamil)`.
  /// Otherwise produces clean [english] (or [tamil] if english is empty).
  static String formatBilingualName(
    String english,
    String tamil, {
    bool bilingual = true,
  }) {
    final eng = english.trim();
    final tam = tamil.trim();

    if (bilingual && tam.isNotEmpty) {
      if (eng.isEmpty) return tam;
      return '$eng ($tam)';
    }
    return eng.isNotEmpty ? eng : tam;
  }

  /// Returns 1-4 common Tamil candidate suggestions for a given English text.
  static List<String> getSuggestions(String text) {
    final raw = text.trim();
    if (raw.isEmpty) return const [];

    final set = <String>{};
    final primary = transliterate(raw);
    if (primary.isNotEmpty) {
      set.add(primary);
    }

    final lower = raw.toLowerCase();
    // Common alternative endings in Tamil names:
    // e.g. -an vs -am, -i vs -ee, -u vs -oo
    if (lower.endsWith('an') && lower.length > 3) {
      final alt = transliterate('${raw.substring(0, raw.length - 2)}am');
      if (alt.isNotEmpty) set.add(alt);
    }
    if (lower.endsWith('am') && lower.length > 3) {
      final alt = transliterate('${raw.substring(0, raw.length - 2)}an');
      if (alt.isNotEmpty) set.add(alt);
    }
    if (lower.endsWith('i') && lower.length > 2) {
      final alt = transliterate('${raw.substring(0, raw.length - 1)}ee');
      if (alt.isNotEmpty) set.add(alt);
    }
    if (lower.contains('th') && !lower.contains('thth')) {
      final alt = transliterate(raw.replaceAll('th', 'thth'));
      if (alt.isNotEmpty) set.add(alt);
    }

    return set.toList();
  }

  static bool _containsTamil(String text) {
    return text.runes.any((rune) => rune >= 0x0B80 && rune <= 0x0BFF);
  }

  /// Formats [rawName] for presentation according to [mode].
  ///
  /// - [WorkerNameDisplayMode.tamil]: returns Tamil name if present, otherwise English fallback.
  /// - [WorkerNameDisplayMode.english]: returns English name if present, otherwise Tamil fallback.
  /// - [WorkerNameDisplayMode.both]: returns `English (Tamil)` if both exist, otherwise raw.
  static String formatForDisplay(
    String rawName, {
    WorkerNameDisplayMode mode = WorkerNameDisplayMode.tamil,
  }) {
    final parsed = parseBilingualName(rawName);
    switch (mode) {
      case WorkerNameDisplayMode.tamil:
        return parsed.tamil.isNotEmpty
            ? parsed.tamil
            : (parsed.english.isNotEmpty ? parsed.english : rawName);
      case WorkerNameDisplayMode.english:
        return parsed.english.isNotEmpty
            ? parsed.english
            : (parsed.tamil.isNotEmpty ? parsed.tamil : rawName);
      case WorkerNameDisplayMode.both:
        if (parsed.english.isNotEmpty && parsed.tamil.isNotEmpty) {
          return '${parsed.english} (${parsed.tamil})';
        }
        return rawName;
    }
  }

  /// Checks if [rawName] matches [query] in English, Tamil, or via transliteration.
  static bool matchesWorkerName(String rawName, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;

    // Direct substring on stored name (handles 'Muthu (முத்து)')
    if (rawName.toLowerCase().contains(q)) return true;

    final parsed = parseBilingualName(rawName);
    if (parsed.english.toLowerCase().contains(q)) return true;
    if (parsed.tamil.contains(query.trim())) return true;

    // Transliterate query if user typed English to match Tamil-only records
    final transliteratedQ = transliterate(query.trim());
    if (transliteratedQ.isNotEmpty && parsed.tamil.contains(transliteratedQ)) {
      return true;
    }

    return false;
  }
}

/// Display mode preference for worker names in UI grids & lists.
enum WorkerNameDisplayMode {
  tamil,
  english,
  both,
}


