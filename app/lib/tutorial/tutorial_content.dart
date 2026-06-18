import 'package:flutter/material.dart';

/// Offline "Learn" content (issue #49). Original prose written for this app and
/// structured after Sudopedia (whose own text is GNU FDL, so nothing is copied);
/// each section links to the matching Sudopedia page as a reference.
///
/// An article's [content] is a list of blocks, each either:
///   • a String of light markup — "## " heading, "- " bullet, ``` fenced
///     monospace, blank line = new paragraph; or
///   • a [GridDiagram] — a small example board with highlighted cells and
///     optional candidate marks, built with the [diagram] helper.

// ---- Diagram model ---------------------------------------------------------

enum DiagramHi { none, region, focus, target, eliminate }

class GridDiagram {
  final String flat; // 81 chars, '.' = empty, '1'-'9' = a digit
  final String? caption;
  final Map<int, DiagramHi> hi; // cell index → highlight role
  final Map<int, String> marks; // cell index → small candidate text
  const GridDiagram(this.flat,
      {this.caption, this.hi = const {}, this.marks = const {}});
}

int _cellIndex(String token) {
  final m = RegExp(r'[Rr](\d)[Cc](\d)').firstMatch(token)!;
  return (int.parse(m.group(1)!) - 1) * 9 + (int.parse(m.group(2)!) - 1);
}

List<int> _cells(String spec) => spec.trim().isEmpty
    ? const []
    : spec.trim().split(RegExp(r'\s+')).map(_cellIndex).toList();

/// Authoring helper. [grid] is 9 lines of 9 chars ('.' empty); the role params
/// take space-separated cell names ("R4C5 R4C6"); [marks] maps a cell name to
/// the small candidate text shown in it.
GridDiagram diagram(
  String grid, {
  String? caption,
  String region = '',
  String focus = '',
  String target = '',
  String elim = '',
  Map<String, String> marks = const {},
}) {
  final flat = grid.replaceAll(RegExp(r'\s'), '');
  final hi = <int, DiagramHi>{};
  for (final i in _cells(region)) {
    hi[i] = DiagramHi.region;
  }
  for (final i in _cells(focus)) {
    hi[i] = DiagramHi.focus;
  }
  for (final i in _cells(elim)) {
    hi[i] = DiagramHi.eliminate;
  }
  for (final i in _cells(target)) {
    hi[i] = DiagramHi.target; // wins on overlap
  }
  final pm = {for (final e in marks.entries) _cellIndex(e.key): e.value};
  return GridDiagram(flat, caption: caption, hi: hi, marks: pm);
}

// ---- Article / section model ----------------------------------------------

class TutorialArticle {
  final String title;
  final List<Object> content; // String | GridDiagram
  const TutorialArticle(this.title, this.content);
}

class TutorialSection {
  final String title;
  final String blurb;
  final IconData icon;
  final String referenceUrl; // matching Sudopedia page
  final List<TutorialArticle> articles;
  const TutorialSection({
    required this.title,
    required this.blurb,
    required this.icon,
    required this.referenceUrl,
    required this.articles,
  });
}

const String sudopediaHome = 'https://www.sudopedia.org/';

// A mostly-empty grid, the base for candidate-mark illustrations.
const String _empty =
    '.................................................................................';

