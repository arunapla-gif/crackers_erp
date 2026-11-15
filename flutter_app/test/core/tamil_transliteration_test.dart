import 'package:flutter_test/flutter_test.dart';
import 'package:crackers_erp/core/utils/tamil_transliteration.dart';

void main() {
  group('TamilTransliteration', () {
    test('transliterates common Tamil factory names accurately', () {
      expect(TamilTransliteration.transliterate('Muthu'), equals('முத்து'));
      expect(TamilTransliteration.transliterate('Murugan'), equals('முருகன்'));
      expect(TamilTransliteration.transliterate('Kaliappan'), equals('காளியப்பன்'));
      expect(TamilTransliteration.transliterate('Selvi'), equals('செல்வி'));
      expect(TamilTransliteration.transliterate('Kumar'), equals('குமார்'));
      expect(TamilTransliteration.transliterate('Suresh'), equals('சுரேஷ்'));
      expect(TamilTransliteration.transliterate('Karthik'), equals('கார்த்திக்'));
      expect(TamilTransliteration.transliterate('Ramasamy'), equals('ராமசாமி'));
      expect(TamilTransliteration.transliterate('Lakshmi'), equals('லட்சுமி'));
      expect(TamilTransliteration.transliterate('Anbu'), equals('அன்பு'));
      expect(TamilTransliteration.transliterate('Marimuthu'), equals('மாரிமுத்து'));
      expect(TamilTransliteration.transliterate('Ganesh'), equals('கணேஷ்'));
      expect(TamilTransliteration.transliterate('Pandian'), equals('பாண்டியன்'));
      expect(TamilTransliteration.transliterate('Arumugam'), equals('ஆறுமுகம்'));
      expect(TamilTransliteration.transliterate('Praveen'), equals('பிரவீன்'));
      expect(TamilTransliteration.transliterate('Dhanapal'), equals('தனபால்'));
      expect(TamilTransliteration.transliterate('Pechiammal'), equals('பேச்சியம்மாள்'));
      expect(TamilTransliteration.transliterate('Madasamy'), equals('மாடசாமி'));
    });

    test('handles compound names with suffixes', () {
      expect(TamilTransliteration.transliterate('Muthukumar'), equals('முத்துகுமார்'));
      expect(TamilTransliteration.transliterate('Arunkumar'), equals('அருண்குமார்'));
      expect(TamilTransliteration.transliterate('Velmurugan'), equals('வேல்முருகன்'));
      expect(TamilTransliteration.transliterate('Muthuraj'), equals('முத்துராஜ்'));
      expect(TamilTransliteration.transliterate('Selvaraj'), equals('செல்வராஜ்'));
    });

    test('transliterates multi-word names', () {
      expect(
        TamilTransliteration.transliterate('Muthu Kumar'),
        equals('முத்து குமார்'),
      );
      expect(
        TamilTransliteration.transliterate('Ramasamy Pandian'),
        equals('ராமசாமி பாண்டியன்'),
      );
    });

    test('parseBilingualName handles various formats', () {
      final p1 = TamilTransliteration.parseBilingualName('Muthu (முத்து)');
      expect(p1.english, equals('Muthu'));
      expect(p1.tamil, equals('முத்து'));

      final p2 = TamilTransliteration.parseBilingualName('Kaliappan / காளியப்பன்');
      expect(p2.english, equals('Kaliappan'));
      expect(p2.tamil, equals('காளியப்பன்'));

      final p3 = TamilTransliteration.parseBilingualName('Murugan');
      expect(p3.english, equals('Murugan'));
      expect(p3.tamil, equals(''));

      final p4 = TamilTransliteration.parseBilingualName('செல்வி');
      expect(p4.english, equals(''));
      expect(p4.tamil, equals('செல்வி'));
    });

    test('formatForDisplay renders according to WorkerNameDisplayMode', () {
      const raw = 'Muthu (முத்து)';
      expect(
        TamilTransliteration.formatForDisplay(
          raw,
          mode: WorkerNameDisplayMode.tamil,
        ),
        equals('முத்து'),
      );
      expect(
        TamilTransliteration.formatForDisplay(
          raw,
          mode: WorkerNameDisplayMode.english,
        ),
        equals('Muthu'),
      );
      expect(
        TamilTransliteration.formatForDisplay(
          raw,
          mode: WorkerNameDisplayMode.both,
        ),
        equals('Muthu (முத்து)'),
      );

      // Fallback if Tamil is missing
      expect(
        TamilTransliteration.formatForDisplay(
          'John',
          mode: WorkerNameDisplayMode.tamil,
        ),
        equals('John'),
      );
    });

    test('matchesWorkerName supports English, Tamil and transliterated queries', () {
      const raw = 'Muthu (முத்து)';
      expect(TamilTransliteration.matchesWorkerName(raw, 'muthu'), isTrue);
      expect(TamilTransliteration.matchesWorkerName(raw, 'MUTHU'), isTrue);
      expect(TamilTransliteration.matchesWorkerName(raw, 'முத்து'), isTrue);
      expect(TamilTransliteration.matchesWorkerName(raw, 'kaliappan'), isFalse);

      // Search in English matches even if worker was stored Tamil-only
      expect(TamilTransliteration.matchesWorkerName('முத்து', 'muthu'), isTrue);
    });

    test('formatBilingualName combines English and Tamil properly', () {
      expect(
        TamilTransliteration.formatBilingualName('Muthu', 'முத்து', bilingual: true),
        equals('Muthu (முத்து)'),
      );
      expect(
        TamilTransliteration.formatBilingualName('Muthu', 'முத்து', bilingual: false),
        equals('Muthu'),
      );
      expect(
        TamilTransliteration.formatBilingualName('Muthu', '', bilingual: true),
        equals('Muthu'),
      );
    });

    test('getSuggestions returns non-empty list of candidate Tamil spellings', () {
      final suggestions = TamilTransliteration.getSuggestions('Muthu');
      expect(suggestions, isNotEmpty);
      expect(suggestions.contains('முத்து'), isTrue);
    });
  });
}

