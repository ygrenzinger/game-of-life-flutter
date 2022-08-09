import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';

import 'package:flutter/scheduler.dart';

enum CellState { ALIVE, DEAD }

extension CellStateExtension on CellState {
  CellState nextState(int numberOfAliveNeighbours) {
    if (numberOfAliveNeighbours == 3) {
      return CellState.ALIVE;
    }
    if (this == CellState.ALIVE && numberOfAliveNeighbours == 2) {
      return CellState.ALIVE;
    }
    return CellState.DEAD;
  }
}

class Position {
  final int row;
  final int column;

  Position(this.row, this.column);

  @override
  String toString() {
    return '$row-$column';
  }

  @override
  bool operator ==(other) =>
      other is Position && row == other.row && column == other.column;

  @override
  int get hashCode => Object.hash(row, column);

  operator +(Position p) => Position(row + p.row, column + p.column);
}

class GameOfLife {
  static final List<Position> neighbourShifts = [
    Position(-1, -1),
    Position(-1, 0),
    Position(-1, 1),
    Position(0, -1),
    Position(0, 1),
    Position(1, -1),
    Position(1, 0),
    Position(1, 1),
  ];

  final int size;
  final Set<Position> _aliveCells;

  GameOfLife(this.size, this._aliveCells);

  static GameOfLife of(int size, {bool random = false}) {
    Set<Position> aliveCells = {};
    if (random) {
      for (int row = 0; row < size; row++) {
        for (int column = 0; column < size; column++) {
          var number = Random().nextInt(2);
          if (number % 2 == 0) {
            aliveCells.add(Position(row, column));
          }
        }
      }
    }

    return GameOfLife(size, aliveCells);
  }

  bool isAlive(Position position) => _aliveCells.contains(position);

  CellState cellStateAt(Position position) {
    if (isAlive(position)) {
      return CellState.ALIVE;
    } else {
      return CellState.DEAD;
    }
  }

  GameOfLife switchCellState(Position position) {
    var updatedCells = Set<Position>.from(_aliveCells);
    if (isAlive(position)) {
      updatedCells.remove(position);
    } else {
      updatedCells.add(position);
    }
    return GameOfLife(size, updatedCells);
  }

  bool isInGrid(Position position) =>
      position.row >= 0 &&
      position.row < size &&
      position.column >= 0 &&
      position.column < size;

  GameOfLife nextGeneration() {
    Set<Position> nextCells = {};
    final posToEvaluate = _aliveCellsWithNeighbour();
    for (var position in posToEvaluate) {
      final cellState = cellStateAt(position);
      final numberOfAliveNeighbours = _computeAliveNeighbours(position);
      if (cellState.nextState(numberOfAliveNeighbours) == CellState.ALIVE) {
        nextCells.add(position);
      }
    }
    return GameOfLife(size, nextCells);
  }

  Set<Position> _aliveCellsWithNeighbour() {
    return _aliveCells.expand((position) => _blockAt(position)).toSet();
  }

  List<Position> _blockAt(Position position) {
    var block = _neighboursOf(position);
    block.add(position);
    return block;
  }

  int _computeAliveNeighbours(Position position) =>
      _neighboursOf(position).fold(0, (int previousValue, Position position) {
        if (isAlive(position)) {
          return previousValue + 1;
        } else {
          return previousValue;
        }
      });

  List<Position> _neighboursOf(Position position) => GameOfLife.neighbourShifts
      .map((Position p) => position + p as Position)
      .where(isInGrid)
      .toList();
}

class GameOfLifeWidget extends StatefulWidget {
  const GameOfLifeWidget({Key? key}) : super(key: key);

  @override
  State<GameOfLifeWidget> createState() => _GameOfLifeWidgetState();
}

class _GameOfLifeWidgetState extends State<GameOfLifeWidget>
    with SingleTickerProviderStateMixin {
  bool _running = false;
  late Ticker _ticker;
  late Duration _lastTime;
  final StreamController<GameOfLife> _controller = StreamController.broadcast();
  late GameOfLife _gameOfLife;

  @override
  void initState() {
    super.initState();
    _running = false;
    _gameOfLife = GameOfLife.of(30, random: true);
    _controller.stream.listen((event) {
      _gameOfLife = event;
    });
    _ticker = createTicker(update);
    _lastTime = Duration.zero;
  }

  void update(Duration elapsed) {
    if (elapsed.inSeconds - _lastTime.inSeconds >= 1) {
      _lastTime = elapsed;
      _startGeneration();
    }
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sample Code'),
      ),
      body: Grid(
        defaultGameOfLife: _gameOfLife,
        riverOfLife: _controller.stream,
        switchCell: _switchCellState,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => _swithRunning()),
        tooltip: _running ? 'start running' : 'stop running',
        child: Icon(_running ? Icons.stop : Icons.start),
      ),
    );
  }

  void _switchCellState(Position position) async {
    _controller.add(_gameOfLife.switchCellState(position));
  }

  void _startRunning() {
    _running = true;
    _ticker.start();
  }

  void _stopRunning() {
    _running = false;
    _ticker.stop();
    _lastTime = Duration.zero;
  }

  // ** Your using a state
  void _swithRunning() {
    if (_running) {
      _stopRunning();
    } else {
      _startRunning();
    }
  }

  void _startGeneration() async {
    print("next generation");
    _controller.add(_gameOfLife.nextGeneration());
  }
}

class Grid extends StatelessWidget {
  final GameOfLife defaultGameOfLife;
  final Stream<GameOfLife> riverOfLife;
  final Function(Position) switchCell;

  const Grid(
      {Key? key,
      required this.riverOfLife,
      required this.switchCell,
      required this.defaultGameOfLife})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Table(
        border: TableBorder.all(),
        defaultColumnWidth: const FixedColumnWidth(20),
        children: [
          ...List<int>.generate(defaultGameOfLife.size, (i) => i)
              .map((row) => TableRow(children: [
                    ...List<int>.generate(defaultGameOfLife.size, (i) => i)
                        .map((column) {
                      final position = Position(row, column);
                      return GridCell(
                          riverOfLife: riverOfLife,
                          position: position,
                          alive: defaultGameOfLife.isAlive(position),
                          onCellClicked: switchCell);
                    }).toList()
                  ]))
              .toList()
        ]);
  }
}

class GridCell extends StatelessWidget {
  const GridCell({
    Key? key,
    required this.riverOfLife,
    required this.position,
    required this.alive,
    required this.onCellClicked,
  }) : super(key: key);

  final Stream<GameOfLife> riverOfLife;
  final Position position;
  final bool alive;
  final Function(Position) onCellClicked;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: SizedBox(
        height: 20,
        child: StreamBuilder<GameOfLife>(
            stream: riverOfLife,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.active) {
                return Container(
                  color: alive ? Colors.black : Colors.white,
                );
              }
              return Container(
                color: snapshot.data?.isAlive(position) == true
                    ? Colors.black
                    : Colors.white,
              );
            }),
      ),
      onTap: () => onCellClicked(position),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Game of Life',
      home: GameOfLifeWidget(),
    );
  }
}

void main() => runApp(const MyApp());
