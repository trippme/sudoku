import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku_app/tutorial/tutorial_content.dart';

void main() {
  test('the Learn index covers the expected sections (issue #49)', () {
    final titles = tutorialSections.map((s) => s.title).toList();
    expect(
      titles,
      containsAll(<String>[
        'Introduction',
        'Diagrams and Notations',
        'Terminology',
        'Solving Techniques',
        'Guides',
        'Sudoku Variations',
      ]),
    );
  });

  test('every section has offline content and a Sudopedia reference link', () {
    for (final s in tutorialSections) {
      expect(s.referenceUrl, startsWith('https://www.sudopedia.org/'),
          reason: '${s.title} should reference Sudopedia');
      expect(s.articles, isNotEmpty, reason: '${s.title} has no articles');
      for (final a in s.articles) {
        expect(a.title, isNotEmpty);
        expect(a.body.trim().length, greaterThan(50),
            reason: '"${a.title}" should have real content');
      }
    }
  });
}
