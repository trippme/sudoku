import 'package:flutter/material.dart';
import 'package:sudoku_app/games/game_definition.dart';
import 'package:sudoku_app/games/registry.dart';

/// Top-level screen: pick which game to play.
class GamePicker extends StatelessWidget {
  final List<GameDefinition> games;
  const GamePicker({super.key, List<GameDefinition>? games})
      : games = games ?? const [];

  @override
  Widget build(BuildContext context) {
    final list = games.isEmpty ? kGames : games;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 12),
                Text(
                  "Tripp's Games",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 28),
                for (final g in list) _GameCard(game: g),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final GameDefinition game;
  const _GameCard({required this.game});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('game-${game.id}'),
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: game.buildHome)),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: game.color.withValues(alpha: 0.15),
                child: Icon(game.icon, color: game.color, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(game.name,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(game.tagline),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
