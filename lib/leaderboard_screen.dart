import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'main.dart';

class LeaderboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Leaderboard'),
      ),
      body: Consumer<GameProvider>(
        builder: (context, gameProvider, child) {
          return ListView.builder(
            itemCount: gameProvider.highScores.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text('Rank ${index + 1}: ${gameProvider.highScores[index]}'),
              );
            },
          );
        },
      ),
    );
  }
}
