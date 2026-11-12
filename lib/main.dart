import 'package:flutter/material.dart';
import 'dart:async';

void main() => runApp(const LaberintoApp());

class LaberintoApp extends StatelessWidget {
  const LaberintoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Laberinto Escape',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        primarySwatch: Colors.deepPurple,
      ),
      home: const MainMenuScreen(),
    );
  }
}

// ==========================================
// 1. MENÚ PRINCIPAL
// ==========================================
class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.games, size: 100, color: Colors.deepPurpleAccent),
            const SizedBox(height: 20),
            const Text(
              'ESCAPE DEL LABERINTO',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 2),
            ),
            const SizedBox(height: 10),
            const Text(
              'Alumno: [Escribe tu nombre aquí]',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 50),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                backgroundColor: Colors.deepPurpleAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              icon: const Icon(Icons.play_arrow, size: 30),
              label: const Text('INICIAR JUEGO', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              onPressed: () {
                // Inicia en el nivel 0 (Fácil)
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MazeGameScreen(initialLevel: 0)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 2. PANTALLA DEL JUEGO (Lógica y 3 Niveles)
// ==========================================
class MazeGameScreen extends StatefulWidget {
  final int initialLevel;
  const MazeGameScreen({super.key, required this.initialLevel});

  @override
  State<MazeGameScreen> createState() => _MazeGameScreenState();
}

class _MazeGameScreenState extends State<MazeGameScreen> {
  
  // --- DEFINICIÓN DE LOS 3 NIVELES (Matrices 10x10) ---
  // 1 = Pared, 0 = Camino
  
  // NIVEL 0: Fácil (Caminos anchos)
  final List<List<int>> _levelEasy = [
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    [1, 0, 0, 0, 0, 0, 1, 0, 0, 1],
    [1, 1, 1, 0, 1, 0, 1, 1, 0, 1],
    [1, 0, 0, 0, 1, 0, 0, 0, 0, 1],
    [1, 0, 1, 1, 1, 1, 1, 1, 0, 1],
    [1, 0, 0, 0, 0, 0, 0, 1, 0, 1],
    [1, 1, 1, 1, 1, 0, 1, 1, 0, 1],
    [1, 0, 0, 0, 1, 0, 0, 0, 0, 1],
    [1, 0, 1, 0, 0, 0, 1, 1, 0, 1],
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
  ];

  // NIVEL 1: Medio (Más paredes)
  final List<List<int>> _levelMedium = [
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    [1, 0, 0, 1, 0, 0, 0, 1, 0, 1],
    [1, 0, 1, 1, 0, 1, 0, 1, 0, 1],
    [1, 0, 0, 0, 0, 1, 0, 0, 0, 1],
    [1, 1, 1, 1, 0, 1, 1, 1, 1, 1],
    [1, 0, 0, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 1, 1, 1, 1, 1, 1, 0, 1],
    [1, 0, 1, 0, 0, 0, 0, 1, 0, 1],
    [1, 0, 0, 0, 1, 1, 0, 0, 0, 1],
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
  ];

  // NIVEL 2: Difícil (Tipo espiral)
  final List<List<int>> _levelHard = [
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    [1, 0, 0, 0, 1, 0, 0, 0, 1, 1],
    [1, 1, 1, 0, 1, 0, 1, 0, 1, 1],
    [1, 0, 0, 0, 1, 0, 1, 0, 0, 1],
    [1, 0, 1, 1, 1, 0, 1, 1, 0, 1],
    [1, 0, 0, 0, 0, 0, 0, 1, 0, 1],
    [1, 1, 1, 1, 1, 1, 0, 1, 1, 1],
    [1, 0, 0, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 1, 1, 1, 1, 1, 1, 0, 1],
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
  ];

  late List<List<int>> _currentMaze;
  late int _currentLevel;
  
  int _playerRow = 1;
  int _playerCol = 1;
  
  // La meta cambia dependiendo del nivel
  int _goalRow = 8;
  int _goalCol = 8;

  int _moves = 0;
  int _seconds = 0;
  Timer? _timer;
  bool _gameWon = false;

  @override
  void initState() {
    super.initState();
    _currentLevel = widget.initialLevel;
    _loadLevel(_currentLevel);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // --- LÓGICA PARA CARGAR NIVELES ---
  void _loadLevel(int level) {
    setState(() {
      _currentLevel = level;
      _playerRow = 1;
      _playerCol = 1;
      _moves = 0;
      _seconds = 0;
      _gameWon = false;

      // Asignamos el laberinto y la meta dependiendo del nivel
      if (level == 0) {
        _currentMaze = _levelEasy;
        _goalRow = 8; _goalCol = 8;
      } else if (level == 1) {
        _currentMaze = _levelMedium;
        _goalRow = 8; _goalCol = 8; // Puedes cambiar la meta si quieres
      } else {
        _currentMaze = _levelHard;
        _goalRow = 7; _goalCol = 8;
      }
    });
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel(); // Cancelamos el anterior si es que había uno
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_gameWon) {
        setState(() {
          _seconds++;
        });
      }
    });
  }

  // --- LÓGICA DE MOVIMIENTO ---
  void _movePlayer(int deltaRow, int deltaCol) {
    if (_gameWon) return;

    int newRow = _playerRow + deltaRow;
    int newCol = _playerCol + deltaCol;

    if (newRow >= 0 && newRow < 10 && newCol >= 0 && newCol < 10) {
      if (_currentMaze[newRow][newCol] == 0) {
        setState(() {
          _playerRow = newRow;
          _playerCol = newCol;
          _moves++;
        });
        _checkWin();
      }
    }
  }

  void _checkWin() {
    if (_playerRow == _goalRow && _playerCol == _goalCol) {
      _timer?.cancel();
      setState(() {
        _gameWon = true;
      });
      _showWinDialog();
    }
  }

  // --- DIÁLOGO DE VICTORIA CON LÓGICA DE NIVELES ---
  void _showWinDialog() {
    String titleText = '¡Nivel Completado!';
    String buttonText = 'Siguiente Nivel';
    
    // Si es el último nivel, cambiamos los textos
    if (_currentLevel == 2) {
      titleText = '¡Felicidades!';
      buttonText = 'Jugar desde el inicio';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(titleText),
          content: Text('Has salido del laberinto.\n\nMovimientos: $_moves\nTiempo: $_seconds segundos'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Cierra el diálogo
                
                // Lógica para avanzar de nivel o reiniciar
                if (_currentLevel < 2) {
                  _loadLevel(_currentLevel + 1);
                } else {
                  _loadLevel(0); // Vuelve al nivel fácil
                }
              },
              child: Text(buttonText),
            ),
            if (_currentLevel < 2) // Solo mostramos "Menú" si no es el final
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('Menú principal'),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Mostramos el nombre del nivel actual en la AppBar
    String levelName = 'Fácil';
    if (_currentLevel == 1) levelName = 'Medio';
    if (_currentLevel == 2) levelName = 'Difícil';

    return Scaffold(
      appBar: AppBar(
        title: Text('Nivel: $levelName'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text('Movimientos: $_moves', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Tiempo: $_seconds s', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber)),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  margin: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.deepPurpleAccent, width: 4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 10,
                    ),
                    itemCount: 100,
                    itemBuilder: (context, index) {
                      int row = index ~/ 10;
                      int col = index % 10;

                      Color cellColor = Colors.transparent;
                      Widget? content;

                      // Dibujamos usando _currentMaze
                      if (_currentMaze[row][col] == 1) {
                        cellColor = Colors.blueGrey.shade800;
                      } else if (row == _goalRow && col == _goalCol) {
                        cellColor = Colors.green.withOpacity(0.3);
                        content = const Icon(Icons.flag, color: Colors.greenAccent, size: 25);
                      } else if (row == _playerRow && col == _playerCol) {
                        content = const Icon(Icons.face, color: Colors.amber, size: 30);
                      }

                      return Container(
                        decoration: BoxDecoration(
                          color: cellColor,
                          border: Border.all(color: Colors.black12, width: 0.5),
                        ),
                        child: content != null ? Center(child: content) : null,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_up, size: 50),
                  onPressed: () => _movePlayer(-1, 0),
                  style: IconButton.styleFrom(backgroundColor: Colors.grey[800]),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_left, size: 50),
                      onPressed: () => _movePlayer(0, -1),
                      style: IconButton.styleFrom(backgroundColor: Colors.grey[800]),
                    ),
                    const SizedBox(width: 40),
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_right, size: 50),
                      onPressed: () => _movePlayer(0, 1),
                      style: IconButton.styleFrom(backgroundColor: Colors.grey[800]),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_down, size: 50),
                  onPressed: () => _movePlayer(1, 0),
                  style: IconButton.styleFrom(backgroundColor: Colors.grey[800]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}