import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'main.dart';

class HistoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('History'),
      ),
      body: Consumer<GameProvider>(
        builder: (context, gameProvider, child) {
          return ListView.builder(
            itemCount: gameProvider.history.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text('Game ${index + 1}: ${gameProvider.history[index]}'),
              );
            },
          );
        },
      ),
    );
  }
}
