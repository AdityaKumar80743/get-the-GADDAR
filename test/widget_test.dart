import 'package:flutter_test/flutter_test.dart';
import 'package:get_the_gaddar/data/word_packs.dart';

void main() {
  test('GaddarWordPacks contains valid categories and words', () {
    expect(GaddarWordPacks.allCategories, isNotEmpty);
    expect(GaddarWordPacks.builtInPacks.containsKey('Movies'), isTrue);
    expect(GaddarWordPacks.builtInPacks['Movies']!.length, greaterThan(0));
  });
}
