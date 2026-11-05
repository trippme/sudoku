import 'package:flutter/material.dart';

/// One playable game in the Tripp's Games collection. Each game lives in
/// `lib/games/<id>/` and registers itself in [kGames] (see `registry.dart`).
///
/// [id] is also the namespace for the game's persisted data and, later, its
/// leaderboard/challenge scope on the backend. Sudoku predates the registry,
/// so its stored keys stay un-prefixed; every new game must prefix its keys
/// with `<id>.`.
class GameDefinition {
  final String id;
  final String name;
  final String tagline;
  final IconData icon;
  final Color color;

  /// Builds the game's own home screen (resume / new game / stats / etc.).
  final WidgetBuilder buildHome;

  const GameDefinition({
    required this.id,
    required this.name,
    required this.tagline,
    required this.icon,
    required this.color,
    required this.buildHome,
  });
}
