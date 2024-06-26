import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'history_screen.dart';
import 'leaderboard_screen.dart';

void main() {
  runApp(SnakeGame());
}

class SnakeGame extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => GameProvider(),
      child: MaterialApp(
        navigatorKey: navigatorKey,
        home: GameScreen(),
      ),
    );
  }
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class GameScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Snake Game'),
        actions: [
          IconButton(
            icon: Icon(Icons.leaderboard),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LeaderboardScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HistoryScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              Provider.of<GameProvider>(context, listen: false)._startGame();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<GameProvider>(
              builder: (context, gameProvider, child) {
                return GestureDetector(
                  onVerticalDragUpdate: (details) {
                    if (details.delta.dy > 0 && gameProvider.direction != Direction.up) {
                      gameProvider.changeDirection(Direction.down);
                    } else if (details.delta.dy < 0 && gameProvider.direction != Direction.down) {
                      gameProvider.changeDirection(Direction.up);
                    }
                  },
                  onHorizontalDragUpdate: (details) {
                    if (details.delta.dx > 0 && gameProvider.direction != Direction.left) {
                      gameProvider.changeDirection(Direction.right);
                    } else if (details.delta.dx < 0 && gameProvider.direction != Direction.right) {
                      gameProvider.changeDirection(Direction.left);
                    }
                  },
                  child: GridView.builder(
                    physics: NeverScrollableScrollPhysics(), // 禁止 GridView 滑动
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: gameProvider.gridSize,
                    ),
                    itemCount: gameProvider.gridSize * gameProvider.gridSize,
                    itemBuilder: (context, index) {
                      var x = index % gameProvider.gridSize;
                      var y = (index / gameProvider.gridSize).floor();
                      var isSnake = gameProvider.snake.contains(Point(x, y));
                      var isFood = gameProvider.food == Point(x, y);
                      return Container(
                        margin: EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          color: isSnake ? Colors.green : (isFood ? Colors.red : Colors.white),
                          border: Border.all(color: Colors.black),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Score: ${Provider.of<GameProvider>(context).snake.length - 1}',
              style: TextStyle(fontSize: 24),
            ),
          ),
        ],
      ),
    );
  }
}

enum Direction { up, down, left, right }

class GameProvider with ChangeNotifier {
  final int gridSize = 20;
  List<Point> snake = [Point(0, 0)];
  Point food = Point(0, 0);
  Direction direction = Direction.right;
  Timer? _timer;
  List<int> history = [];
  List<int> highScores = [];

  GameProvider() {
    _loadHistory();
    _loadHighScores();
    _startGame();
  }

  void _startGame() {
    snake = [Point(0, 0)];
    direction = Direction.right;
    _placeFood();
    _timer?.cancel();
    _timer = Timer.periodic(Duration(milliseconds: 200), (timer) {
      _moveSnake();
    });
  }

  void _placeFood() {
    Random random = Random();
    food = Point(random.nextInt(gridSize), random.nextInt(gridSize));
    while (snake.contains(food)) {
      food = Point(random.nextInt(gridSize), random.nextInt(gridSize));
    }
    notifyListeners();
  }

  void _moveSnake() {
    Point newHead = _getNewHead();
    if (_isGameOver(newHead)) {
      _saveScore(snake.length - 1);
      _updateHighScores(snake.length - 1);
      _timer?.cancel();
      _showGameOverDialog();
      return;
    }
    if (newHead == food) {
      snake.add(newHead);
      _placeFood();
    } else {
      snake.removeAt(0);
      snake.add(newHead);
    }
    notifyListeners();
  }

  bool _isGameOver(Point newHead) {
    if (newHead.x < 0 || newHead.y < 0 || newHead.x >= gridSize || newHead.y >= gridSize) {
      return true;
    }
    if (snake.contains(newHead)) {
      return true;
    }
    return false;
  }

  Point _getNewHead() {
    Point currentHead = snake.last;
    switch (direction) {
      case Direction.up:
        return Point(currentHead.x, currentHead.y - 1);
      case Direction.down:
        return Point(currentHead.x, currentHead.y + 1);
      case Direction.left:
        return Point(currentHead.x - 1, currentHead.y);
      case Direction.right:
        return Point(currentHead.x + 1, currentHead.y);
    }
  }

  void changeDirection(Direction newDirection) {
    if ((direction == Direction.up && newDirection != Direction.down) ||
        (direction == Direction.down && newDirection != Direction.up) ||
        (direction == Direction.left && newDirection != Direction.right) ||
        (direction == Direction.right && newDirection != Direction.left)) {
      direction = newDirection;
    }
  }

  Future<void> _saveScore(int score) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    history.add(score);
    await prefs.setStringList('history', history.map((e) => e.toString()).toList());
    notifyListeners();
  }

  Future<void> _loadHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    history = prefs.getStringList('history')?.map((e) => int.parse(e)).toList() ?? [];
    notifyListeners();
  }

  Future<void> _loadHighScores() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    highScores = prefs.getStringList('highScores')?.map((e) => int.parse(e)).toList() ?? [];
    notifyListeners();
  }

  Future<void> _updateHighScores(int score) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    highScores.add(score);
    highScores.sort((a, b) => b.compareTo(a));
    if (highScores.length > 10) {
      highScores = highScores.sublist(0, 10);
    }
    await prefs.setStringList('highScores', highScores.map((e) => e.toString()).toList());
    notifyListeners();
  }

  void _showGameOverDialog() {
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      showDialog(
        context: navigatorKey.currentContext!,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Game Over'),
            content: Text('Your score: ${snake.length - 1}'),
            actions: <Widget>[
              TextButton(
                child: Text('Restart'),
                onPressed: () {
                  Navigator.of(context).pop();
                  _startGame();
                },
              ),
            ],
          );
        },
      );
    });
  }
}