final List<TutorialSection> tutorialSections = [
  // ======================================================================
  TutorialSection(
    title: 'Introduction',
    blurb: 'What Sudoku is and the single rule behind it.',
    icon: Icons.flag_outlined,
    referenceUrl: 'https://www.sudopedia.org/wiki/Introduction',
    articles: [
      TutorialArticle('What is Sudoku?', [
        '''
Sudoku is a logic puzzle on a 9×9 grid divided into nine 3×3 boxes. Some cells start filled in — the "givens" or clues. You fill the rest so that one rule holds everywhere.

## The one rule
Each digit 1–9 appears exactly once in every row, every column, and every 3×3 box.

That's the whole game. There is no arithmetic and no trivia — Sudoku is pure deduction. A proper Sudoku has exactly one solution, reachable by logic alone, with no guessing.''',
        diagram(
          '''
53..7....
6..195...
.98....6.
8...6...3
4..8.3..1
7...2...6
.6....28.
...419..5
....8..79''',
          caption:
              'A classic puzzle. Highlighted: row 1, column 1, and box 1 — the '
              'three kinds of "unit" that must each hold 1–9 exactly once.',
          region:
              'R1C1 R1C2 R1C3 R1C4 R1C5 R1C6 R1C7 R1C8 R1C9 R2C1 R3C1 R4C1 R5C1 R6C1 R7C1 R8C1 R9C1 R2C2 R2C3 R3C2 R3C3',
        ),
        '''
## How you win
When you place a digit you can almost always prove it belongs there: every other option is blocked by a digit already in its row, column, or box. The rest of this guide is about finding those proofs.''',
      ]),
    ],
  ),

  // ======================================================================
  TutorialSection(
    title: 'Diagrams and Notations',
    blurb: 'How players name cells, boxes, and candidates.',
    icon: Icons.grid_on_outlined,
    referenceUrl: 'https://www.sudopedia.org/wiki/Diagrams_and_Notations',
    articles: [
      TutorialArticle('Naming the grid', [
        '''
To talk about a puzzle, you need names for its parts.

## Rows and columns
Rows are numbered 1–9 top to bottom; columns 1–9 left to right. A cell is named RnCn — its row then its column. R1C1 is top-left, R9C9 is bottom-right, R6C4 is row 6, column 4.''',
        diagram(
          _empty,
          caption: 'R1C1 (top-left) and R6C4, named by their row and column.',
          target: 'R1C1 R6C4',
          marks: {'R1C1': 'R1C1', 'R6C4': 'R6C4'},
        ),
        '''
## Boxes
The nine 3×3 boxes are numbered 1–9, left to right then top to bottom:

```
 1 | 2 | 3
---+---+---
 4 | 5 | 6
---+---+---
 7 | 8 | 9
```

So box 1 is top-left, box 5 is the centre, box 9 is bottom-right.

## Givens and candidates
The digits printed at the start are "givens" — they never change. A small digit you pencil into an empty cell is a "candidate": a value that could still go there. Solving is mostly removing candidates that become impossible until one is left.''',
        diagram(
          _empty,
          caption: 'Candidates (pencil marks): R5C5 still allows 2, 5, or 8.',
          focus: 'R5C5',
          marks: {'R5C5': '258'},
        ),
      ]),
    ],
  ),

  // ======================================================================
  TutorialSection(
    title: 'Terminology',
    blurb: 'The vocabulary solvers use, defined plainly.',
    icon: Icons.menu_book_outlined,
    referenceUrl: 'https://www.sudopedia.org/wiki/Terminology',
    articles: [
      TutorialArticle('Parts of the grid', [
        '''
## Grid
The whole 9×9 playing field — 81 cells.

## Cell
One of the 81 squares; holds a single digit when solved.

## Box (block)
One of the nine 3×3 regions. Also called a block.

## Row / Column
A horizontal / vertical line of nine cells.

## Unit (house)
Any row, column, or box — a group of nine cells that must contain each digit 1–9 exactly once. "Unit" and "house" are interchangeable.

## Band / Stack
A band is three boxes in a horizontal row (boxes 1–3, 4–6, or 7–9). A stack is three boxes in a vertical column (boxes 1·4·7, etc.).

## Chute
A band or a stack — any line of three boxes.

## Peer
A cell that shares a unit with another. Every cell has 20 peers (8 in its row + 8 in its column + 4 more in its box). A digit can never repeat among peers.''',
        diagram(
          _empty,
          caption: 'The 20 peers of R5C5 — its row, column, and box.',
          target: 'R5C5',
          region:
              'R5C1 R5C2 R5C3 R5C4 R5C6 R5C7 R5C8 R5C9 R1C5 R2C5 R3C5 R4C5 R6C5 R7C5 R8C5 R9C5 R4C4 R4C6 R6C4 R6C6',
        ),
      ]),
      TutorialArticle('Givens, candidates, singles', [
        '''
## Given (clue)
A digit filled in from the start. Givens are fixed.

## Candidate
A digit that could still legally go in an empty cell — a pencil mark.

## Bi-value cell
A cell with exactly two candidates. Bi-value cells drive many advanced techniques.

## Single
A cell that resolves to one digit.

## Naked single
A cell with only one candidate left — its single value is shown openly.''',
        diagram(_empty,
            caption: 'A naked single: R3C3 has only one candidate, 4.',
            target: 'R3C3',
            marks: {'R3C3': '4'}),
        '''
## Hidden single
A digit that can go in only one cell of a unit, even though that cell has other candidates too — the digit is "hidden" among them but still forced.''',
      ]),
      TutorialArticle('Solving vocabulary', [
        '''
## Elimination
Removing a candidate from a cell because logic rules it out. Many techniques don't place a digit — they only eliminate, which unlocks a later single.

## Locked candidate
A digit confined within a box to a single row or column (or vice-versa), letting you eliminate it elsewhere. Two forms: pointing and claiming.

## Subset (pair / triple / quad)
N cells in one unit that together hold only N candidates. Those candidates are locked to those cells and can be cleared from the rest of the unit. Naked subsets show the candidates directly; hidden ones bury them among extras.

## Conjugate pair
A unit where a digit has exactly two possible cells. One of the two must be that digit — the backbone of colouring and chains.

## Fish (X-Wing, Swordfish, …)
A family of row/column patterns on a single digit. X-Wing uses 2 lines, Swordfish 3.

## Chain
A linked sequence of conjugate pairs / bi-value cells used to prove an elimination far across the grid.

## Unique rectangle (BUG)
Patterns that exploit the fact that a proper puzzle has exactly one solution: a "deadly pattern" that would allow two solutions can't occur, which forces an elimination.''',
      ]),
    ],
  ),

  // ======================================================================
  TutorialSection(
    title: 'Solving Techniques',
    blurb: 'From scanning to subsets — how to make progress.',
    icon: Icons.lightbulb_outline,
    referenceUrl: 'https://www.sudopedia.org/wiki/Solving_Technique',
    articles: [
      TutorialArticle('Scanning (cross-hatching)', [
        '''
The first thing to try, and the easiest to see.

Pick a digit, say 7. Look at a box with no 7 yet. For each empty cell in that box ask: is there already a 7 in that cell's row or column? If so, 7 can't go there. If only one cell in the box survives, it must be 7.''',
        diagram(
          '''
.......7.
....7....
.........
.........
.........
.........
.........
..7......
.........''',
          caption:
              'Looking for 7 in box 1. The 7s in rows 2 & 8 and column 8/3 rule '
              'out every cell but R1C1 — so R1C1 = 7.',
          region: 'R1C1 R1C2 R1C3 R2C1 R2C2 R2C3 R3C1 R3C2 R3C3',
          target: 'R1C1',
          focus: 'R1C8 R2C5 R8C3',
        ),
        '''
This "scan rows and columns through a box" move — cross-hatching — finds most moves in easy and medium puzzles.''',
      ]),
      TutorialArticle('Naked & hidden singles', [
        '''
## Naked single
A cell whose row, column, and box already use eight different digits has only one left — place it.''',
        diagram(_empty,
            caption: 'R5C5 can only be 6 — every other digit is taken by a peer.',
            target: 'R5C5',
            marks: {'R5C5': '6'}),
        '''
## Hidden single
Within one unit a digit may have only one possible cell, even if that cell shows other candidates. Scanning is how you find hidden singles in a box.''',
        diagram(_empty,
            caption:
                'In this row, 4 fits only in R1C7 (a hidden single) even though '
                'that cell could also be 8 or 9.',
            region:
                'R1C1 R1C2 R1C3 R1C4 R1C5 R1C6 R1C7 R1C8 R1C9',
            target: 'R1C7',
            marks: {'R1C1': '12', 'R1C4': '23', 'R1C7': '489', 'R1C9': '28'}),
        '''
Singles are the bread and butter of solving — this app's Hint button looks for them first, and offers the box-scan (hidden single) before the naked single.''',
      ]),
      TutorialArticle('Locked candidates: pointing', [
        '''
A digit can't be placed yet, but you can pin down where it lives — and that removes candidates elsewhere.

## Pointing
If a digit's only spots within a box all lie in one row (or column), the digit must come from this box along that line. So it can be removed from the rest of that row (or column) outside the box.''',
        diagram(_empty,
            caption:
                '3 in box 1 fits only in row 1 (R1C1, R1C3). So 3 is removed '
                'from the rest of row 1 — here R1C5 and R1C8.',
            focus: 'R1C1 R1C3',
            elim: 'R1C5 R1C8',
            marks: {'R1C1': '3', 'R1C3': '3', 'R1C5': 'x3', 'R1C8': 'x3'}),
      ]),
      TutorialArticle('Locked candidates: claiming', [
        '''
## Claiming (box–line reduction)
The mirror image of pointing. If a digit in a row (or column) has candidates inside only one box, the digit must be in that box for that line — so remove it from the rest of the box.''',
        diagram(_empty,
            caption:
                '5 in row 1 fits only inside box 1 (R1C1, R1C2). So 5 is removed '
                'from the rest of box 1 — R2C3 and R3C2.',
            focus: 'R1C1 R1C2',
            elim: 'R2C3 R3C2',
            marks: {'R1C1': '5', 'R1C2': '5', 'R2C3': 'x5', 'R3C2': 'x5'}),
        '''
Neither pointing nor claiming places a digit — both delete candidates, which usually frees a single soon after.''',
      ]),
      TutorialArticle('Naked subsets (pairs, triples)', [
        '''
## Naked pair
If two cells in a unit each hold only the same two candidates (say 3 and 7), those digits are locked to those two cells and can be removed from every other cell in the unit.''',
        diagram(_empty,
            caption:
                'R1C1 and R1C2 are a naked pair on {3,7}. Remove 3 and 7 from '
                'the rest of row 1 (R1C5, R1C8).',
            focus: 'R1C1 R1C2',
            elim: 'R1C5 R1C8',
            marks: {
              'R1C1': '37',
              'R1C2': '37',
              'R1C5': 'x379',
              'R1C8': 'x137'
            }),
        '''
## Naked triple
Three cells in a unit whose candidates together use only three digits (e.g. {2,5,8}, in any mix) form a naked triple — clear those three digits from the unit's other cells. Quads extend the idea to four.''',
      ]),
      TutorialArticle('Hidden subsets', [
        '''
## Hidden pair
If two digits can go in only the same two cells of a unit — even though those cells carry other candidates — those cells belong to the pair. Remove every other candidate from them.''',
        diagram(_empty,
            caption:
                '4 and 9 appear only in R1C1 and R1C2 of this row → a hidden '
                'pair. Strip the extras: both cells become {4,9}.',
            focus: 'R1C1 R1C2',
            region: 'R1C5 R1C8',
            marks: {
              'R1C1': '149',
              'R1C2': '249',
              'R1C5': '123',
              'R1C8': '1235'
            }),
        '''
Hidden triples and quads work the same way with three or four digits. Hidden subsets are harder to spot than naked ones because the digits are buried among other candidates.''',
      ]),
      TutorialArticle('A taste of advanced: X-Wing', [
        '''
When subsets run out, patterns that span two units help.

## X-Wing
On one digit, say 5: find two rows where 5's only candidates sit in the same two columns. The four cells form a rectangle. Since each row places its 5 in one of those columns, the 5s take two opposite corners — so 5 can be removed from those two columns everywhere else.''',
        diagram(_empty,
            caption:
                "5's candidates in rows 2 and 6 lie only in columns 3 and 7 (the "
                "corners). 5 can be eliminated from the rest of columns 3 and 7.",
            focus: 'R2C3 R2C7 R6C3 R6C7',
            elim: 'R4C3 R8C7',
            marks: {
              'R2C3': '5',
              'R2C7': '5',
              'R6C3': '5',
              'R6C7': '5',
              'R4C3': 'x5',
              'R8C7': 'x5'
            }),
        '''
The same pattern works with rows and columns swapped. X-Wing, Swordfish, and XY-Wing are the gateway to expert puzzles. This app's hints stop at the basics above; these are here so you know what comes next.''',
      ]),
    ],
  ),

  // ======================================================================
  TutorialSection(
    title: 'Guides',
    blurb: 'How to actually approach a puzzle.',
    icon: Icons.route_outlined,
    referenceUrl: 'https://www.sudopedia.org/wiki/Sudoku_Guides',
    articles: [
      TutorialArticle('A beginner walkthrough', [
        '''
A reliable order of attack:

## 1. Scan for easy placements
Go digit by digit (1, then 2, …) and cross-hatch each box. Fill every hidden single. Repeat — each placement can create new ones.

## 2. Look for naked singles
Check cells that are nearly surrounded. A cell whose peers already use eight digits is forced.

## 3. Pencil in candidates
When obvious moves run out, mark the remaining candidates in each empty cell (the Auto button fills them all). Now subsets and locked candidates become visible.

## 4. Eliminate, then place
Use locked candidates and naked/hidden subsets to remove candidates. Every elimination may expose a new single — go back to step 1.

## Tips
- Never guess. A proper Sudoku is solvable by logic; if you're stuck, there's a deduction you've missed — or use a hint.
- Keep pencil marks tidy: remove a candidate from peers the instant you place a digit (the app can do this for you).
- Work the most-constrained units first — rows, columns, and boxes that are nearly full.
- A wrong guess may not surface for many moves, which is why logic beats guessing.''',
      ]),
    ],
  ),

  // ======================================================================
  TutorialSection(
    title: 'Sudoku Variations',
    blurb: 'Popular twists on the classic 9×9 grid.',
    icon: Icons.extension_outlined,
    referenceUrl: 'https://www.sudopedia.org/wiki/Sudoku_Variations',
    articles: [
      TutorialArticle('Popular variants', [
        '''
The classic rule (1–9 once per row, column, and box) can be extended many ways.

## Diagonal (X) Sudoku
The two main diagonals must also contain 1–9 — two extra units.

## Killer Sudoku
No givens. Dotted "cages" each show a target sum, and digits within a cage can't repeat. Logic plus light arithmetic.

## Jigsaw (irregular)
The nine regions are irregular nine-cell shapes instead of 3×3 boxes; row/column rules are unchanged.

## Hyper / Windoku
Four extra shaded 3×3 regions inside the grid must each hold 1–9, adding constraints.

## Sudoku-X / Centerdot / Asterisk
Extra "special" cell groups that must also contain 1–9.

## Samurai
Five overlapping 9×9 grids sharing corner boxes, solved together.

## Smaller / larger grids
4×4 (digits 1–4) and 6×6 are gentle introductions; 16×16 (hexadoku) is a bigger challenge.

This app plays the classic 9×9 game; variations are here for reference.''',
      ]),
    ],
  ),
];
