import 'package:flutter/material.dart';
import 'package:sudoku_app/games/freecell/freecell_screen.dart';
import 'package:sudoku_app/games/game_definition.dart';
import 'package:sudoku_app/games/sudoku/ui/home_menu.dart';

/// Every game in the app, in picker order. Adding a game = add an entry here.
final List<GameDefinition> kGames = [
  GameDefinition(
    id: 'sudoku',
    name: 'Sudoku',
    tagline: 'Daily puzzles, challenges & friends',
    icon: Icons.grid_on,
    color: Colors.indigo,
    buildHome: (_) => const HomeMenu(),
  ),
  GameDefinition(
    id: 'freecell',
    name: 'FreeCell',
    tagline: 'Classic numbered deals',
    icon: Icons.style,
    color: Colors.green,
    buildHome: (_) => const FreeCellScreen(),
  ),
];
