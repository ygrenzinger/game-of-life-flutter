import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math';
import 'dart:async';

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

class _GameOfLifeWidgetState extends State<GameOfLifeWidget> {
  Timer? _generating;
  bool _running = false;
  GameOfLife _gameOfLife = GameOfLife.of(30, random: true);

  @override
  Widget build(BuildContext context) {
    var children = List<int>.generate(_gameOfLife.size, (i) => i)
        .map((row) => _buildRow(row))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sample Code'),
      ),
      body: Table(
        border: TableBorder.all(),
        defaultColumnWidth: const FixedColumnWidth(20),
        children: children,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => _swithRunning()),
        tooltip: _running ? 'start running' : 'stop running',
        child: Icon(_running ? Icons.stop : Icons.start),
      ),
    );
  }

  void _switchCellState(Position position) {
    setState(() => {_gameOfLife = _gameOfLife.switchCellState(position)});
  }

  GridCell _buildCell(int row, int column) {
    final position = Position(row, column);
    return GridCell(
        position: position,
        alive: _gameOfLife.isAlive(position),
        onCellClicked: _switchCellState);
  }

  TableRow _buildRow(int row) {
    return TableRow(
        children: List<int>.generate(_gameOfLife.size, (i) => i)
            .map((column) => _buildCell(row, column))
            .toList());
  }

  void _startRunning() {
    _running = true;
    _generating =
        Timer.periodic(const Duration(seconds: 1), (_) => _startGeneration());
  }

  void _stopRunning() {
    _running = false;
    _generating?.cancel();
  }

  void _swithRunning() {
    if (_running) {
      _stopRunning();
    } else {
      _startRunning();
    }
  }

  void _startGeneration() {
    print("next generation");
    setState(() {
      _gameOfLife = _gameOfLife.nextGeneration();
    });
  }
}

class GridCell extends StatelessWidget {
  GridCell({
    required this.position,
    required this.alive,
    required this.onCellClicked,
  }) : super(key: ObjectKey(position));

  final Position position;
  final bool alive;
  final Function(Position) onCellClicked;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: SizedBox(
        height: 20,
        child: Container(
          color: alive ? Colors.black : Colors.white,
        ),
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
