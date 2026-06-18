import 'package:flutter/material.dart';

/// Offline "Learn" content (issue #49). Written originally for this app and
/// structured after Sudopedia's index; each section links to the matching
/// Sudopedia page as a reference. Sudopedia's own text is GNU FDL, so nothing
/// here is copied from it — these are our own explanations of the same ideas.
///
/// Article [body] uses a tiny markup the renderer understands:
///   "## "  → sub-heading        "- "   → bullet list item
///   ``` fences ``` → monospace example block     blank line → new paragraph

class TutorialArticle {
  final String title;
  final String body;
  const TutorialArticle(this.title, this.body);
}

class TutorialSection {
  final String title;
  final String blurb;
  final IconData icon;
  final String referenceUrl; // the matching Sudopedia page
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

const List<TutorialSection> tutorialSections = [
  // ---- Introduction -------------------------------------------------------
  TutorialSection(
    title: 'Introduction',
    blurb: 'What Sudoku is and the single rule behind it.',
    icon: Icons.flag_outlined,
    referenceUrl: 'https://www.sudopedia.org/wiki/Introduction',
    articles: [
      TutorialArticle('What is Sudoku?', '''
Sudoku is a logic puzzle played on a 9×9 grid. The grid is divided into nine 3×3 boxes. Some cells start already filled in — these are the "givens" or clues.

Your job is to fill every empty cell with a digit from 1 to 9 so that one rule holds everywhere:

## The one rule
Each digit 1–9 appears exactly once in every row, every column, and every 3×3 box.

That's it. There is no arithmetic and no trivia — Sudoku is pure deduction. A proper Sudoku has exactly one solution, and you can always reach it by logic alone, without guessing.

## How to win
Fill the whole grid so the rule holds. When you place a digit you can usually prove it belongs there because every other option is blocked by a digit already in its row, column, or box. The rest of this guide teaches you how to find those proofs.''',
      ),
    ],
  ),

  // ---- Diagrams and Notations --------------------------------------------
  TutorialSection(
    title: 'Diagrams and Notations',
    blurb: 'How players name cells, boxes, and candidates.',
    icon: Icons.grid_on_outlined,
    referenceUrl: 'https://www.sudopedia.org/wiki/Diagrams_and_Notations',
    articles: [
      TutorialArticle('Naming cells, rows, columns, and boxes', '''
To talk about a puzzle, players need names for its parts.

## Rows and columns
Rows are numbered 1–9 from top to bottom; columns 1–9 from left to right. A cell is named by its row and column as RnCn. So R1C1 is the top-left cell and R9C9 is the bottom-right one. R6C4 means row 6, column 4.

## Boxes
The nine 3×3 boxes are numbered 1–9, left to right then top to bottom:

```
 1 | 2 | 3
---+---+---
 4 | 5 | 6
---+---+---
 7 | 8 | 9
```

So box 1 is the top-left 3×3, box 5 is the center, box 9 is the bottom-right.

## Givens and candidates
The digits printed at the start are "givens" — they never change. A small digit you pencil into an empty cell is a "candidate" (or pencil mark): a value that could still go there. As you solve, you remove candidates that become impossible until only the right one is left.''',
      ),
    ],
  ),

  // ---- Terminology --------------------------------------------------------
  TutorialSection(
    title: 'Terminology',
    blurb: 'The words solvers use, defined plainly.',
    icon: Icons.menu_book_outlined,
    referenceUrl: 'https://www.sudopedia.org/wiki/Terminology',
    articles: [
      TutorialArticle('Common terms', '''
## Cell
One of the 81 squares. It holds a single digit when solved.

## Unit (house)
Any row, column, or 3×3 box — a group of nine cells that must contain each digit 1–9 exactly once. "House" and "unit" mean the same thing.

## Peer
Two cells are peers if they share a unit (same row, column, or box). A cell has 20 peers. A digit can never repeat among peers.

## Given (clue)
A digit filled in from the start. Givens are fixed.

## Candidate
A digit that could still legally go in an empty cell — what you'd write as a pencil mark.

## Single
A cell that has only one possible digit left. Placing it is the most basic move.

## Naked vs. hidden
"Naked" describes what a cell shows directly — e.g. a naked single is a cell with only one candidate. "Hidden" describes a digit that has only one home in a unit even though that cell has other candidates too — a hidden single.

## Subset (pair, triple, quad)
A group of N cells in one unit that together hold only N candidates. Those candidates are locked to those cells and can be cleared from the rest of the unit.

## Elimination
Removing a candidate from a cell because logic rules it out. Many techniques don't place a digit — they just eliminate, which unlocks a later placement.''',
      ),
    ],
  ),

  // ---- Solving Techniques -------------------------------------------------
  TutorialSection(
    title: 'Solving Techniques',
    blurb: 'From scanning to subsets — how to make progress.',
    icon: Icons.lightbulb_outline,
    referenceUrl: 'https://www.sudopedia.org/wiki/Solving_Technique',
    articles: [
      TutorialArticle('Scanning (cross-hatching)', '''
The first thing to try, and the easiest to see.

Pick a digit, say 7. Look at a box that doesn't have a 7 yet. For each empty cell in that box, ask: does a 7 already sit in that cell's row or column? If so, a 7 can't go there. If only one empty cell in the box survives, that cell must be 7.

This "scan the rows and columns through a box" move is called cross-hatching, and it finds most of the moves in easy and medium puzzles.''',
      ),
      TutorialArticle('Naked & hidden singles', '''
## Naked single
An empty cell whose row, column, and box together already use eight different digits has only one digit left — so that digit goes there. The cell "nakedly" shows its single candidate.

## Hidden single
Within a single unit (row, column, or box), a digit may have only one cell where it can still go — even if that cell has other candidates. The digit is "hidden" among them, but it's forced. Scanning (above) is how you spot hidden singles in a box.

Singles are the bread and butter of solving — this app's Hint button looks for them first.''',
      ),
      TutorialArticle('Locked candidates (pointing & claiming)', '''
Sometimes a digit can't be placed yet, but you can still narrow where it lives — and that removes candidates elsewhere.

## Pointing
If, within a box, a digit's only remaining candidates all lie in one row (or one column), then that digit must come from this box along that line. So it can be removed from the rest of that row (or column) outside the box.

## Claiming (box-line reduction)
The mirror image: if a digit in a row (or column) only has candidates inside one box, the digit must be in that box for that line — so remove it from the rest of the box.

Neither move places a digit; both delete candidates, which often frees up a single afterwards.''',
      ),
      TutorialArticle('Naked & hidden subsets', '''
## Naked pair / triple
If two cells in a unit each hold only the same two candidates (say 3 and 7), those two digits are locked to those two cells. They can't appear anywhere else in the unit, so remove 3 and 7 from the unit's other cells. Three cells sharing only three candidates form a naked triple, and so on.

## Hidden pair / triple
If two digits can only go in the same two cells of a unit (even though those cells carry other candidates), those two cells belong to that pair — so every other candidate can be removed from them.

Subsets are how you break into harder puzzles once singles dry up.''',
      ),
      TutorialArticle('A taste of advanced: X-Wing', '''
When subsets aren't enough, patterns that span two units help.

X-Wing (on a digit, say 5): find two rows in which 5 has candidates in only the same two columns. Those four cells form a rectangle. Because 5 must take one cell in each of those rows, it will occupy two opposite corners — which means 5 can be removed from those two columns everywhere else.

The same pattern works with rows and columns swapped. X-Wing, and its cousins Swordfish and XY-Wing, are the gateway to expert puzzles. This app's hints stop at the basics above; these are here so you know what's next.''',
      ),
    ],
  ),

  // ---- Guides -------------------------------------------------------------
  TutorialSection(
    title: 'Guides',
    blurb: 'How to actually approach a puzzle.',
    icon: Icons.route_outlined,
    referenceUrl: 'https://www.sudopedia.org/wiki/Sudoku_Guides',
    articles: [
      TutorialArticle('A beginner walkthrough', '''
A reliable order of attack:

## 1. Scan for easy placements
Go digit by digit (1, then 2, …) and cross-hatch each box. Fill every hidden single you find. Repeat — each placement can create new ones.

## 2. Look for naked singles
Check cells that are nearly surrounded. A cell whose peers already use eight digits is forced.

## 3. Pencil in candidates
When obvious moves run out, mark the remaining candidates in each empty cell (the Auto button fills them all). Now you can see subsets and locked candidates.

## 4. Eliminate, then place
Use locked candidates and naked/hidden pairs to remove candidates. Every elimination may expose a new single.

## Tips
- Never guess. A proper Sudoku is solvable by logic; if you're stuck, there's a deduction you haven't spotted — use a hint.
- Keep pencil marks tidy; remove a candidate from peers the moment you place a digit (the app can do this for you).
- Work the most-constrained units first (rows/columns/boxes that are nearly full).''',
      ),
    ],
  ),

  // ---- Sudoku variations --------------------------------------------------
  TutorialSection(
    title: 'Sudoku Variations',
    blurb: 'Popular twists on the classic 9×9 grid.',
    icon: Icons.extension_outlined,
    referenceUrl: 'https://www.sudopedia.org/wiki/Sudoku_Variations',
    articles: [
      TutorialArticle('Popular variants', '''
The classic rule (1–9 once per row, column, and box) can be extended in many ways. A few you'll meet often:

## Diagonal (X) Sudoku
The two main diagonals must also contain 1–9 exactly once — two extra units to satisfy.

## Killer Sudoku
No givens. Instead, dotted "cages" each show a target sum, and digits within a cage can't repeat. Combines logic with light arithmetic.

## Jigsaw (irregular)
The nine boxes aren't 3×3 squares but irregular nine-cell shapes; the row/column rules are unchanged.

## Hyper / Windoku
Four extra shaded 3×3 regions inside the grid must each hold 1–9, adding constraints.

## Samurai
Five overlapping 9×9 grids sharing corner boxes — solved together.

## Smaller grids
4×4 (digits 1–4) and 6×6 are gentle introductions for new or younger players.

This app plays the classic 9×9 game; variations are here for reference.''',
      ),
    ],
  ),
];
