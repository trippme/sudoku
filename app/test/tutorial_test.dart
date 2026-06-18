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
        final text = a.content.whereType<String>().join(' ');
        expect(text.trim().length, greaterThan(50),
            reason: '"${a.title}" should have real content');
      }
    }
  });

  test('every diagram is a well-formed 9×9 board', () {
    // Reading tutorialSections already runs every diagram() call, so a bad cell
    // name would have thrown by now; here we just check the boards' shape.
    var count = 0;
    for (final s in tutorialSections) {
      for (final a in s.articles) {
        for (final d in a.content.whereType<GridDiagram>()) {
          expect(d.flat.length, 81, reason: 'a diagram in "${a.title}"');
          count++;
        }
      }
    }
    expect(count, greaterThan(5)); // techniques etc. are illustrated
  });
}
